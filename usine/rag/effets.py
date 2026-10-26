"""Catalogue d'effets et de shaders du RAG (étape R1 du suivi) : une fiche et un exemple vérifié par effet.

`rag/effets/effets.toml` liste les effets : titre, ce que fait l'effet, quand l'employer, pièges (chacun mesuré par
l'exemple, cité dans sa source, ou marqué « non mesuré ici »). `rag/effets/<id>/exemple/` contient l'exemple : ses
shaders et `exemple.gd`, qui construit la scène, pilote l'effet par ses fonctions publiques, laisse le moteur dessiner,
lit les pixels de l'image rendue et écrit « EXEMPLE VERIFIE » si l'effet s'y voit comme prévu.

Un shader ne se compile qu'au rendu (règle 5.4) : chaque exemple tourne fenêtre hors de l'écran, en Compatibilité,
comme les rendus des cours, avec le bloc `[debug]` strict du socle (règle 5.3). L'exemple réussit s'il écrit la marque
et si la sortie ne contient ni erreur ni avertissement (règle 5.5). Après une réussite, `rag/effets/<id>/fiche.md`, que
lit le RAG, est réécrite : son code (shaders, fonctions de pilotage) est recopié des fichiers que Godot vient de faire
tourner, et sa mesure est la ligne écrite par l'exemple.

    python -m usine.rag.effets verifier [id …]
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import time
import tomllib
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.rag.plugins import IMAGES_MAX, MARQUE, bloc_debug, lancer, problemes, reussi, type_racine

DOSSIER = cfg.RACINE / "rag" / "effets"
MANIFESTE = DOSSIER / "effets.toml"
FENETRE = ["--rendering-method", "gl_compatibility", "--position", "-10000,-10000"]
RE_FONCTION_PUBLIQUE = re.compile(r"^func ([a-z][a-z0-9_]*)\(")
RANGEMENT = ("Dans un projet qui suit le plan, le shader va dans `6_assets/` (aucun code) et ses réglages (couleurs, "
             "durées) dans un `.tres` de `5_data/` (principe 2) ; la fonction qui le pilote va dans la présentation : "
             "le `_view.gd` de l'entité, ou `4_ui/` pour un effet d'écran (principe 1).")


def manifeste(chemin: Path | None = None) -> dict[str, dict[str, Any]]:
    return tomllib.loads(Path(chemin or MANIFESTE).read_text(encoding="utf-8"))


def effets() -> list[str]:
    return sorted(manifeste())


def fonctions_publiques(script: str) -> str:
    """Les fonctions sans `_` de tête, avec leur commentaire de documentation (`##`) : le pilotage de l'effet."""
    lignes = script.splitlines()
    blocs = []
    for i, ligne in enumerate(lignes):
        if not RE_FONCTION_PUBLIQUE.match(ligne):
            continue
        debut = i
        while debut > 0 and lignes[debut - 1].startswith("##"):
            debut -= 1
        fin = i + 1
        while fin < len(lignes) and (not lignes[fin].strip() or lignes[fin][0] in " \t"):
            fin += 1
        blocs.append("\n".join(lignes[debut:fin]).rstrip())
    return "\n\n\n".join(blocs)


def fiche(ident: str, entree: dict[str, Any], mesure: str, dossier: Path | None = None) -> str:
    exemple = Path(dossier or DOSSIER) / ident / "exemple"
    lignes = [f"# {entree['titre']}", "",
              "Exemple vérifié dans Godot 4.7.2, rendu en Compatibilité, fenêtre hors de l'écran, en lisant les pixels "
              f"de l'image : `python -m usine.rag.effets verifier {ident}`.", "",
              "## Ce que fait l'effet", "", entree["fait"], "",
              "## Quand l'employer", "", entree["quand"], "", RANGEMENT, ""]
    for shader in sorted(exemple.glob("*.gdshader")):
        lignes += [f"## Le shader (`{shader.name}`, vérifié)", "", "```glsl",
                   shader.read_text(encoding="utf-8").rstrip(), "```", ""]
    pilotage = fonctions_publiques((exemple / "exemple.gd").read_text(encoding="utf-8"))
    if pilotage:
        lignes += ["## Le piloter depuis GDScript (vérifié)", "", "```gdscript", pilotage, "```", ""]
    lignes += ["## Ce que l'exemple mesure", "", f"`exemple/exemple.gd` : {mesure}.", "",
               "## Pièges", ""] + [f"- {p}" for p in entree["pieges"]] + [""]
    return "\n".join(lignes)


def preparer(ident: str, projet: Path) -> None:
    shutil.copytree(DOSSIER / ident / "exemple", projet / "exemple")
    script = (projet / "exemple" / "exemple.gd").read_text(encoding="utf-8")
    (projet / "exemple" / "main.tscn").write_text(
        '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://exemple/exemple.gd" id="1"]\n\n'
        f'[node name="Exemple" type="{type_racine(script)}"]\nscript = ExtResource("1")\n', encoding="utf-8")
    (projet / "project.godot").write_text(
        f'config_version=5\n\n[application]\n\nconfig/name="effet {ident}"\n'
        'config/features=PackedStringArray("4.7")\n\n'
        '[rendering]\n\nrenderer/rendering_method="gl_compatibility"\n\n' + bloc_debug(), encoding="utf-8")


def verifier(ident: str, donnees: Path | None = None) -> dict[str, Any]:
    racine = Path(donnees or cfg.dossier_donnees()) / "effets" / "travail" / ident
    for ancien in racine.glob("*") if racine.exists() else []:
        shutil.rmtree(ancien, ignore_errors=True)
    projet = racine / time.strftime("%Y%m%d-%H%M%S")
    preparer(ident, projet)
    for _ in range(2):  # Godot 4.7.2 plante parfois en sortant de l'import (0xC0000005), sans message : on relance
        code, sortie = lancer(["--headless", "--path", str(projet), "--import"])
        if code < 0xC0000000 or problemes(sortie):
            break
    if code != 0 or problemes(sortie):
        return {"id": ident, "ok": False, "etape": "import", "code": code, "lignes": problemes(sortie)[:20]}
    code, sortie = lancer([*FENETRE, "--path", str(projet), "--fixed-fps", "60", "--quit-after", str(IMAGES_MAX),
                           "res://exemple/main.tscn"])
    marque = next((l.strip() for l in sortie.splitlines() if MARQUE in l), None)
    return {"id": ident, "ok": reussi(code, sortie), "etape": "exemple", "code": code, "marque": marque,
            "lignes": problemes(sortie)[:20]}


def main(argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parseur = argparse.ArgumentParser(prog="python -m usine.rag.effets")
    sous = parseur.add_subparsers(dest="commande", required=True)
    p_v = sous.add_parser("verifier", help="rendre l'exemple de chaque effet en Compatibilité, lire ses pixels, "
                                           "réécrire sa fiche s'il passe")
    p_v.add_argument("ids", nargs="*")
    args = parseur.parse_args(argv)
    catalogue = manifeste()
    ids = args.ids or sorted(catalogue)
    inconnus = [i for i in ids if i not in catalogue]
    if inconnus:
        parseur.error(f"effets absents de {MANIFESTE.name} : {', '.join(inconnus)}")
    sortie = cfg.dossier_donnees() / "effets" / "verification.json"
    anciens = json.loads(sortie.read_text(encoding="utf-8")) if sortie.is_file() else []
    bilans = {b["id"]: b for b in anciens if b["id"] in catalogue}
    reussis = 0
    for ident in ids:
        b = verifier(ident)
        bilans[ident] = b
        print(f"{ident} : {'ok' if b['ok'] else 'ÉCHEC à l’étape ' + b['etape']} {b.get('marque') or ''}")
        for ligne in b["lignes"]:
            print("    " + ligne)
        if b["ok"]:
            reussis += 1
            mesure = b["marque"].split(MARQUE, 1)[1].lstrip(" :")
            (DOSSIER / ident / "fiche.md").write_text(fiche(ident, catalogue[ident], mesure), encoding="utf-8",
                                                      newline="\n")
    sortie.parent.mkdir(parents=True, exist_ok=True)
    sortie.write_text(json.dumps([bilans[i] for i in sorted(bilans)], indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"{reussis}/{len(ids)} exemples vérifiés, leurs fiches réécrites ; bilan : {sortie}")
    return 0 if reussis == len(ids) else 1


if __name__ == "__main__":
    sys.exit(main())
