"""CLI de l'entraînement : écrire les réglages de LLaMA-Factory, puis lancer (avec l'accord de laurent).

    python -m usine.entrainement reglages --etape 1 --jeu <dossier> --nom <nom du jeu> [--sortie <dossier>]
                                          [--reprise <LoRA de l'étape précédente>]
    python -m usine.entrainement lancer --yaml <etape_N.yaml> [--cli <llamafactory-cli.exe>]
"""

from __future__ import annotations

import argparse
import json
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
    lc = sous.add_parser("lancer", help="lancer LLaMA-Factory ; journal et bilan dans le dossier du LoRA")
    lc.add_argument("--yaml", type=Path, required=True)
    lc.add_argument("--cli", default=None, help="llamafactory-cli (défaut : [entrainement] llamafactory de config.toml)")
    args = parseur.parse_args(argv)
    if args.commande == "lancer":
        from usine.entrainement import lancer
        bilan = lancer.lancer(args.yaml, args.cli)
        print(json.dumps({k: v for k, v in bilan.items() if k != "pertes"}, ensure_ascii=False, indent=1))
        print("dernières pertes :", bilan["pertes"][-3:])
        return 0 if bilan["code"] == 0 and bilan["adaptateur"] else 1
    sortie = args.sortie or args.jeu / f"lora_etape_{args.etape}"
    chemin = reglages.ecrire(args.etape, args.jeu.resolve(), args.nom, sortie.resolve(), args.reprise)
    print(f"écrit : {chemin}")
    print(f"à lancer (accord de laurent) : python -m usine.entrainement lancer --yaml {chemin}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
