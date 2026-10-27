"""Sonde : un faux modèle OpenAI-compatible pour capturer ce qu'OpenCode envoie (étape A5 du suivi ; accord de laurent
du 2026-10-27, « ok pour tout »). Ni Qwen ni llama-server : on veut la forme des requêtes d'OpenCode (message système,
`AGENTS.md`, outils, appel du Code Mode, retour d'un outil MCP, image lue), pas une réponse de modèle.

Chaque POST …/chat/completions est gardé tel quel (`requete_<k>.json`). La réponse suit un scénario court, écrit d'après
les outils que la requête déclare :
  0. appeler `search_docs` du serveur MCP de l'usine : par l'outil du Code Mode s'il existe (son code dans son premier
     paramètre requis), sinon par l'outil MCP direct ;
  1. lire une image du projet avec l'outil de lecture d'OpenCode ;
  2. conclure en texte.
Une requête sans outils (titre de la session, résumé) reçoit un texte court.

    python -m usine.capture sonde --port 8097 --sortie donnees/capture_opencode/requetes [--code '<code>']
"""

from __future__ import annotations

import json
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

MODELE = "qwen-sonde"
REQUETE_DOC = "CharacterBody3D move_and_slide"
CODE_PAR_DEFAUT = 'tools["usine-godot"].search_docs({"requete": "' + REQUETE_DOC + '"})'
AMORCE = "Prêt ?"  # message d'une session d'amorce, qui laisse les serveurs MCP se connecter : réponse en texte


def _outil(corps: dict[str, Any], *noms: str) -> dict[str, Any] | None:
    for t in corps.get("tools") or []:
        f = t.get("function") or {}
        if f.get("name") in noms:
            return f
    return None


def _outil_contenant(corps: dict[str, Any], morceau: str) -> dict[str, Any] | None:
    return next(((t.get("function") or {}) for t in corps.get("tools") or []
                 if morceau in (t.get("function") or {}).get("name", "")), None)


def _premier_parametre(f: dict[str, Any]) -> str:
    p = f.get("parameters") or {}
    requis = p.get("required") or list((p.get("properties") or {}).keys())
    return requis[0] if requis else "code"


def etape(corps: dict[str, Any]) -> int:
    """Le nombre de tours de l'assistant qui ont déjà appelé un outil."""
    return sum(1 for m in corps.get("messages") or [] if m.get("role") == "assistant" and m.get("tool_calls"))


def decision(corps: dict[str, Any], image: str, code: str = CODE_PAR_DEFAUT) -> tuple[str | None, dict[str, Any], str]:
    """(outil à appeler ou None, ses arguments, texte) pour cette requête."""
    if not corps.get("tools"):
        return None, {}, "Capture d'OpenCode"
    derniers = [m for m in corps.get("messages") or [] if m.get("role") == "user"]
    if derniers and AMORCE in json.dumps(derniers[-1].get("content"), ensure_ascii=False):
        return None, {}, "Prêt."
    k = etape(corps)
    if k == 0:
        execute = _outil(corps, "execute")
        if execute:
            return "execute", {_premier_parametre(execute): code}, "Je cherche dans la documentation :"
        direct = _outil_contenant(corps, "search_docs")
        if direct:
            return direct["name"], {"requete": REQUETE_DOC}, "Je cherche dans la documentation :"
    if k <= 1:
        lire = _outil(corps, "read", "view", "read_file")
        if lire:
            return lire["name"], {_premier_parametre(lire): image}, "Je regarde l'image :"
    return None, {}, "Capture terminée."


def _morceaux(outil: str | None, arguments: dict[str, Any], texte: str) -> list[dict[str, Any]]:
    base = {"id": f"sonde-{int(time.time() * 1000)}", "object": "chat.completion.chunk", "created": int(time.time()),
            "model": MODELE}
    sortie = [dict(base, choices=[{"index": 0, "delta": {"role": "assistant", "content": texte}}])]
    if outil:
        appel = {"index": 0, "id": f"appel_{int(time.time() * 1000)}", "type": "function",
                 "function": {"name": outil, "arguments": json.dumps(arguments, ensure_ascii=False)}}
        sortie.append(dict(base, choices=[{"index": 0, "delta": {"tool_calls": [appel]}}]))
    sortie.append(dict(base, choices=[{"index": 0, "delta": {}, "finish_reason": "tool_calls" if outil else "stop"}],
                       usage={"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}))
    return sortie


def _complet(outil: str | None, arguments: dict[str, Any], texte: str) -> dict[str, Any]:
    message: dict[str, Any] = {"role": "assistant", "content": texte}
    if outil:
        message["tool_calls"] = [{"id": f"appel_{int(time.time() * 1000)}", "type": "function",
                                  "function": {"name": outil, "arguments": json.dumps(arguments, ensure_ascii=False)}}]
    return {"id": "sonde", "object": "chat.completion", "created": int(time.time()), "model": MODELE,
            "choices": [{"index": 0, "message": message, "finish_reason": "tool_calls" if outil else "stop"}],
            "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0}}


class _Gestionnaire(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server: "Sonde"

    def log_message(self, format: str, *args) -> None:  # noqa: A002
        pass

    def _json(self, objet: Any) -> None:
        octets = json.dumps(objet, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(octets)))
        self.end_headers()
        self.wfile.write(octets)

    def do_GET(self) -> None:
        self._json({"object": "list", "data": [{"id": MODELE, "object": "model"}]})

    def do_POST(self) -> None:
        brut = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        try:
            corps = json.loads(brut)
        except json.JSONDecodeError:
            corps = {}
        k = self.server.garder(self.path, dict(self.headers.items()), brut)
        outil, arguments, texte = decision(corps, self.server.image, self.server.code)
        self.server.journal.append({"requete": k, "etape": etape(corps), "outil": outil, "arguments": arguments})
        if corps.get("stream"):
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "close")
            self.end_headers()
            for m in _morceaux(outil, arguments, texte):
                self.wfile.write(f"data: {json.dumps(m, ensure_ascii=False)}\n\n".encode("utf-8"))
                self.wfile.flush()
            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
            self.close_connection = True
        else:
            self._json(_complet(outil, arguments, texte))


class Sonde(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, port: int, sortie: Path, image: str, code: str = CODE_PAR_DEFAUT):
        super().__init__(("127.0.0.1", port), _Gestionnaire)
        self.sortie, self.image, self.code = Path(sortie), image, code
        self.sortie.mkdir(parents=True, exist_ok=True)
        self.journal: list[dict[str, Any]] = []
        self._verrou = threading.Lock()
        self._n = 0

    def garder(self, chemin: str, entetes: dict[str, str], brut: bytes) -> int:
        with self._verrou:
            self._n += 1
            k = self._n
        try:
            corps: Any = json.loads(brut)
        except json.JSONDecodeError:
            corps = brut.decode("utf-8", errors="replace")
        entetes = {c: v for c, v in entetes.items() if c.lower() != "authorization"}
        (self.sortie / f"requete_{k:02d}.json").write_text(
            json.dumps({"chemin": chemin, "entetes": entetes, "corps": corps}, indent=1, ensure_ascii=False),
            encoding="utf-8")
        return k

    def demarrer(self) -> threading.Thread:
        fil = threading.Thread(target=self.serve_forever, daemon=True)
        fil.start()
        return fil
