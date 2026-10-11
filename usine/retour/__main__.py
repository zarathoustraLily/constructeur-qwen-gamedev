"""python -m usine.retour verifier <projet> [res://script.gd …]
python -m usine.retour capturer <projet> --images 30,90,150 [--scene res://…] [--touche move_up:10-70] [--sortie dossier]

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
    c = sous.add_parser("capturer", help="grille d'images horodatées du jeu, avec le journal Trace")
    c.add_argument("projet", type=Path)
    c.add_argument("--images", default="30,90,150,210,270,330,390,450", help="numéros d'image, à 60 images/s")
    c.add_argument("--scene", help="scène à lancer (défaut : la scène principale)")
    c.add_argument("--touche", action="append", default=[], help="action:de-à, ex. move_up:10-70 (répétable)")
    c.add_argument("--sortie", type=Path, help="dossier du PNG et de sa légende (défaut : dossier temporaire)")
    args = parser.parse_args(argv)

    if args.commande == "capturer":
        from usine.retour.capture import capturer
        r = capturer(args.projet.resolve(), [int(x) for x in args.images.split(",") if x.strip()], args.scene,
                     args.touche, args.sortie)
        print(r["legende"] or r.get("erreur", ""))
        print(f"grille : {r['grille'] or 'aucune'}")
        return 0 if r["ok"] else 1

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
