"""python -m usine.regles verifier <projet> [res://fichier …]"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from usine.regles import par_regle, verifier_regles


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m usine.regles")
    sous = parser.add_subparsers(dest="commande", required=True)
    v = sous.add_parser("verifier", help="juge les règles d'architecture mécaniques d'un projet rangé")
    v.add_argument("projet", type=Path)
    v.add_argument("fichiers", nargs="*")
    args = parser.parse_args(argv)
    verdict = verifier_regles(args.projet.resolve(), args.fichiers or None)
    if not verdict["applicable"]:
        print("projet sans plan numéroté : règles non jugées")
        return 0
    for e in verdict["erreurs"]:
        print(f"{e['fichier']}:{e['ligne'] or ''}  {e['message']}")
    print(f"{len(verdict['erreurs'])} violation(s) {par_regle(verdict)}")
    return 0 if verdict["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
