"""CLI du juge.

    python -m usine.juge run <projet> [--filtre res://tests/test_x.gd]
    python -m usine.juge check <script.gd>
    python -m usine.juge scene <scene.tscn>
    python -m usine.juge tests <projet> [--filtre ...]
    python -m usine.juge tache <dossier_tache> [--version depart|reference] [--candidat DOSSIER] [--repeter N]
    python -m usine.juge modeles [--dossier godot/taches_modeles] [--travailleurs N]

Le verdict JSON est écrit sur la sortie standard ; code de retour 0 si ok, 1 sinon.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from usine import config as cfg
from usine.juge import godot as juges
from usine.juge.projet import juger_projet


def _imprimer(objet) -> None:
    print(json.dumps(objet, ensure_ascii=False, indent=1))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m usine.juge", description="Juge commun Godot (sans LLM).")
    sous = parser.add_subparsers(dest="commande", required=True)
    p = sous.add_parser("run", help="juger un projet complet (sur une copie)")
    p.add_argument("projet", type=Path)
    p.add_argument("--filtre", action="append")
    p = sous.add_parser("check", help="--check-only sur un script")
    p.add_argument("script", type=Path)
    p = sous.add_parser("scene", help="charger et instancier une scène")
    p.add_argument("scene", type=Path)
    p = sous.add_parser("tests", help="GdUnit4 sur un projet (sur place)")
    p.add_argument("projet", type=Path)
    p.add_argument("--filtre", action="append")
    p = sous.add_parser("tache", help="juger une tâche")
    p.add_argument("dossier", type=Path)
    p.add_argument("--version", choices=["depart", "reference"], default="reference")
    p.add_argument("--candidat", type=Path, help="projet produit par l'agent (remplace --version)")
    p.add_argument("--repeter", type=int, default=1)
    p = sous.add_parser("modeles", help="FAIL sur depart / PASS sur reference, deux fois, pour chaque tâche")
    p.add_argument("--dossier", type=Path, default=cfg.RACINE / "godot" / "taches_modeles")
    p.add_argument("--travailleurs", type=int, default=2)
    args = parser.parse_args(argv)

    if args.commande == "run":
        verdict = juger_projet(args.projet, args.filtre)
    elif args.commande == "check":
        verdict = juges.check_script(args.script)
    elif args.commande == "scene":
        verdict = juges.load_scene(args.scene)
    elif args.commande == "tests":
        verdict = juges.run_tests(args.projet, args.filtre)
        verdict.pop("journal", None)
    elif args.commande == "tache":
        from usine.taches import juger_tache
        verdicts = [juger_tache(args.dossier, args.version, args.candidat) for _ in range(args.repeter)]
        _imprimer(verdicts[0] if len(verdicts) == 1 else verdicts)
        return 0 if all(v["ok"] for v in verdicts) else 1
    else:
        from usine.taches import verifier_modeles
        return 0 if verifier_modeles(args.dossier, args.travailleurs) else 1
    _imprimer(verdict)
    return 0 if verdict["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
