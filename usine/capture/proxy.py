"""Proxy HTTP OpenAI-compatible entre OpenCode et llama-server, qui enregistre sans altérer.

    OpenCode → http://127.0.0.1:8090 (proxy) → http://127.0.0.1:8080 (llama-server)

Toute requête est relayée telle quelle (méthode, chemin, en-têtes hors saut à saut, corps) ;
la réponse revient octet pour octet, flux SSE compris : chaque morceau lu chez llama-server
est réécrit aussitôt vers OpenCode. L'enregistrement (POST …/chat/completions) a lieu après la
fin de la réponse, sur une copie ; une erreur d'enregistrement n'interrompt jamais le relais.

Bibliothèque standard seule. Le proxy ne coupe rien : pas de délai côté OpenCode, un délai
de lecture très long côté llama-server (génération longue).
"""

from __future__ import annotations

import http.client
import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

from usine.capture.enregistreur import Enregistreur

SAUT_A_SAUT = {"connection", "keep-alive", "proxy-authenticate", "proxy-authorization", "te", "trailer",
               "trailers", "transfer-encoding", "upgrade", "host", "expect"}
DELAI_AMONT_S = 3600
TAILLE_LECTURE = 65536


def amont_depuis_url(url: str) -> tuple[str, int]:
    """'http://127.0.0.1:8080/v1' → ('127.0.0.1', 8080) ; le chemin de la requête est gardé tel quel."""
    parties = urlsplit(url if "://" in url else "http://" + url)
    if parties.scheme != "http":
        raise ValueError(f"amont http:// attendu (serveur local) : {url}")
    return parties.hostname or "127.0.0.1", parties.port or 80


class Gestionnaire(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server: "ProxyCapture"

    def log_message(self, format: str, *args) -> None:  # noqa: A002
        if self.server.bavard:
            sys.stderr.write("proxy : " + format % args + "\n")

    def _lire_corps(self) -> bytes:
        if "chunked" in self.headers.get("Transfer-Encoding", "").lower():
            morceaux = []
            while True:
                taille = int(self.rfile.readline().split(b";")[0].strip(), 16)
                if taille == 0:
                    while self.rfile.readline() not in (b"\r\n", b"\n", b""):
                        pass
                    break
                morceaux.append(self.rfile.read(taille))
                self.rfile.readline()
            return b"".join(morceaux)
        longueur = int(self.headers.get("Content-Length") or 0)
        return self.rfile.read(longueur) if longueur else b""

    def _relayer(self) -> None:
        corps = self._lire_corps()
        entetes = {k: v for k, v in self.headers.items() if k.lower() not in SAUT_A_SAUT}
        if corps or self.command in ("POST", "PUT", "PATCH"):
            entetes["Content-Length"] = str(len(corps))
        hote, port = self.server.amont
        amont = http.client.HTTPConnection(hote, port, timeout=DELAI_AMONT_S)
        try:
            amont.request(self.command, self.path, body=corps or None, headers=entetes)
            rep = amont.getresponse()
        except OSError as exc:
            amont.close()
            message = json.dumps({"error": {"message": f"proxy de capture : llama-server injoignable "
                                                       f"({hote}:{port}) : {exc}", "type": "proxy"}}).encode()
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(message)))
            self.end_headers()
            self.wfile.write(message)
            return
        recu = bytearray()
        try:
            self.send_response_only(rep.status, rep.reason)
            longueur = rep.getheader("Content-Length")
            for k, v in rep.getheaders():
                if k.lower() not in SAUT_A_SAUT:
                    self.send_header(k, v)
            par_morceaux = longueur is None and self.command != "HEAD" and rep.status not in (204, 304)
            if par_morceaux:
                self.send_header("Transfer-Encoding", "chunked")
            self.end_headers()
            self.wfile.flush()
            while True:
                morceau = rep.read1(TAILLE_LECTURE) if self.command != "HEAD" else b""
                if not morceau:
                    break
                recu += morceau
                if par_morceaux:
                    self.wfile.write(f"{len(morceau):x}\r\n".encode("ascii") + morceau + b"\r\n")
                else:
                    self.wfile.write(morceau)
                self.wfile.flush()
            if par_morceaux:
                self.wfile.write(b"0\r\n\r\n")
                self.wfile.flush()
        finally:
            amont.close()
        if self.command == "POST" and self.path.split("?")[0].rstrip("/").endswith("/chat/completions"):
            try:
                self.server.enregistreur.enregistrer(self.path, corps, rep.status,
                                                     {k.lower(): v for k, v in rep.getheaders()}, bytes(recu))
            except Exception as exc:  # l'enregistrement ne doit jamais gêner OpenCode
                sys.stderr.write(f"proxy : enregistrement impossible : {exc!r}\n")

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = do_OPTIONS = do_HEAD = _relayer


class ProxyCapture(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, port: int, amont: str, dossier: Path, hote: str = "127.0.0.1", bavard: bool = False):
        self.amont = amont_depuis_url(amont)
        self.enregistreur = Enregistreur(dossier)
        self.bavard = bavard
        super().__init__((hote, port), Gestionnaire)

    @property
    def port(self) -> int:
        return self.server_address[1]

    def demarrer_en_fond(self) -> threading.Thread:
        fil = threading.Thread(target=self.serve_forever, daemon=True)
        fil.start()
        return fil
