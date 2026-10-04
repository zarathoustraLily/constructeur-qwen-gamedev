"""CLI de la spec de scène.

    python -m usine.scene lire <scene.tscn> [--res res://…]           → spec JSON
    python -m usine.scene ecrire <spec.json> [-o sortie.tscn] [--projet DIR]
    python -m usine.scene valider <spec.json> [--projet DIR]
    python -m usine.scene preuve [--projet godot/reference] [--sans-godot] [--sans-generees]

`ecrire` et `valider` vérifient la spec contre le vocabulaire (et les scripts du projet
si --projet est donné) ; code de retour 1 si la spec est refusée.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from usine import config as cfg
from usine.scene.spec import ErreurSpec, scene_read, scene_write, valider_spec


def _verif(projet: Path | None):
    from usine.projet.index import Projet, Verificateur
    from usine.vocab import ouvrir
    return Verificateur(ouvrir(), Projet(projet) if projet else None)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m usine.scene", description="Spec de scène ↔ .tscn (sans LLM).")
    sous = parser.add_subparsers(dest="commande", required=True)
    p = sous.add_parser("lire", help=".tscn → spec JSON")
    p.add_argument("scene", type=Path)
    p.add_argument("--res", help="chemin res:// de la scène (défaut : déduit du project.godot parent)")
    p = sous.add_parser("ecrire", help="spec JSON → .tscn")
    p.add_argument("spec", type=Path)
    p.add_argument("-o", "--sortie", type=Path)
    p.add_argument("--projet", type=Path)
    p = sous.add_parser("valider", help="vérifier une spec contre le vocabulaire")
    p.add_argument("spec", type=Path)
    p.add_argument("--projet", type=Path)
    p = sous.add_parser("preuve", help="aller-retour sur un projet + 5 scènes générées")
    p.add_argument("--projet", type=Path, default=cfg.RACINE / "godot" / "reference")
    p.add_argument("--sans-godot", action="store_true")
    p.add_argument("--sans-generees", action="store_true", help="ne pas ajouter les 5 scènes générées (autre projet que la référence)")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    if args.commande == "lire":
        res = args.res
        if res is None:
            from usine.juge.godot import chemin_res, trouver_projet
            try:
                res = chemin_res(args.scene, trouver_projet(args.scene))
            except (FileNotFoundError, ValueError):
                res = None
        spec = scene_read(args.scene.read_text(encoding="utf-8"), res)
        print(json.dumps(spec, ensure_ascii=False, indent=1))
        return 0
    if args.commande in ("ecrire", "valider"):
        spec = json.loads(args.spec.read_text(encoding="utf-8"))
        verif = _verif(args.projet)
        erreurs = valider_spec(spec, verif)
        if erreurs:
            print(json.dumps({"ok": False, "etape": "validation", "erreurs": erreurs}, ensure_ascii=False, indent=1))
            return 1
        if args.commande == "valider":
            print(json.dumps({"ok": True, "etape": "validation", "erreurs": []}, ensure_ascii=False, indent=1))
            return 0
        try:
            texte = scene_write(spec, verif)
        except ErreurSpec as exc:
            print(json.dumps({"ok": False, "etape": "ecriture", "erreurs": [{"message": str(exc)}]}, ensure_ascii=False))
            return 1
        if args.sortie:
            args.sortie.parent.mkdir(parents=True, exist_ok=True)
            args.sortie.write_text(texte, encoding="utf-8", newline="\n")
        else:
            sys.stdout.write(texte)
        return 0
    if args.commande == "preuve":
        from usine.scene.preuve import preuve
        return preuve(args.projet, avec_godot=not args.sans_godot, avec_generees=not args.sans_generees)
    return 2


if __name__ == "__main__":
    sys.exit(main())
