"""CLI des paires courtes.

    python -m usine.paires camera [--niveaux N] [--graine G] [--paires P]
"""

from __future__ import annotations

import argparse
import json
import sys


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parseur = argparse.ArgumentParser(prog="python -m usine.paires")
    sous = parseur.add_subparsers(dest="famille", required=True)
    p = sous.add_parser("camera", help="situer la caméra et les objets (voir_scene), cas vérifiés par deux rendus")
    p.add_argument("--niveaux", type=int, default=2)
    p.add_argument("--graine", type=int, default=1)
    p.add_argument("--paires", type=int, default=None, help="s'arrêter au niveau qui atteint P paires (niveaux devient un plafond)")
    args = parseur.parse_args(argv)
    if args.famille == "camera":
        from usine.paires.camera import generer
        bilan = generer(args.niveaux, args.graine, cible=args.paires)
        print(json.dumps({k: v for k, v in bilan.items() if k != "rejets"}, ensure_ascii=False, indent=1))
        for r in bilan["rejets"]:
            print("rejet :", r)
        return 0 if bilan["paires"] else 1
    return 2


if __name__ == "__main__":
    sys.exit(main())
