"""CLI de l'entraînement : écrire les réglages de LLaMA-Factory (rien n'est lancé).

    python -m usine.entrainement reglages --etape 1 --jeu <dossier> --nom <nom du jeu> [--sortie <dossier>]
                                          [--reprise <LoRA de l'étape précédente>]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from usine.entrainement import reglages


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parseur = argparse.ArgumentParser(prog="python -m usine.entrainement")
    sous = parseur.add_subparsers(dest="commande", required=True)
    r = sous.add_parser("reglages", help="écrire etape_<N>.yaml dans le dossier du jeu")
    r.add_argument("--etape", type=int, required=True, choices=[1, 2, 3])
    r.add_argument("--jeu", type=Path, required=True)
    r.add_argument("--nom", required=True, help="nom du jeu dans dataset_info.json")
    r.add_argument("--sortie", type=Path, default=None, help="dossier du LoRA (défaut : <jeu>/lora_etape_<N>)")
    r.add_argument("--reprise", type=Path, default=None, help="LoRA de l'étape précédente")
    args = parseur.parse_args(argv)
    sortie = args.sortie or args.jeu / f"lora_etape_{args.etape}"
    chemin = reglages.ecrire(args.etape, args.jeu.resolve(), args.nom, sortie.resolve(), args.reprise)
    print(f"écrit : {chemin}")
    print(f"à lancer par laurent : llamafactory-cli train {chemin}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
