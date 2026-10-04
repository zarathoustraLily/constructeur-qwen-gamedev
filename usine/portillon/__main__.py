"""CLI du portillon.

    python -m usine.portillon chaine [--graine 1] [--sortie donnees] [--travailleurs 4] [--f1 40]
                                     [--sources reference survivor …] [--completer-gel]
    python -m usine.portillon evaluer <dossier_tache> [--graine 1]
    python -m usine.portillon comparer <rapport1.json> <rapport2.json>
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from usine import config as cfg

CLES_DETERMINISTES = ("acceptees", "acceptees_empreintes", "gelees", "gelees_empreintes", "rejets_par_raison",
                      "competences", "ecartes_a_la_generation", "doublons_avec_geles")


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="python -m usine.portillon")
    sous = parser.add_subparsers(dest="commande", required=True)
    p = sous.add_parser("chaine", help="candidats → portillon → gel → tâches acceptées")
    p.add_argument("--graine", type=int, default=1)
    p.add_argument("--sortie", type=Path, default=cfg.dossier_donnees())
    p.add_argument("--travailleurs", type=int, default=4)
    p.add_argument("--f1", type=int, default=40)
    p.add_argument("--sources", nargs="*", default=None, help="projets sources (défaut : tous, voir sources.py)")
    p.add_argument("--completer-gel", action="store_true",
                   help="compléter un gel existant (nouvelle source) au lieu de le réutiliser tel quel")
    p = sous.add_parser("evaluer", help="règles du portillon sur une tâche")
    p.add_argument("dossier", type=Path)
    p.add_argument("--graine", type=int, default=1)
    p = sous.add_parser("comparer", help="deux rapports de chaîne donnent-ils le même résultat ?")
    p.add_argument("rapports", type=Path, nargs=2)
    args = parser.parse_args(argv)

    if args.commande == "chaine":
        from usine.portillon.chaine import afficher_rapport, chaine
        r = chaine(args.sortie, args.graine, args.travailleurs, args.f1, sources=args.sources,
                   completer_gel=args.completer_gel)
        afficher_rapport(r)
        print(f"Durée : {r['duree_s']} s")
        return 0 if r["acceptees"] and not r["doublons_avec_geles"] else 1
    if args.commande == "evaluer":
        from usine.portillon.regles import Reglages, evaluer
        d = evaluer(args.dossier, Reglages.depuis_config(args.graine))
        print(json.dumps(d.ligne(), ensure_ascii=False, indent=1))
        return 0 if d.acceptee else 1
    a, b = (json.loads(r.read_text(encoding="utf-8")) for r in args.rapports)
    differences = [k for k in CLES_DETERMINISTES if a.get(k) != b.get(k)]
    for k in CLES_DETERMINISTES:
        print(f"{k:<26} {'identique' if k not in differences else 'DIFFÉRENT'}")
        if k in differences and isinstance(a.get(k), dict) and isinstance(b.get(k), dict):
            ids = sorted(i for i in set(a[k]) | set(b[k]) if a[k].get(i) != b[k].get(i))
            print("    " + ", ".join(ids[:20]) + (f" (et {len(ids) - 20} autres)" if len(ids) > 20 else ""))
    print("Résultat identique" if not differences else "Résultats différents")
    return 0 if not differences else 1


if __name__ == "__main__":
    raise SystemExit(main())
