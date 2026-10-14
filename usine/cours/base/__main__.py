"""CLI de la base « bâtiments procéduraux ».

    python -m usine.cours.base generer [--villes parisien …] [--etapes 1 2 …] [--travailleurs 2] [--refaire]
    python -m usine.cours.base assembler
    python -m usine.cours.base tout [--travailleurs 2]

Chemins (sinon lus dans config.toml) : --docs (godot-docs), --source-godot (godot à l'étiquette 4.7.2-stable),
--vocab (models/ggml-vocab-qwen35.gguf de llama.cpp), --vocab-qwen2 (models/ggml-vocab-qwen2.gguf, facultatif).
"""

from __future__ import annotations

import argparse
import sys


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(prog="python -m usine.cours.base")
    sous = parser.add_subparsers(dest="commande", required=True)
    for nom, aide in (("generer", "exemples de création et sessions de débogage, étape par étape"),
                      ("assembler", "contrôles, statistiques, fichiers d'entraînement"),
                      ("tout", "generer, puis assembler")):
        p = sous.add_parser(nom, help=aide)
        p.add_argument("--docs")
        p.add_argument("--source-godot")
        p.add_argument("--vocab")
        p.add_argument("--vocab-qwen2")
        if nom != "assembler":
            p.add_argument("--villes", nargs="*")
            p.add_argument("--etapes", nargs="*", type=int)
            p.add_argument("--travailleurs", type=int, default=1)
            p.add_argument("--refaire", action="store_true", help="refaire les étapes déjà générées")
    args = parser.parse_args(argv)
    reglages = {"docs": args.docs, "source_godot": args.source_godot, "vocab": args.vocab,
                "vocab_qwen2": args.vocab_qwen2}

    from usine.cours.base import chemins
    chemins.configurer(**reglages)
    if args.commande in ("generer", "tout"):
        from usine.cours.base.generer import generer
        echecs = generer(args.villes, args.etapes, args.travailleurs, reglages, args.refaire,
                         journal=lambda t: print(t, flush=True))
        if echecs:
            print(f"{echecs} étape(s) en échec : voir ci-dessus")
            return 1
    if args.commande in ("assembler", "tout"):
        from usine.cours.base.assembler import assembler
        controles = assembler(journal=lambda t: print(t, flush=True))
        return 0 if not controles["problemes"] else 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
