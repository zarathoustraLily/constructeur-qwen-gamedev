"""Dashboard HTML de la chaîne du portillon (session 3, étape 11).

Lance `python chain_verbose.py` en fond, lit son fichier d'événements JSONL
(donnees/chain_events.jsonl) et :
  - affiche chaque TEST individuellement (départ → résultat : ACCEPTÉE / REJETÉE) ;
  - affiche les lignes de progression (production, compteur d'évaluations, gel…) ;
  - met à jour un tableau récapitulatif en direct ;
  - bouton STOP (tue le processus enfant).

USAGE : python outils\\dashboard_chaine.py [--port 8788] [--relancer]
  --relancer : efface les logs avant de démarrer.
  puis ouvrir http://127.0.0.1:8788/
"""
from __future__ import annotations

import argparse
import datetime
import json
import re
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
EVENTS = RACINE / "donnees" / "chain_events.jsonl"
CHAIN_LOG = RACINE / "donnees" / "chain_verbose_log.txt"

CMD = [sys.executable, "-X", "utf8", "chain_verbose.py"]

# Regex pour les lignes du log texte (production, éval, etc.)
_RE_PRODUCTION = re.compile(r"^masquage\s+(\S+)\s+(\d+)\s+tâches\s+(\d+)\s+écartés\s+\((\d+)\s+s\)")
_RE_EVALUATION = re.compile(r"^\s+(\d+)/(\d+)\s+évaluées\s+\((\d+)\s+s\)")
_RE_DEMARRAGE = re.compile(r"^== CHAINE DÉMARRAGE \((\d+:\d+:\d+)\), graine=(\d+), f1=(\d+)")
_RE_FIN = re.compile(r"^== CHAINE FINI \((\d+:\d+:\d+)\), durée (\d+) s")


class Orchestrateur(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True)
        self.arrêt = threading.Event()
        self.proc: subprocess.Popen | None = None
        self._pos_events: int = 0
        self._pos_log: int = 0

    def _lire_events(self) -> None:
        """Lit les nouveaux événements du fichier JSONL."""
        if not EVENTS.is_file():
            return
        try:
            with open(EVENTS, "r", encoding="utf-8") as f:
                f.seek(self._pos_events)
                for ligne in f:
                    ligne = ligne.strip()
                    if not ligne:
                        continue
                    try:
                        d = json.loads(ligne)
                    except json.JSONDecodeError:
                        continue
                    t = d.get("type")
                    if t == "test_debut":
                        d["idx"] = len(self._tests) + len(self._test_en_cours)
                        self._test_en_cours[d["nom"]] = d
                    elif t == "test_fin":
                        self._tests.append(d)
                    # On garde tous les événements pour la page
                    self._evenements.append(d)
                self._pos_events = f.tell()
        except OSError:
            pass

    def _lire_log(self) -> None:
        """Lit les nouvelles lignes du log texte (production, éval, etc.)."""
        if not CHAIN_LOG.is_file():
            return
        try:
            with open(CHAIN_LOG, "r", encoding="utf-8") as f:
                f.seek(self._pos_log)
                for ligne in f:
                    txt = ligne.rstrip()
                    if not txt:
                        continue
                    m = _RE_PRODUCTION.match(txt)
                    if m:
                        self._evenements.append({
                            "type": "prod", "ts": time.strftime("%H:%M:%S"),
                            "competence": m.group(1), "taches": int(m.group(2)),
                            "ecartes": int(m.group(3)), "duree_s": int(m.group(4))})
                        continue
                    m = _RE_EVALUATION.match(txt)
                    if m:
                        self._evenements.append({
                            "type": "eval", "ts": time.strftime("%H:%M:%S"),
                            "faites": int(m.group(1)), "total": int(m.group(2)),
                            "seconde": int(m.group(3))})
                        continue
                    m = _RE_DEMARRAGE.match(txt)
                    if m:
                        self._evenements.append({
                            "type": "info", "ts": time.strftime("%H:%M:%S"),
                            "txt": f"Chaîne démarrée : graine={m.group(2)}, f1={m.group(3)}"})
                        continue
                    m = _RE_FIN.match(txt)
                    if m:
                        self._evenements.append({
                            "type": "info", "ts": time.strftime("%H:%M:%S"),
                            "txt": f"Chaîne terminée : durée {m.group(2)} s"})
                        continue
                    self._evenements.append({"type": "raw", "ts": time.strftime("%H:%M:%S"), "txt": txt})
                self._pos_log = f.tell()
        except OSError:
            pass

    def run(self) -> None:
        self._tests: list[dict] = []
        self._test_en_cours: dict[str, dict] = {}
        self._evenements: list[dict] = []

        self._evenements.append({"type": "info", "ts": time.strftime("%H:%M:%S"),
                                 "txt": f"=== Dashboard chaîne démarré à {time.strftime('%Y-%m-%d %H:%M:%S')} ==="})

        if not CHAIN_LOG.is_file() or CHAIN_LOG.stat().st_size == 0:
            try:
                self.proc = subprocess.Popen(CMD, cwd=RACINE, stdout=subprocess.DEVNULL,
                                             stderr=subprocess.DEVNULL)
            except Exception as e:
                self._evenements.append({"type": "info", "ts": time.strftime("%H:%M:%S"),
                                         "txt": f"lancement impossible : {e}"})
                return
        else:
            self._evenements.append({"type": "info", "ts": time.strftime("%H:%M:%S"),
                                     "txt": "Mode observation : chaîne déjà démarrée ailleurs"})

        while True:
            self._lire_events()
            self._lire_log()
            if self.arrêt.is_set():
                if self.proc:
                    self.proc.kill()
                break
            if self.proc is not None and self.proc.poll() is not None:
                self._lire_events()
                self._lire_log()
                code = self.proc.returncode
                self._evenements.append({"type": "info", "ts": time.strftime("%H:%M:%S"),
                                         "txt": f"=== Fin, code sortie {code} ==="})
                break
            time.sleep(1)
        self.proc = None

    def get_tests(self) -> list[dict]:
        return self._tests

    def get_en_cours(self) -> list[dict]:
        return list(self._test_en_cours.values())

    def get_evenements(self) -> list[dict]:
        return self._evenements


def _chrono_statique(ts: str) -> str:
    parts = ts.split(":")
    try:
        t_ref = datetime.datetime.now().replace(
            hour=int(parts[0]), minute=int(parts[1]), second=int(parts[2]), microsecond=0)
        diff = max(0, int((datetime.datetime.now() - t_ref).total_seconds()))
        h, m, s = diff // 3600, (diff % 3600) // 60, diff % 60
        return (f"{h}h " if h else "") + f"{m:02d}m{s:02d}s"
    except (ValueError, IndexError):
        return "?"


HTML_PAGE = r"""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8">
<meta http-equiv="refresh" content="2">
<title>Chaîne du portillon — en direct</title>
<style>
 body{font-family:Consolas,monospace;background:#111;color:#ddd;margin:16px}
 h1{font-size:18px} .info{color:#888;font-size:12px;margin-bottom:12px}
 .stop{position:fixed;top:16px;right:16px;background:#a00;color:#fff;border:0;
        padding:8px 16px;font-size:14px;cursor:pointer;border-radius:4px}
 .stop:hover{background:#c22}
 .progre{display:flex;gap:12px;align-items:baseline;margin:8px 0;flex-wrap:wrap}
 .progre .bloc{background:#1a1a1a;border:1px solid #333;padding:6px 14px;border-radius:4px}
 .progre .bloc .v{font-size:20px;font-weight:bold}
 .progre .bloc .l{font-size:11px;color:#888}
 .barre{height:14px;background:#222;border-radius:7px;overflow:hidden;margin:4px 0 12px;width:100%}
 .barre .fill{height:100%;background:linear-gradient(90deg,#0a5,#4f4);transition:width .5s}
 table{border-collapse:collapse;width:100%;margin-top:8px}
 th,td{border:1px solid #333;padding:3px 8px;font-size:12px;text-align:left}
 th{background:#1a1a1a;position:sticky;top:0}
 tr.acc td{color:#4f4} tr.rej td{color:#f66} tr.enc td{color:#4df}
 .stat{display:inline-block;padding:1px 8px;border-radius:3px;font-size:11px}
 .stat.acc{background:#033;color:#4f4} .stat.rej{background:#300;color:#f66}
 .stat.enc{background:#036;color:#4df}
 pre{background:#0a0a0a;border:1px solid #333;padding:8px;max-height:200px;overflow:auto;
      font-size:11px;white-space:pre-wrap;margin:4px 0 12px}
 .section{margin:12px 0}
 .section h2{font-size:14px;color:#aaa;margin:8px 0 4px;border-bottom:1px solid #333;padding-bottom:4px}
 .filtre{margin:8px 0}
 .filtre button{background:#222;color:#ddd;border:1px solid #444;padding:3px 10px;
                margin:2px;cursor:pointer;border-radius:3px;font-size:12px}
 .filtre button.actif{background:#0a5;color:#fff}
 .vie{position:fixed;top:16px;left:16px;display:flex;gap:5px;align-items:center;z-index:99}
 .vie .pt{width:10px;height:10px;border-radius:50%;background:#4f4;animation:pulse 1.5s infinite}
 .vie .pt:nth-child(2){animation-delay:.25s}
 .vie .pt:nth-child(3){animation-delay:.5s}
 @keyframes pulse{0%{opacity:.2;transform:scale(.7)}50%{opacity:1;transform:scale(1.3)}100%{opacity:.2;transform:scale(.7)}}
 .vie .lbl{font-size:11px;color:#4f4;margin-left:6px}
</style></head><body>
<div class="vie"><div class="pt"></div><div class="pt"></div><div class="pt"></div><div class="lbl">EN VIE</div></div>
<button class="stop" onclick="fetch('/stop',{method:'POST'}).then(()=>alert('arrêt demandé'))">■ STOP</button>
<h1>Chaîne du portillon — session 3, étape 11 (en direct)</h1>
<div class="info">Actualisation automatique toutes les 2 s. 217 tests attendus.</div>
__CONTENU__
</body></html>
"""


def construire_page(orch: Orchestrateur) -> str:
    tests = orch.get_tests()
    en_cours = orch.get_en_cours()
    evenements = orch.get_evenements()

    prods = [e for e in evenements if e.get("type") == "prod"]
    evals = [e for e in evenements if e.get("type") == "eval"]
    infos = [e for e in evenements if e.get("type") == "info"]
    raws = [e for e in evenements if e.get("type") == "raw"]
    rapports = [e for e in evenements if e.get("type") == "rapport_ligne"]

    total = 217
    faites = len(tests)
    pct = min(100, round(100 * faites / total)) if total else 0

    # Dernier événement horodaté
    ts_dernier = ""
    candidats_ts: list[str] = []
    if tests:
        candidats_ts.append(tests[-1].get("ts", ""))
    if en_cours:
        candidats_ts.append(en_cours[-1].get("ts", ""))
    if evals:
        candidats_ts.append(evals[-1].get("ts", ""))
    if raws:
        candidats_ts.append(raws[-1].get("ts", ""))
    if infos:
        candidats_ts.append(infos[-1].get("ts", ""))
    for ts in reversed(candidats_ts):
        if ts:
            ts_dernier = ts
            break
    if not ts_dernier:
        ts_dernier = time.strftime("%H:%M:%S")

    h = []
    h.append('<div class="progre">')
    h.append(f'<div class="bloc"><div class="v">{faites}/{total}</div><div class="l">tests éval.</div></div>')
    n_acc = sum(1 for t in tests if t.get("acceptee"))
    n_rej = faites - n_acc
    h.append(f'<div class="bloc"><div class="v" style="color:#4f4">{n_acc}</div><div class="l">acceptées</div></div>')
    h.append(f'<div class="bloc"><div class="v" style="color:#f66">{n_rej}</div><div class="l">rejetées</div></div>')
    h.append(f'<div class="bloc"><div class="v" style="color:#4df">{len(en_cours)}</div><div class="l">en cours</div></div>')
    chrono = _chrono_statique(ts_dernier)
    h.append(f'<div class="bloc"><div class="v" id="chrono" style="color:#ff0">{chrono}</div><div class="l">depuis {ts_dernier}</div></div>')
    h.append('</div>')
    h.append(f'<div class="barre"><div class="fill" style="width:{pct}%"></div></div>')

    if prods:
        h.append('<div class="section"><h2>Production des candidates</h2>')
        for p in prods:
            h.append(f'<div>masquage {p["competence"]} : {p["taches"]} tâches, '
                     f'{p["ecartes"]} écartés ({p["duree_s"]} s)</div>')
        h.append('</div>')

    if evals:
        dernier = evals[-1]
        h.append(f'<div class="info">Dernier compteur : {dernier["faites"]}/{dernier["total"]} '
                 f'évaluées ({dernier["seconde"]} s)</div>')

    if en_cours:
        h.append('<div class="section"><h2>En cours</h2>')
        for t in en_cours:
            h.append(f'<div>⏳ <b>{t["nom"]}</b> ({t["competence"]}) — démarré à {t["ts"]}</div>')
        h.append('</div>')

    h.append('<div class="section"><h2>Tests ({})</h2>'.format(faites))
    h.append('<div class="filtre">'
             '<button class="actif" onclick="filtrer(\'all\',this)">Tous</button>'
             '<button onclick="filtrer(\'acc\',this)">Acceptées</button>'
             '<button onclick="filtrer(\'rej\',this)">Rejetées</button>'
             '</div>')
    h.append('<table id="ttests"><thead><tr>'
             '<th>#</th><th>id</th><th>comp.</th><th>statut</th>'
             '<th>raison / verdicts</th><th>durée</th><th>fin</th>'
             '</tr></thead><tbody>')
    for i, t in enumerate(reversed(tests)):
        cls = "acc" if t.get("acceptee") else "rej"
        badge = f'<span class="stat {cls}">{"✓" if t.get("acceptee") else "✗"}</span>'
        idx = faites - 1 - i
        h.append(f'<tr class="{cls}" data-s="{cls}">'
                 f'<td>{idx}</td><td>{t["nom"]}</td><td>{t.get("competence", "")}</td>'
                 f'<td>{badge}</td><td>{t.get("raison", "")}</td>'
                 f'<td>{t.get("duree_s", 0):.1f}s</td><td>{t.get("ts", "")}</td></tr>')
    for t in reversed(en_cours):
        h.append(f'<tr class="enc" data-s="enc">'
                 f'<td>…</td><td>{t["nom"]}</td><td>{t.get("competence", "")}</td>'
                 f'<td><span class="stat enc">⏳</span></td><td></td><td></td><td>{t.get("ts", "")}</td></tr>')
    h.append('</tbody></table>')
    h.append('<script>'
             'function filtrer(s,btn){'
             'document.querySelectorAll("#ttests tbody tr").forEach(function(tr){'
             'tr.style.display=(s==="all"||tr.getAttribute("data-s")===s)?"":"none";});'
             'document.querySelectorAll(".filtre button").forEach(function(b){b.classList.remove("actif");});'
             'btn.classList.add("actif");}'
             '</script>')

    if rapports:
        h.append('<div class="section"><h2>Rapport final</h2><pre>')
        for r in rapports:
            h.append(r.get("txt", "").replace("<", "&lt;"))
        h.append('</pre></div>')

    if infos:
        h.append('<div class="section"><h2>Journal</h2><pre>')
        for i in reversed(infos[-30:]):
            h.append(i.get("txt", "").replace("<", "&lt;"))
        h.append('</pre></div>')

    if raws:
        h.append('<div class="section"><h2>Autres lignes</h2><pre>')
        for r in reversed(raws[-50:]):
            h.append(r.get("txt", "").replace("<", "&lt;"))
        h.append('</pre></div>')

    return HTML_PAGE.replace("__CONTENU__", "\n".join(h))


class Handler(BaseHTTPRequestHandler):
    server: "ThreadingHTTPServer"

    def log_message(self, *args):
        pass

    def _envoyer(self, corps: bytes, content_type: str) -> None:
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(corps)))
        self.end_headers()
        self.wfile.write(corps)

    def do_GET(self) -> None:
        if self.path in ("/", "/index.html"):
            self._envoyer(construire_page(self.server.orchestrateur).encode("utf-8"),
                          "text/html; charset=utf-8")
        else:
            self.send_error(404)

    def do_POST(self) -> None:
        if self.path == "/stop":
            self.server.orchestrateur.arrêt.set()
            if self.server.orchestrateur.proc:
                self.server.orchestrateur.proc.kill()
            self._envoyer("arrêt demandé\n".encode("utf-8"), "text/plain; charset=utf-8")
        else:
            self.send_error(404)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--port", type=int, default=8788)
    p.add_argument("--relancer", action="store_true",
                   help="efface les logs avant de démarrer")
    args = p.parse_args()
    if args.relancer:
        EVENTS.unlink(missing_ok=True)
        CHAIN_LOG.unlink(missing_ok=True)
    serveur = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    serveur.orchestrateur = Orchestrateur()
    serveur.orchestrateur.start()
    print(f"Dashboard chaîne : http://127.0.0.1:{args.port}/  (Ctrl+C pour tout arrêter)", flush=True)
    try:
        serveur.serve_forever()
    except KeyboardInterrupt:
        print("\nArrêt (Ctrl+C)…", flush=True)
        serveur.orchestrateur.arrêt.set()
        if serveur.orchestrateur.proc:
            serveur.orchestrateur.proc.kill()
        serveur.orchestrateur.join(timeout=10)
    return 0


if __name__ == "__main__":
    sys.exit(main())
