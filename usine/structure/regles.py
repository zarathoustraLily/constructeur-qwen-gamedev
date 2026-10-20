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
# Tableau des dossiers des règles d'architecture (« Peut dépendre de ») : dossier source → dossiers
# qu'il peut référencer. Le sien est toujours permis ; 7_tests voit tout ; personne ne voit 7_tests.
PERMIS: dict[str, set[str]] = {
    "0_autoload": {"1_core"},
    "1_core": set(),
    "2_sequence": {"0_autoload", "1_core", "3_entities", "4_ui", "5_data", "6_assets"},
    "3_entities": {"1_core", "5_data", "6_assets"},
    "4_ui": {"0_autoload", "1_core", "6_assets"},
    "5_data": {"1_core", "6_assets"},
    "6_assets": set(),
}
EXCEPTIONS: set[tuple[str, str]] = set()
SANS_CODE = {"5_data", "6_assets"}
# Décors procéduraux (CLAUDE.md, « Règles qui priment », section 5 ; demande de laurent du 2026-10-14) :
# les générateurs @tool et leurs scènes vivent dans 6_assets/Mesh/Procedural/, leurs données (palettes,
# listes, cotes : des scripts de constantes) dans 5_data/DECORS/. Ces zones admettent du code ; la valeur
# donne les dossiers qu'elles peuvent connaître en plus de ceux de leur dossier dans PERMIS.
DECORS: dict[str, set[str]] = {
    "6_assets/Mesh/Procedural/": {"1_core", "5_data"},
    "5_data/DECORS/": set(),
}


def zone_decor(res: str) -> str | None:
    """La zone de décor procédural d'un fichier (« 6_assets/Mesh/Procedural/ »…), ou None."""
    rel = res.removeprefix("res://")
    return next((zone for zone in DECORS if rel.startswith(zone)), None)


def code_permis(res: str) -> bool:
    """Un script peut-il vivre à cet endroit ? Partout dans le plan, sauf 5_data et 6_assets hors des décors."""
    return dossier_de(res) not in SANS_CODE or zone_decor(res) is not None


def dossiers_permis(res: str) -> set[str]:
    """Les dossiers qu'un fichier peut connaître, en plus du sien : son dossier, et sa zone de décor s'il en a une."""
    dossier = dossier_de(res)
    permis = set(PERMIS.get(dossier, set())) if dossier else set()
    zone = zone_decor(res)
    if zone is not None:
        permis |= DECORS[zone]
    return permis
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


def _erreur(fichier: str, regle: str, message: str, ligne: int | None = None) -> dict[str, Any]:
    """Erreur au format commun ; `regle` est l'identifiant de la règle d'architecture violée."""
    return {"fichier": fichier, "ligne": ligne, "categorie": "structure", "regle": regle,
            "message": f"{regle} : {message}"}


def entite_de(projet: Path, res: str) -> str | None:
    """Dossier de l'entité d'un fichier de 3_entities : `player`, `enemies/drone`… (None hors 3_entities).
    Une entité est le premier dossier qui contient une scène du même nom (player/player.tscn),
    sinon les deux premiers niveaux (catégorie/entité)."""
    parties = res.removeprefix("res://").split("/")
    if parties[0] != "3_entities" or len(parties) < 3:
        return None
    if (Path(projet) / "3_entities" / parties[1] / f"{parties[1]}.tscn").is_file() or len(parties) < 4:
        return parties[1]
    return "/".join(parties[1:3])


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
        erreurs.append(_erreur("res://", "ORG-01", "pas de plan numéroté (0_autoload … 7_tests) : la structure n'est pas jugée"))
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
                    erreurs.append(_erreur(res, "ORG-01", "fichier à la racine : il doit aller dans un des dossiers du plan"))
                continue
            if dossier is None:
                erreurs.append(_erreur(res, "ORG-01", f"dossier « {rel.parts[0]} » hors du plan d'organisation"))
                continue
            if f.suffix == ".gd" and not code_permis(res):
                erreurs.append(_erreur(res, "DOSSIERS", f"script dans {dossier} ({DOSSIERS[dossier]}) : ce dossier ne contient aucun code"
                                                        " (hors des décors procéduraux : 6_assets/Mesh/Procedural/, 5_data/DECORS/)"))
            if f.suffix in (".gd", ".tscn", ".tres", ".gdshader") and not _SNAKE.match(f.stem):
                erreurs.append(_erreur(res, "COD-01", f"nom de fichier hors convention : {f.name} (snake_case attendu)"))
            if f.suffix == ".gd":
                texte = nettoyer(lire_texte(f))
                m = _CLASS_NAME.search(texte)
                if m and snake(m.group(1)) != f.stem:
                    erreurs.append(_erreur(res, "COD-01", f"class_name {m.group(1)} dans {f.name} : le fichier doit "
                                                f"s'appeler {snake(m.group(1))}.gd", texte.count("\n", 0, m.start()) + 1))
                a = _ANCIEN_EXPORT.search(texte)
                if a:
                    erreurs.append(_erreur(res, "COD-04", "« export var » : écrire « @export var »", texte.count("\n", 0, a.start()) + 1))
            if dossier == "7_tests" and f.suffix == ".gd":
                teste = Path(*rel.parts[1:-1]) if len(rel.parts) > 2 else None
                if teste is None or teste.parts[0] not in DOSSIERS or not (projet / teste).is_dir():
                    erreurs.append(_erreur(res, "QA-01", "test hors miroir : 7_tests/<chemin du dossier testé>/test_<sujet>.gd, "
                                                         "le dossier testé doit exister"))
        for source, cibles in references(projet).items():
            dossier = dossier_de(source)
            if dossier is None or dossier == "7_tests":
                continue
            permis = dossiers_permis(source)
            vues: set[str] = set()
            for cible, ligne in cibles:
                d = dossier_de(cible)
                if d is None or cible in vues or (dossier, cible) in EXCEPTIONS:
                    continue
                if d == dossier:
                    a, b = entite_de(projet, source), entite_de(projet, cible)
                    if a and b and a != b:
                        vues.add(cible)
                        erreurs.append(_erreur(source, "DOSSIERS", f"l'entité {a} ne doit pas dépendre d'une autre entité "
                                                                   f"({b}) : le niveau lui fournit ce qu'il faut", ligne))
                    continue
                if d in permis:
                    continue
                vues.add(cible)
                erreurs.append(_erreur(source, "DOSSIERS", f"{dossier} ({DOSSIERS[dossier]}) ne doit pas connaître {cible} "
                                                           f"({DOSSIERS[d]}) ; permis : "
                                                           f"{', '.join(sorted(permis)) or 'aucun autre dossier'}", ligne))
    verdict["ok"] = not erreurs
    verdict["duree_s"] = round(time.monotonic() - debut, 3)
    return verdict
