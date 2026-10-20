"""Dashboard HTML de la vérification locale (étapes 12 à 16 de la session 4).

Lance les étapes dans l'ordre, en temps réel, et affiche une page HTML auto-actualisante :
  - liste des étapes : EN ATTENTE / EN COURS (avec la ligne la plus récente) / TERMINEE (code de sortie) ;
  - sortie de chaque étape en direct (journal complet, scroll auto) ;
  - bouton STOP.

Le processus est un seul python : on peut le tuer d'un coup (le bouton appelle /stop,
le kill du process reste la solution de secours).

USAGE : python outils\\dashboard_verif.py [--port 8787] [--etape 13a,14]
        puis ouvrir http://127.0.0.1:8787/
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
JOURNAL = RACINE / "donnees" / "verif_dashboard.jsonl"

# (id, libellé, commande) — l'ordre de la liste est l'ordre d'exécution.
ETAPES = [
    ("12", "Préparation (clones + wheelhouse + config) — déjà fait", None),
    ("13a", "RAG : construire l'index de la doc Godot (--sans-demos)",
     [sys.executable, "-m", "usine.rag", "construire", "--sans-demos"]),
    ("13b", "RAG : chercher CharacterBody2D -n 3 (attendu : [exact] en 1re ligne)",
     [sys.executable, "-m", "usine.rag", "chercher", "CharacterBody2D", "-n", "3"]),
    ("13c", "RAG : vérifier l'exclusion des gelés (attendu : 0 fuite)",
     [sys.executable, "-m", "usine.rag", "verifier"]),
    ("14a", "Capture : preuve du proxy de capture (attendu : CONFORME)",
     [sys.executable, "-m", "usine.capture", "preuve"]),
    ("14b", "MCP : preuve du serveur (attendu : 12/12 contrôles conformes)",
     [sys.executable, "-m", "mcp_serveur.preuve"]),
    ("15", "Fusion OpenCode sur une copie jetable (attendu : opencode.json écrit)",
     [sys.executable, "outils/opencode_fusion.py", "D:/GODOT/essai_usine", "--proxy"]),
]


def _ecrire_journal(ligne: dict) -> None:
    JOURNAL.parent.mkdir(parents=True, exist_ok=True)
    with open(JOURNAL, "a", encoding="utf-8") as f:
        f.write(json.dumps(ligne, ensure_ascii=False) + "\n")


def _lister_etape_sortie(etape_id: str) -> list[str]:
    if not JOURNAL.is_file():
        return []
    out = []
    with open(JOURNAL, encoding="utf-8") as f:
        for ligne in f:
            try:
                d = json.loads(ligne)
            except json.JSONDecodeError:
                continue
            if d.get("etape") == etape_id and d.get("type") in ("out", "err", "info"):
                out.append(d.get("txt", ""))
    return out


class Orchestrateur(threading.Thread):
    def __init__(self, port: int, etapes_ids: list[str] | None):
        super().__init__(daemon=True)
        self.port = port
        self.etape_courante: str | None = None
        self.arrêt = threading.Event()
        self.choix = set(etapes_ids) if etapes_ids else None

    def _statut(self, etape_id: str, statut: str, **extra) -> None:
        _ecrire_journal({"type": "statut", "etape": etape_id, "statut": statut,
                         "ts": time.strftime("%H:%M:%S"), **extra})

    def run(self) -> None:
        _ecrire_journal({"type": "info", "txt": f"=== Dashboard vérification session 4 démarré à "
                                                f"{time.strftime('%Y-%m-%d %H:%M:%S')} — port {self.port} ==="})
        for eid, _lib, cmd in ETAPES:
            if self.arrêt.is_set():
                self._statut(eid, "ABANDONNEE")
                continue
            if self.choix and eid not in self.choix:
                continue
            if cmd is None:
                self._statut(eid, "PASSE", detail="étape préparatoire déjà faite manuellement")
                continue
            self.etape_courante = eid
            self._statut(eid, "EN_COURS")
            debut = time.monotonic()
            try:
                proc = subprocess.Popen(cmd, cwd=RACINE, stdout=subprocess.PIPE,
                                        stderr=subprocess.STDOUT, text=True,
                                        encoding="utf-8", errors="replace")
            except Exception as e:
                self._statut(eid, "TERMINEE", code=-1, duree_s=0, detail=f"lancement impossible : {e}")
                continue
            assert proc.stdout is not None
            for ligne in proc.stdout:
                ligne = ligne.rstrip("\n")
                _ecrire_journal({"type": "out", "etape": eid, "ts": time.strftime("%H:%M:%S"), "txt": ligne})
                if self.arrêt.is_set():
                    proc.kill()
            code = proc.wait()
            duree = round(time.monotonic() - debut)
            self._statut(eid, "TERMINEE", code=code, duree_s=duree,
                         detail=f"code {code}, {duree} s")
            self.etape_courante = None
        _ecrire_journal({"type": "info", "txt": "=== Toutes les étapes sont terminées. ==="})
        self.etape_courante = None


HTML_PAGE = r"""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="3">
<title>Vérification session 4 — en direct</title>
<style>
 body{font-family:Consolas,monospace;background:#111;color:#ddd;margin:16px}
 h1{font-size:18px} .ligne{display:flex;gap:12px;align-items:baseline;margin:2px 0}
 .eid{width:34px;color:#888} .lib{flex:1}
 .badge{padding:1px 8px;border-radius:3px;font-size:12px}
 .EN_COURS{background:#0a5;background:#033;color:#4df}
 .TERMINEE{background:#033;color:#4f4}
 .ABANDONNEE{background:#300;color:#f44}
 .PASSE{background:#333;color:#888}
 .EN_ATTENTE{background:#222;color:#777}
 pre{background:#0a0a0a;border:1px solid #333;padding:8px;max-height:300px;overflow:auto;
     font-size:12px;white-space:pre-wrap;margin:4px 0 12px}
 .stop{position:fixed;top:16px;right:16px;background:#a00;color:#fff;border:0;
       padding:8px 16px;font-size:14px;cursor:pointer;border-radius:4px}
 .info{color:#888;font-size:12px}
</style></head><body>
<button class="stop" onclick="fetch('/stop').then(()=>alert('arrêt demandé'))">■ STOP</button>
<h1>Vérification locale — session 4 (étapes 12 à 16)</h1>
<div class="info">Actualisation automatique toutes les 3 s. Les sorties ci-dessous sont le journal réel des commandes.</div>
__CONTENU__
</body></html>
"""


def construire_page() -> str:
    statuts: dict[str, dict] = {}
    dernier: dict[str, str] = {}
    if JOURNAL.is_file():
        with open(JOURNAL, encoding="utf-8") as f:
            for ligne in f:
                try:
                    d = json.loads(ligne)
                except json.JSONDecodeError:
                    continue
                t = d.get("type")
                if t == "statut":
                    statuts[d["etape"]] = d
                elif t in ("out", "info") and d.get("etape"):
                    dernier[d["etape"]] = d.get("txt", "")
    lignes_html = []
    for eid, lib, _cmd in ETAPES:
        st = statuts.get(eid)
        if st:
            badge = st["statut"].replace("_", " ")
            extra = ""
            if st.get("code") is not None:
                extra = f' code {st["code"]} · {st.get("duree_s", "?")} s'
            detail = f' — {st["detail"]}' if st.get("detail") else ""
        else:
            badge, extra, detail = "EN ATTENTE", "", ""
        cls = {"EN_COURS": "EN_COURS", "TERMINEE": "TERMINEE", "ABANDONNEE": "ABANDONNEE",
               "PASSE": "PASSE"}.get(badge, "EN_ATTENTE")
        if badge == "EN_COURS":
            last = dernier.get(eid, "(aucune sortie pour l'instant)")
        else:
            last = ""
        lignes_html.append(
            f'<div class="ligne"><span class="eid">{eid}</span><span class="lib">{lib}{detail}</span>'
            f'<span class="badge {cls}">{badge}{extra}</span></div>')
        if last:
            lignes_html.append(f"<pre>{last.replace('<', '&lt;')}</pre>")
    return HTML_PAGE.replace("__CONTENU__", "\n".join(lignes_html))


class Handler(BaseHTTPRequestHandler):
    serveur: "ThreadingHTTPServer"

    def log_message(self, *args):  # silencieux
        pass

    def _envoyer(self, corps: bytes, content_type: str) -> None:
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(corps)))
        self.end_headers()
        self.wfile.write(corps)

    def do_GET(self) -> None:
        if self.path in ("/", "/index.html"):
            self._envoyer(construire_page().encode("utf-8"), "text/html; charset=utf-8")
        elif self.path == "/journal.jsonl":
            corps = JOURNAL.read_bytes() if JOURNAL.is_file() else b""
            self._envoyer(corps, "application/jsonlines; charset=utf-8")
        else:
            self.send_error(404)

    def do_POST(self) -> None:
        if self.path == "/stop":
            self.serveur.orchestrateur.arrêt.set()
            self._envoyer("arrêt demandé\n".encode("utf-8"), "text/plain; charset=utf-8")
        else:
            self.send_error(404)


def main() -> int:
    import argparse as ap
    p = ap.ArgumentParser()
    p.add_argument("--port", type=int, default=8787)
    p.add_argument("--etape", type=str, default=None, help="ex. 13a,14a pour n'en lancer que celles-là")
    args = p.parse_args()
    JOURNAL.unlink(missing_ok=True)
    choix = [e.strip() for e in args.etape.split(",")] if args.etape else None
    serveur = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    serveur.orchestrateur = Orchestrateur(args.port, choix)
    serveur.orchestrateur.start()
    print(f"Dashboard : http://127.0.0.1:{args.port}/  (Ctrl+C pour tout arrêter)", flush=True)
    try:
        serveur.serve_forever()
    except KeyboardInterrupt:
        print("\nArrêt demandé (Ctrl+C) : arrêt des étapes…", flush=True)
        serveur.orchestrateur.arrêt.set()
        serveur.orchestrateur.join(timeout=10)
    return 0


if __name__ == "__main__":
    sys.exit(main())
