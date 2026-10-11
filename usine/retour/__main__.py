"""python -m usine.retour verifier <projet> [res://script.gd …]

Affiche, pour chaque script (tous ceux du projet par défaut, hors addons), le retour que Qwen
reçoit après l'avoir écrit : membres Godot inconnus et signatures officielles.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from usine.retour import IndexProjet, formater_rapport, verifier_script
from usine.vocab import ouvrir


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m usine.retour")
    sous = parser.add_subparsers(dest="commande", required=True)
    v = sous.add_parser("verifier", help="vérifie le vocabulaire Godot des scripts d'un projet")
    v.add_argument("projet", type=Path)
    v.add_argument("scripts", nargs="*", help="res://… (défaut : tous les scripts hors addons)")
    v.add_argument("--signatures", action="store_true", help="affiche aussi les signatures des membres reconnus")
    args = parser.parse_args(argv)

    projet = args.projet.resolve()
    vocab = ouvrir()
    index = IndexProjet.lire(projet)
    scripts = args.scripts or [c for c in sorted(index.scripts) if not c.startswith("res://addons/")]
    total = 0
    for res in scripts:
        texte = (projet / res.removeprefix("res://")).read_text(encoding="utf-8", errors="replace")
        rapport = verifier_script(texte, res, vocab, index)
        total += len(rapport["problemes"])
        if not args.signatures:
            rapport["signatures"] = []
        if rapport["problemes"] or args.signatures:
            print(formater_rapport(rapport, res, vocab.version()), end="\n\n")
    print(f"{len(scripts)} scripts, {total} problème(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
