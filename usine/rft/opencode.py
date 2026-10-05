"""Harnais OpenCode en mode non interactif (production de données seulement). À CONFIRMER par laurent.

laurent n'utilise que l'application de bureau. Ce mode ne sert qu'à produire des données, avec le
moteur d'OpenCode en ligne de commande :
    opencode run --format json --dir <copie> [--model <fournisseur/modèle>] "<consigne>"
(même forme que le solveur OpenCode de GameDevBench). Si ce moteur n'est pas disponible sur la
machine, l'agent maison (agent.py) prend le relais : `[rft] harnais = "agent"`.

Déroulé d'un essai :
  1. un proxy de capture (usine/capture) démarre sur un port libre, devant llama-server ;
  2. la copie de travail reçoit un opencode.json (outils/opencode_fusion.py) : serveur MCP
     `usine-godot` sur la copie, fiches, et baseURL du fournisseur redirigée vers le proxy ;
  3. OpenCode tourne dans la copie (processus lancé par nous, coupé par PID au-delà du délai) ;
  4. la session capturée par le proxy devient la session de l'essai ; opencode.json est retiré
     de la copie avant le jugement.
"""

from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.mesure.client import Reglages


def _fusion():
    spec = importlib.util.spec_from_file_location("opencode_fusion", cfg.RACINE / "outils" / "opencode_fusion.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def commande(cli: str | list[str], copie: Path, consigne: str, modele: str | None = None) -> list[str]:
    cmd = list(cli) if isinstance(cli, list) else [cli]
    cmd += ["run", "--format", "json", "--dir", str(copie)]
    if modele:
        cmd += ["--model", modele]
    return cmd + [consigne]


def resoudre(copie: Path, consigne: str, competence: str, client: Reglages,
             reglages: dict[str, Any]) -> tuple[list[dict[str, Any]], list[dict[str, Any]], str]:
    """Une session OpenCode sur `copie`. Renvoie (messages, définitions d'outils, fin)."""
    from usine.capture.enregistreur import lire_session
    from usine.capture.proxy import ProxyCapture
    from usine.processus import executer
    fournisseur = reglages.get("fournisseur")
    if not fournisseur:
        raise ValueError("[opencode].fournisseur à renseigner (id du fournisseur llama-server dans la config OpenCode)")
    copie = Path(copie)
    with tempfile.TemporaryDirectory(prefix="usine_capture_") as tmp:
        proxy = ProxyCapture(0, client.url, Path(tmp))
        proxy.demarrer_en_fond()
        config_projet = copie / "opencode.json"
        try:
            fusion = _fusion()
            donnees = fusion.fusionner({}, copie, proxy_url=f"http://127.0.0.1:{proxy.port}/v1", fournisseur=fournisseur)
            config_projet.write_text(json.dumps(donnees, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            consigne_complete = (f"Tâche ({competence}) : {consigne}\n"
                                 "Le projet Godot est le dossier courant. Vérifie avec run_tests avant de finir.")
            res = executer(commande(reglages.get("cli", "opencode"), copie, consigne_complete, reglages.get("modele")),
                           cwd=copie, delai_s=float(reglages.get("delai_s", 1800)))
        finally:
            proxy.shutdown()
            proxy.server_close()
            config_projet.unlink(missing_ok=True)
        sessions = [lire_session(f) for f in sorted(Path(tmp).glob("*.jsonl"))]
    if not sessions:
        return ([{"role": "user", "content": consigne},
                 {"role": "assistant", "content": f"[aucune session capturée ; code {res.code}]"}], [],
                "aucune_session")
    entete, messages = max(sessions, key=lambda s: (s[0].get("echanges", 0), len(s[1])))
    return messages, list(entete.get("tools") or []), "delai" if res.expire else "termine"
