"""Règles de rangement et de dépendances entre dossiers numérotés."""

from __future__ import annotations

import re
import time
from pathlib import Path
from typing import Any

from usine.projet.index import Projet, lire_texte
from usine.retour.verification import IDENT, nettoyer
from usine.juge.verdict import nouveau_verdict

DOSSIERS = {
    "0_autoload": "le chef d'orchestre",
    "1_core": "le cœur",
    "2_sequence": "le déroulé",
    "3_entities": "les acteurs",
    "4_ui": "l'interface",
    "5_data": "les réglages",
    "6_assets": "la matière",
    "7_tests": "les tests",
}
# Dossier source → dossiers qu'il peut référencer (le sien est toujours permis ; 7_tests voit tout).
PERMIS: dict[str, set[str]] = {
    "0_autoload": {"1_core", "5_data", "6_assets"},
    "1_core": set(),
    "2_sequence": {"0_autoload", "1_core", "3_entities", "4_ui", "5_data", "6_assets"},
    "3_entities": {"0_autoload", "1_core", "5_data", "6_assets"},
    "4_ui": {"0_autoload", "1_core", "5_data", "6_assets"},
    "5_data": {"1_core", "3_entities", "6_assets"},
    "6_assets": set(),
}
# 0_autoload lit la séquence, et seulement elle : il ne connaît aucune étape en particulier.
EXCEPTIONS = {("0_autoload", "res://2_sequence/sequence.tres")}
SANS_CODE = {"5_data", "6_assets"}
FICHIERS_RACINE = {"project.godot", "ORGANISATION.md", "plan.md", "icon.svg", "README.md", "AGENTS.md",
                   "opencode.json", "default_bus_layout.tres", "export_presets.cfg"}
_RES = re.compile(r"res://[^\"'\s)\]]+")
_SNAKE = re.compile(r"^[a-z0-9_]+$")
_CLASS_NAME = re.compile(rf"^class_name\s+({IDENT})", re.M)
_ANCIEN_EXPORT = re.compile(r"^\s*export(?:\(|\s+var\b)", re.M)


def dossier_de(res: str) -> str | None:
    tete = res.removeprefix("res://").split("/", 1)[0]
    return tete if tete in DOSSIERS else None


def snake(nom: str) -> str:
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", "_", nom).lower()


def _erreur(fichier: str, message: str, ligne: int | None = None) -> dict[str, Any]:
    return {"fichier": fichier, "ligne": ligne, "categorie": "structure", "message": message}


def est_organise(projet: Path) -> bool:
    """Vrai si le projet suit le plan numéroté (au moins le cœur et les acteurs)."""
    return all((Path(projet) / d).is_dir() for d in ("1_core", "3_entities"))


def references(projet: Path) -> dict[str, list[tuple[str, int]]]:
    """Fichier res:// → [(fichier référencé, ligne)] : chemins écrits, class_name, autoloads."""
    projet = Path(projet)
    p = Projet(projet)
    autoloads = p.autoloads()
    fichiers = sorted(f for f in projet.rglob("*") if f.is_file() and f.suffix in (".gd", ".tscn", ".tres")
                      and f.relative_to(projet).parts[0] not in ("addons", ".godot"))
    classes: dict[str, str] = {}
    for f in fichiers:
        if f.suffix == ".gd":
            m = _CLASS_NAME.search(nettoyer(lire_texte(f)))
            if m:
                classes[m.group(1)] = "res://" + f.relative_to(projet).as_posix()
    noms = {**classes, **autoloads}
    motif_noms = re.compile(r"\b(" + "|".join(map(re.escape, sorted(noms, key=len, reverse=True))) + r")\b") if noms else None
    refs: dict[str, list[tuple[str, int]]] = {}
    for f in fichiers:
        res = "res://" + f.relative_to(projet).as_posix()
        texte = lire_texte(f)
        trouvees: list[tuple[str, int]] = []
        for n, ligne in enumerate(texte.splitlines(), 1):
            trouvees += [(r, n) for r in _RES.findall(ligne)]
        if f.suffix == ".gd" and motif_noms is not None:
            for n, ligne in enumerate(nettoyer(texte).splitlines(), 1):
                if ligne.lstrip().startswith("class_name"):
                    continue
                trouvees += [(noms[m], n) for m in motif_noms.findall(ligne)]
        refs[res] = [(r, n) for r, n in trouvees if r != res]
    return refs


def verifier_projet(projet: Path) -> dict[str, Any]:
    """Verdict au format commun (étape « structure »)."""
    debut = time.monotonic()
    projet = Path(projet)
    verdict = nouveau_verdict("structure", ok=True)
    erreurs: list[dict[str, Any]] = verdict["erreurs"]
    if not est_organise(projet):
        erreurs.append(_erreur("res://", "pas de plan numéroté (0_autoload … 7_tests) : la structure n'est pas jugée"))
    else:
        for f in sorted(projet.rglob("*")):
            rel = f.relative_to(projet)
            if not f.is_file() or rel.parts[0] in ("addons", ".godot") or rel.name.startswith(".") \
                    or f.suffix in (".import", ".uid"):
                continue
            res = "res://" + rel.as_posix()
            dossier = dossier_de(res)
            if len(rel.parts) == 1:
                if rel.name not in FICHIERS_RACINE:
                    erreurs.append(_erreur(res, "fichier à la racine : il doit aller dans un des dossiers du plan"))
                continue
            if dossier is None:
                erreurs.append(_erreur(res, f"dossier « {rel.parts[0]} » hors du plan d'organisation"))
                continue
            if f.suffix == ".gd" and dossier in SANS_CODE:
                erreurs.append(_erreur(res, f"script dans {dossier} ({DOSSIERS[dossier]}) : ce dossier ne contient aucun code"))
            if f.suffix in (".gd", ".tscn", ".tres", ".gdshader") and not _SNAKE.match(f.stem):
                erreurs.append(_erreur(res, f"nom de fichier hors convention : {f.name} (snake_case attendu)"))
            if f.suffix == ".gd":
                texte = nettoyer(lire_texte(f))
                m = _CLASS_NAME.search(texte)
                if m and snake(m.group(1)) != f.stem:
                    erreurs.append(_erreur(res, f"class_name {m.group(1)} dans {f.name} : le fichier doit s'appeler "
                                                f"{snake(m.group(1))}.gd", texte.count("\n", 0, m.start()) + 1))
                a = _ANCIEN_EXPORT.search(texte)
                if a:
                    erreurs.append(_erreur(res, "« export var » : écrire « @export var »", texte.count("\n", 0, a.start()) + 1))
            if dossier == "7_tests" and f.suffix == ".gd" and (len(rel.parts) < 3 or rel.parts[1] not in DOSSIERS):
                erreurs.append(_erreur(res, "test hors miroir : 7_tests/<dossier du plan>/test_<sujet>.gd"))
        for source, cibles in references(projet).items():
            dossier = dossier_de(source)
            if dossier is None or dossier == "7_tests":
                continue
            permis = PERMIS.get(dossier, set())
            vues: set[str] = set()
            for cible, ligne in cibles:
                d = dossier_de(cible)
                if d is None or d == dossier or d in permis or (dossier, cible) in EXCEPTIONS or cible in vues:
                    continue
                vues.add(cible)
                erreurs.append(_erreur(source, f"{dossier} ({DOSSIERS[dossier]}) ne doit pas connaître {cible} "
                                               f"({DOSSIERS[d]}) ; permis : {', '.join(sorted(permis)) or 'aucun autre dossier'}",
                                       ligne))
    verdict["ok"] = not erreurs
    verdict["duree_s"] = round(time.monotonic() - debut, 3)
    return verdict
