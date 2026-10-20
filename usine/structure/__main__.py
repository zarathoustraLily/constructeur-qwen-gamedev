"""python -m usine.structure verifier <projet>"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from usine.structure import verifier_projet


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m usine.structure")
    sous = parser.add_subparsers(dest="commande", required=True)
    v = sous.add_parser("verifier", help="juge de structure d'un projet (verdict JSON)")
    v.add_argument("projet", type=Path)
    args = parser.parse_args(argv)
    verdict = verifier_projet(args.projet)
    print(json.dumps(verdict, ensure_ascii=False, indent=1))
    return 0 if verdict["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
