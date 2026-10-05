"""CLI des générateurs.

    python -m usine.generateurs produire [--graine 1] [--sortie DOSSIER] [--f1 40] [--travailleurs 4]
                                         [--sources reference survivor …]
    python -m usine.generateurs mutants <projet> <dossier_tests> [--max N] [--graine G]
    python -m usine.generateurs invention <proposition.json> [--sortie DOSSIER]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from usine import config as cfg


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "mutants":
        from usine.generateurs.mutants import main as main_mutants
        return main_mutants(argv[1:])
    parser = argparse.ArgumentParser(prog="python -m usine.generateurs")
    sous = parser.add_subparsers(dest="commande", required=True)
    p = sous.add_parser("produire", help="écrire toutes les tâches candidates")
    p.add_argument("--graine", type=int, default=1)
    p.add_argument("--sortie", type=Path, default=cfg.dossier_donnees() / "candidats")
    p.add_argument("--f1", type=int, default=40, help="nombre de tirages F1")
    p.add_argument("--travailleurs", type=int, default=4)
    p.add_argument("--sources", nargs="*", default=None, help="projets sources (défaut : tous, voir sources.py)")
    sous.add_parser("mutants", help="score de mutation d'un dossier de tests (voir mutants.py)")
    p = sous.add_parser("invention", help="valider une proposition de tâche et l'écrire")
    p.add_argument("proposition", type=Path)
    p.add_argument("--sortie", type=Path, default=cfg.dossier_donnees() / "inventions")
    args = parser.parse_args(argv)

    if args.commande == "produire":
        from usine.generateurs.produire import produire
        prod = produire(args.sortie, args.graine, nombre_f1=args.f1, travailleurs=args.travailleurs,
                        sources=args.sources)
        print(f"{len(prod.taches)} tâches candidates dans {args.sortie}")
        return 0 if prod.taches else 1
    from usine.generateurs.invention import ErreurInvention, materialiser
    from usine.portillon.exclusion import Exclusion
    try:
        dossier = materialiser(json.loads(args.proposition.read_text(encoding="utf-8")), args.sortie,
                               Exclusion.charger())
    except ErreurInvention as e:
        print(json.dumps({"ok": False, "erreurs": e.erreurs}, ensure_ascii=False, indent=1))
        return 1
    print(json.dumps({"ok": True, "dossier": str(dossier)}, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
