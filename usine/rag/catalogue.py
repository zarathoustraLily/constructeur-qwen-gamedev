"""Catalogues vérifiés du RAG : une fiche et un exemple vérifié par entrée (effets, R1 ; morceaux de code, R2).

`rag/<catalogue>/<catalogue>.toml` liste les entrées : titre, ce que fait l'entrée, quand l'employer, pièges (chacun
mesuré par l'exemple, cité dans sa source, ou marqué « non mesuré ici »), et selon le catalogue où la ranger et les
fichiers du socle qu'elle emploie. `rag/<catalogue>/<id>/exemple/` contient le code de l'entrée (shaders, scripts) et
`exemple.gd`, qui l'emploie par ses fonctions publiques, mesure le résultat (pixels de l'image, ou comportement) et
écrit « EXEMPLE VERIFIE » s'il est conforme.

Chaque exemple tourne dans Godot 4.7.2 avec le bloc `[debug]` strict du socle (règle 5.3) : fenêtre hors de l'écran
en Compatibilité quand il faut un rendu (un shader ne se compile qu'au rendu, règle 5.4), sans fenêtre sinon.
L'exemple réussit s'il écrit la marque et si la sortie ne contient ni erreur ni avertissement (règle 5.5). Après une
réussite, `rag/<catalogue>/<id>/fiche.md`, que lit le RAG, est réécrite : son code est recopié des fichiers que
Godot vient de faire tourner, et sa mesure est la ligne écrite par l'exemple.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import time
import tomllib
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from usine import config as cfg
from usine.rag.plugins import IMAGES_MAX, MARQUE, bloc_debug, lancer, problemes, reussi, type_racine

FENETRE = ["--rendering-method", "gl_compatibility", "--position", "-10000,-10000"]
SOCLE = cfg.RACINE / "godot" / "socle_jeu"
RE_FONCTION_PUBLIQUE = re.compile(r"^func ([a-z][a-z0-9_]*)\(")
LANGAGES = {".gdshader": "glsl", ".gdshaderinc": "glsl", ".gd": "gdscript", ".tres": "ini", ".tscn": "ini"}


@dataclass(frozen=True)
class Catalogue:
    nom: str  # dossier sous rag/ et nom du manifeste
    genre: str  # genre des fragments de fiche dans l'index
    rendu: bool  # par défaut : fenêtre hors de l'écran (True) ou sans fenêtre (False) ; une entrée peut le changer
    rangement: str  # où ranger l'entrée dans un projet qui suit le plan, si l'entrée ne le dit pas
    titre_emploi: str  # titre de la section des fonctions publiques de l'exemple
    verification: str  # comment l'exemple vérifie, pour l'en-tête de la fiche
    # Le code de l'entrée garde dans le projet de vérification son chemin du plan (`exemple/3_entities/robot/robot.gd`
    # devient `res://3_entities/robot/robot.gd`) ; sinon tout reste sous `res://exemple/`.
    code_a_la_racine: bool = False

    @property
    def dossier(self) -> Path:
        return cfg.RACINE / "rag" / self.nom

    @property
    def chemin_manifeste(self) -> Path:
        return self.dossier / f"{self.nom}.toml"


def manifeste(cat: Catalogue) -> dict[str, dict[str, Any]]:
    return tomllib.loads(cat.chemin_manifeste.read_text(encoding="utf-8"))


def fonctions_publiques(script: str) -> str:
    """Les fonctions sans `_` de tête, avec leur commentaire de documentation (`##`) : l'emploi de l'entrée."""
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


def fichiers_de_code(exemple: Path) -> list[Path]:
    """Le code de l'entrée : tout le dossier de l'exemple sauf `exemple.gd` et la scène générée."""
    return sorted(p for p in exemple.rglob("*") if p.is_file() and p.suffix in LANGAGES
                  and p.name not in ("exemple.gd", "main.tscn"))


def fiche(cat: Catalogue, ident: str, entree: dict[str, Any], mesure: str, dossier: Path | None = None) -> str:
    exemple = Path(dossier or cat.dossier) / ident / "exemple"
    lignes = [f"# {entree['titre']}", "",
              f"Exemple vérifié dans Godot 4.7.2, {cat.verification} : "
              f"`python -m usine.rag.{cat.nom} verifier {ident}`.", "",
              "## Ce que fait le morceau" if cat.nom == "morceaux" else "## Ce que fait l'effet", "", entree["fait"], "",
              "## Quand l'employer", "", entree["quand"], "", entree.get("rangement", cat.rangement), ""]
    if entree.get("project_godot"):
        lignes += ["## Le code (`project.godot`, extrait vérifié)", "", "```ini", entree["project_godot"].rstrip(), "```",
                   ""]
    for f in fichiers_de_code(exemple):
        nature = "Le shader" if f.suffix in (".gdshader", ".gdshaderinc") else "Le code"
        lignes += [f"## {nature} (`{f.relative_to(exemple).as_posix()}`, vérifié)", "", f"```{LANGAGES[f.suffix]}",
                   f.read_text(encoding="utf-8").rstrip(), "```", ""]
    emploi = fonctions_publiques((exemple / "exemple.gd").read_text(encoding="utf-8"))
    if emploi:
        lignes += [f"## {cat.titre_emploi} (vérifié)", "", "```gdscript", emploi, "```", ""]
    lignes += ["## Ce que l'exemple mesure", "", f"`exemple/exemple.gd` : {mesure}.", "",
               "## Pièges", ""] + [f"- {p}" for p in entree["pieges"]] + [""]
    return "\n".join(lignes)


def preparer(cat: Catalogue, ident: str, entree: dict[str, Any], projet: Path) -> None:
    source = cat.dossier / ident / "exemple"
    if cat.code_a_la_racine:
        for f in fichiers_de_code(source):
            cible = projet / f.relative_to(source)
            cible.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, cible)
        (projet / "exemple").mkdir(parents=True)
        shutil.copy2(source / "exemple.gd", projet / "exemple" / "exemple.gd")
    else:
        shutil.copytree(source, projet / "exemple")
    for rel in entree.get("socle", []):  # les classes du socle qu'emploie l'entrée, à leur place du plan
        cible = projet / rel
        cible.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(SOCLE / rel, cible)
    script = (projet / "exemple" / "exemple.gd").read_text(encoding="utf-8")
    (projet / "exemple" / "main.tscn").write_text(
        '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://exemple/exemple.gd" id="1"]\n\n'
        f'[node name="Exemple" type="{type_racine(script)}"]\nscript = ExtResource("1")\n', encoding="utf-8")
    (projet / "project.godot").write_text(
        f'config_version=5\n\n[application]\n\nconfig/name="{cat.nom} {ident}"\n'
        'config/features=PackedStringArray("4.7")\n\n' + entree.get("project_godot", "") +
        '[rendering]\n\nrenderer/rendering_method="gl_compatibility"\n\n' + bloc_debug(), encoding="utf-8")


def verifier(cat: Catalogue, ident: str, entree: dict[str, Any], donnees: Path | None = None) -> dict[str, Any]:
    racine = Path(donnees or cfg.dossier_donnees()) / cat.nom / "travail" / ident
    for ancien in racine.glob("*") if racine.exists() else []:
        shutil.rmtree(ancien, ignore_errors=True)
    projet = racine / time.strftime("%Y%m%d-%H%M%S")
    preparer(cat, ident, entree, projet)
    for _ in range(2):  # Godot 4.7.2 plante parfois en sortant de l'import (0xC0000005), sans message : on relance
        code, sortie = lancer(["--headless", "--path", str(projet), "--import"])
        if code < 0xC0000000 or problemes(sortie):
            break
    if code != 0 or problemes(sortie):
        return {"id": ident, "ok": False, "etape": "import", "code": code, "lignes": problemes(sortie)[:20]}
    affichage = FENETRE if entree.get("rendu", cat.rendu) else ["--headless"]
    code, sortie = lancer([*affichage, "--path", str(projet), "--fixed-fps", "60", "--quit-after", str(IMAGES_MAX),
                           "res://exemple/main.tscn"])
    marque = next((l.strip() for l in sortie.splitlines() if MARQUE in l), None)
    # `sorties_connues` : messages exacts que le moteur écrit dans le cas que l'exemple montre exprès (un fichier
    # abîmé…), expliqués dans un piège de la fiche ; « re: » pour une expression régulière.
    connues = entree.get("sorties_connues", [])
    return {"id": ident, "ok": reussi(code, sortie, connues), "etape": "exemple", "code": code, "marque": marque,
            "lignes": problemes(sortie, connues)[:20]}


def main(cat: Catalogue, argv: list[str] | None = None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parseur = argparse.ArgumentParser(prog=f"python -m usine.rag.{cat.nom}")
    sous = parseur.add_subparsers(dest="commande", required=True)
    p_v = sous.add_parser("verifier", help="lancer l'exemple de chaque entrée dans Godot, réécrire sa fiche s'il passe")
    p_v.add_argument("ids", nargs="*")
    args = parseur.parse_args(argv)
    entrees = manifeste(cat)
    ids = args.ids or sorted(entrees)
    inconnus = [i for i in ids if i not in entrees]
    if inconnus:
        parseur.error(f"entrées absentes de {cat.chemin_manifeste.name} : {', '.join(inconnus)}")
    sortie = cfg.dossier_donnees() / cat.nom / "verification.json"
    anciens = json.loads(sortie.read_text(encoding="utf-8")) if sortie.is_file() else []
    bilans = {b["id"]: b for b in anciens if b["id"] in entrees}
    reussis = 0
    for ident in ids:
        b = verifier(cat, ident, entrees[ident])
        bilans[ident] = b
        print(f"{ident} : {'ok' if b['ok'] else 'ÉCHEC à l’étape ' + b['etape']} {b.get('marque') or ''}")
        for ligne in b["lignes"]:
            print("    " + ligne)
        if b["ok"]:
            reussis += 1
            mesure = b["marque"].split(MARQUE, 1)[1].lstrip(" :")
            (cat.dossier / ident / "fiche.md").write_text(fiche(cat, ident, entrees[ident], mesure),
                                                          encoding="utf-8", newline="\n")
    sortie.parent.mkdir(parents=True, exist_ok=True)
    sortie.write_text(json.dumps([bilans[i] for i in sorted(bilans)], indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"{reussis}/{len(ids)} exemples vérifiés, leurs fiches réécrites ; bilan : {sortie}")
    return 0 if reussis == len(ids) else 1
