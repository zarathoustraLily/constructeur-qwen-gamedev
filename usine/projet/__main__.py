"""CLI : vue du projet et langage d'édition.

    python -m usine.projet describe <projet> [--json]
    python -m usine.projet apply <projet> <edits.json> [--sans-juge]
    python -m usine.projet demo [--projet godot/reference]

`apply` modifie le projet seulement si toutes les éditions sont acceptées et que le juge
passe (tout ou rien) ; code de retour 0 si appliqué, 1 sinon.
`demo` travaille sur une copie jetable : démo PASS, puis deux listes fausses refusées,
avec l'empreinte du projet avant/après.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import shutil
import sys
import tempfile
from pathlib import Path

from usine import config as cfg

EXEMPLES = Path(__file__).resolve().parent / "exemples"


def empreinte_dossier(dossier: Path) -> str:
    """SHA-256 des chemins et contenus de tous les fichiers (hors .godot)."""
    h = hashlib.sha256()
    for f in sorted(p for p in Path(dossier).rglob("*") if p.is_file() and ".godot" not in p.relative_to(dossier).parts):
        h.update(f.relative_to(dossier).as_posix().encode("utf-8") + b"\n")
        h.update(hashlib.sha256(f.read_bytes()).hexdigest().encode("ascii"))
    return h.hexdigest()


def _imprimer(objet) -> None:
    print(json.dumps(objet, ensure_ascii=False, indent=1))


def demo(projet_ref: Path) -> int:
    from usine.projet.editions import apply_edits
    from usine.juge.projet import IGNORES_COPIE

    echecs = 0
    with tempfile.TemporaryDirectory(prefix="usine_demo_") as tmp:
        copie = Path(tmp) / "projet"
        shutil.copytree(projet_ref, copie, ignore=IGNORES_COPIE)
        cas = [("demo_reference", True), ("faux_id_reference", False), ("faux_juge_reference", False)]
        for nom, attendu in cas:
            edits = json.loads((EXEMPLES / f"{nom}.json").read_text(encoding="utf-8"))
            avant = empreinte_dossier(copie)
            textes_avant = {p.relative_to(copie).as_posix(): p.read_text(encoding="utf-8")
                            for p in copie.rglob("*") if p.is_file() and p.suffix in (".gd", ".tscn")}
            verdict = apply_edits(copie, edits)
            apres = empreinte_dossier(copie)
            print(f"== {nom} : {edits.get('description', '')}")
            resume = {k: verdict[k] for k in ("ok", "applique", "etape", "erreurs", "tests", "fichiers")}
            _imprimer(resume)
            print(f"empreinte avant : {avant}")
            print(f"empreinte après : {apres}")
            conforme = verdict["applique"] == attendu and ((avant != apres) if attendu else (avant == apres))
            if attendu:
                for p in sorted(copie.rglob("*")):
                    rel = p.relative_to(copie).as_posix()
                    if p.is_file() and p.suffix in (".gd", ".tscn"):
                        nouveau = p.read_text(encoding="utf-8")
                        ancien = textes_avant.get(rel, "")
                        if nouveau != ancien:
                            sys.stdout.writelines(difflib.unified_diff(ancien.splitlines(True), nouveau.splitlines(True),
                                                                       f"a/{rel}", f"b/{rel}"))
            print(f"=> {'CONFORME' if conforme else 'NON CONFORME'} "
                  f"({'appliqué, PASS' if attendu else 'refusé, projet intact'} attendu)\n")
            echecs += not conforme
    print(f"{len(cas) - echecs}/{len(cas)} cas conformes")
    return 0 if echecs == 0 else 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m usine.projet", description="describe_project / apply_edits (sans LLM).")
    sous = parser.add_subparsers(dest="commande", required=True)
    p = sous.add_parser("describe", help="vue compacte du projet")
    p.add_argument("projet", type=Path)
    p.add_argument("--json", action="store_true", help="vue structurée (avec la table des ids)")
    p = sous.add_parser("apply", help="appliquer une liste d'éditions (tout ou rien)")
    p.add_argument("projet", type=Path)
    p.add_argument("edits", type=Path)
    p.add_argument("--sans-juge", action="store_true", help="ne pas lancer Godot (tests de l'outil seulement)")
    p = sous.add_parser("demo", help="démo PASS + éditions fausses refusées, sur une copie")
    p.add_argument("--projet", type=Path, default=cfg.RACINE / "godot" / "reference")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    if args.commande == "describe":
        from usine.projet.decrire import describe_project
        vue = describe_project(args.projet)
        if args.json:
            _imprimer(vue)
        else:
            sys.stdout.write(vue["texte"])
        return 0
    if args.commande == "apply":
        from usine.projet.editions import apply_edits
        edits = json.loads(args.edits.read_text(encoding="utf-8"))
        from usine.juge.projet import ETAPES
        verdict = apply_edits(args.projet, edits, etapes=() if args.sans_juge else ETAPES)
        _imprimer(verdict)
        return 0 if verdict["applique"] else 1
    if args.commande == "demo":
        return demo(args.projet)
    return 2


if __name__ == "__main__":
    sys.exit(main())
