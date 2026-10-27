"""Capture de ce qu'OpenCode envoie au modèle (étape A5 du suivi), sans Qwen ni llama-server.

    python outils/capturer_opencode.py --travail <dossier hors de tout dépôt git> [--cli <opencode-cli.exe>]
                                       [--python <python avec mcp>] [--port 8097] [--attente 25]

- Bac à sable : `<travail>/bac/` reçoit la configuration, les données, l'état et le cache d'OpenCode (variables
  XDG_* ; vérifié par `opencode debug paths`). La configuration globale de laurent, son historique et son service de
  fond ne sont ni lus ni touchés. Configuration globale du bac : le fournisseur « sonde » (`usine/capture/sonde.py`,
  sur 127.0.0.1).
- Projet : une copie du socle (`godot/socle_jeu`, avec son `AGENTS.md`) dans `<travail>/projet/`, une image de
  l'éditeur (`capture.png`) et un `opencode.json` de projet : le serveur MCP de l'usine et ses fiches, comme
  `outils/opencode_fusion.py` les déclare. Hors de tout dépôt git : OpenCode prend la racine git pour dossier de
  travail, et son dossier dans `PWD` (hérité du shell), qu'on fixe.
- Un serveur OpenCode privé (`serve`, mot de passe jetable dans OPENCODE_PASSWORD) est lancé d'abord ; une session
  d'amorce laisse ses serveurs MCP se connecter, puis la vraie session part (`run --server`). Seul ce PID est arrêté.
- Rien ne part sur le réseau : catalogue des modèles non chargé (`OPENCODE_DISABLE_MODELS_FETCH`), fournisseur local.

Sorties : `donnees/capture_opencode/requetes/requete_<k>.json` (chaque requête d'OpenCode, en-tête d'autorisation
retiré), `journal.json` (décisions de la sonde), `sortie_opencode.txt` et `serveur_opencode.txt` (journaux).
"""

from __future__ import annotations

import argparse
import json
import os
import secrets
import shutil
import subprocess
import sys
import time
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RACINE))

from usine.capture.sonde import AMORCE, MODELE, Sonde  # noqa: E402
from usine.processus import _tuer_arbre, executer  # noqa: E402

CLI = Path.home() / "AppData/Local/Programs/@opencode-aidesktop/resources/opencode-cli.exe"
PYTHON_MCP = Path("C:/Program Files/Python312/python.exe")
MESSAGE = ("Cherche dans la documentation comment déplacer un CharacterBody3D avec move_and_slide, puis regarde "
           "l'image capture.png et dis-moi ce qu'elle montre.")


def preparer(base: Path, port: int, python: Path) -> tuple[Path, dict[str, str]]:
    """Le bac (configuration globale : le fournisseur « sonde ») et la copie du projet (son `opencode.json` : le
    serveur MCP de l'usine et ses fiches, comme `outils/opencode_fusion.py`). La copie est hors de tout dépôt git :
    OpenCode prend la racine git pour dossier de travail, et y lirait la configuration et les consignes d'un autre."""
    bac, projet = base / "bac", base / "projet"
    shutil.rmtree(bac, ignore_errors=True)
    shutil.rmtree(projet, ignore_errors=True)
    env = {}
    for nom in ("CONFIG", "DATA", "STATE", "CACHE"):
        (bac / nom).mkdir(parents=True, exist_ok=True)
        env[f"XDG_{nom}_HOME"] = str(bac / nom)
    env["OPENCODE_DISABLE_MODELS_FETCH"] = "1"
    env["OPENCODE_DISABLE_AUTOUPDATE"] = "1"
    globale = {
        "$schema": "https://opencode.ai/config.json",
        "model": f"sonde/{MODELE}",
        "provider": {"sonde": {"npm": "@ai-sdk/openai-compatible", "name": "Sonde de l'usine",
                               "options": {"baseURL": f"http://127.0.0.1:{port}/v1", "apiKey": "sonde"},
                               "models": {MODELE: {"name": "Sonde", "attachment": True, "tool_call": True,
                                                   "limit": {"context": 131072, "output": 8192}}}}},
    }
    (bac / "CONFIG" / "opencode").mkdir(parents=True, exist_ok=True)
    (bac / "CONFIG" / "opencode" / "opencode.json").write_text(json.dumps(globale, indent=1), encoding="utf-8")
    shutil.copytree(RACINE / "godot" / "socle_jeu", projet, ignore=shutil.ignore_patterns(".godot"))
    image = next((RACINE / "donnees" / "paires" / "lire_editeur" / "images").glob("*.png"), None)
    if image is not None:
        shutil.copyfile(image, projet / "capture.png")
    config = {
        "$schema": "https://opencode.ai/config.json",
        "mcp": {"usine-godot": {"type": "local", "enabled": True, "timeout": 120000,
                                "command": [str(python), str(RACINE / "mcp_serveur" / "serveur.py"), "--projet",
                                            str(projet)]}},
        "skills": {"paths": [str(RACINE / "skills")]},
    }
    (projet / "opencode.json").write_text(json.dumps(config, indent=1, ensure_ascii=False), encoding="utf-8")
    return projet, env


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser()
    p.add_argument("--cli", type=Path, default=CLI)
    p.add_argument("--python", type=Path, default=PYTHON_MCP)
    p.add_argument("--port", type=int, default=8097)
    p.add_argument("--delai", type=int, default=300)
    p.add_argument("--port-opencode", type=int, default=4199)
    p.add_argument("--attente", type=float, default=25, help="secondes laissées aux serveurs MCP pour se connecter")
    p.add_argument("--travail", type=Path, required=True, help="dossier hors de tout dépôt git (bac et projet)")
    args = p.parse_args(argv)
    base = RACINE / "donnees" / "capture_opencode"
    base.mkdir(parents=True, exist_ok=True)
    projet, env = preparer(args.travail, args.port, args.python)
    requetes = base / "requetes"
    shutil.rmtree(requetes, ignore_errors=True)
    sonde = Sonde(args.port, requetes, str(projet / "capture.png"))
    env["PWD"] = str(projet)  # OpenCode prend son dossier de travail dans PWD (hérité du shell), pas dans le cwd
    sonde.demarrer()
    # Un serveur OpenCode privé, lancé d'abord : ses serveurs MCP ont le temps de se connecter, comme dans
    # l'application de bureau, avant le premier message (avec `run --standalone`, la première requête part 0,1 s après
    # le démarrage, avant que le serveur MCP de l'usine réponde, et son catalogue manquait). Seul ce PID est arrêté.
    # Mot de passe jetable de ce serveur privé (le serveur en exige un ; le client le lit dans OPENCODE_PASSWORD).
    env["OPENCODE_PASSWORD"] = secrets.token_urlsafe(24)
    journal_serveur = (base / "serveur_opencode.txt").open("wb")
    serveur = subprocess.Popen([str(args.cli), "serve", "--hostname", "127.0.0.1", "--port", str(args.port_opencode),
                                "--print-logs", "--log-level", "info"], cwd=projet, env={**os.environ, **env},
                               stdin=subprocess.DEVNULL, stdout=journal_serveur, stderr=subprocess.STDOUT,
                               creationflags=getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0))
    adresse = f"http://127.0.0.1:{args.port_opencode}"
    try:
        time.sleep(5)
        # Session d'amorce : le dossier du projet est ouvert, ses serveurs MCP se connectent ; la vraie session suit.
        executer([args.cli, "run", "--server", adresse, "--auto", "-m", f"sonde/{MODELE}", AMORCE], cwd=projet,
                 delai_s=args.delai, env=env)
        time.sleep(args.attente)
        sonde.journal.append({"amorce": "fin"})
        res = executer([args.cli, "run", "--server", adresse, "--auto", "--format", "json", "-m", f"sonde/{MODELE}",
                        MESSAGE], cwd=projet, delai_s=args.delai, env=env)
    finally:
        _tuer_arbre(serveur)
        journal_serveur.close()
        sonde.shutdown()
    (base / "sortie_opencode.txt").write_text(res.sortie, encoding="utf-8")
    (base / "journal.json").write_text(json.dumps(sonde.journal, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"code {res.code}, expiré {res.expire}, {res.duree_s} s, {len(sonde.journal)} requêtes gardées")
    for j in sonde.journal:
        print(j)
    return 0 if sonde.journal else 1


if __name__ == "__main__":
    sys.exit(main())
