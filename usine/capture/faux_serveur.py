"""Faux serveur OpenAI-compatible qui rejoue un échange scripté (preuve du proxy, tests).

Le scénario est une liste de réponses, servies dans l'ordre aux POST …/chat/completions :
    {"flux": true,  "morceaux": ["data: {...}\\n\\n", ...], "pause_s": 0.01}   → SSE, sans Content-Length
    {"flux": false, "corps": {...}}                                         → JSON avec Content-Length
GET /v1/models répond une liste fixe. Les requêtes reçues sont gardées (`self.recues`)
pour vérifier que le proxy les a transmises à l'identique.
"""

from __future__ import annotations

import json
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


def morceaux_sse(objets: list[dict[str, Any]]) -> list[str]:
    return [f"data: {json.dumps(o, ensure_ascii=False)}\n\n" for o in objets] + ["data: [DONE]\n\n"]


class _Gestionnaire(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server: "FauxServeur"

    def log_message(self, format: str, *args) -> None:  # noqa: A002
        pass

    def do_GET(self) -> None:
        corps = json.dumps({"object": "list", "data": [{"id": "qwen3.8-27b", "object": "model"}]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(corps)))
        self.end_headers()
        self.wfile.write(corps)

    def do_POST(self) -> None:
        corps = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        self.server.recues.append({"chemin": self.path, "entetes": dict(self.headers.items()), "corps": corps})
        rep = self.server.scenario[min(len(self.server.recues), len(self.server.scenario)) - 1]
        self.send_response(200)
        if rep.get("flux"):
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-cache")
            self.send_header("Connection", "close")
            self.end_headers()
            for m in rep["morceaux"]:
                self.wfile.write(m.encode("utf-8"))
                self.wfile.flush()
                time.sleep(rep.get("pause_s", 0))
            self.close_connection = True
        else:
            octets = json.dumps(rep["corps"], ensure_ascii=False).encode("utf-8")
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(octets)))
            self.end_headers()
            self.wfile.write(octets)


class FauxServeur(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, scenario: list[dict[str, Any]], port: int = 0):
        self.scenario = scenario
        self.recues: list[dict[str, Any]] = []
        super().__init__(("127.0.0.1", port), _Gestionnaire)

    @property
    def url(self) -> str:
        return f"http://127.0.0.1:{self.server_address[1]}/v1"

    def demarrer_en_fond(self) -> threading.Thread:
        fil = threading.Thread(target=self.serve_forever, daemon=True)
        fil.start()
        return fil
