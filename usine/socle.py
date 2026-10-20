"""Socle d'un projet source : ses fichiers non textuels (sons, images, modèles 3D, .import).

Une tâche ne recopie pas ces fichiers dans depart/ (plusieurs Mo par tâche, des centaines de
tâches). Son départ porte à la place un fichier `.usine_socle` à la racine, qui nomme le socle :
« <source>-<12 premiers caractères de l'empreinte> ». Le socle vit dans donnees/socles/<nom>/ ;
il se reconstruit à l'identique depuis godot/<source>/ (même empreinte), sur n'importe quelle
machine.

Toute copie de travail passe par `usine.juge.projet.preparer_copie`, qui étend le marqueur :
les fichiers du socle sont posés sous le projet, sans jamais remplacer un fichier du projet.
Le marqueur fait partie du départ : il entre dans l'empreinte de la tâche et dans la clé du
cache des verdicts, et un socle dont le contenu ne correspond plus à son nom est refusé.

Un projet sans fichier binaire (godot/reference) n'a pas de socle : ses tâches restent
identiques à celles de la session 3.
"""

from __future__ import annotations

import hashlib
import os
import shutil
import tempfile
from pathlib import Path

from usine import config as cfg

MARQUEUR = ".usine_socle"
# Fichiers recopiés dans chaque tâche (lisibles et modifiables par l'agent).
EXTENSIONS_TEXTE = {".gd", ".tscn", ".tres", ".godot", ".json", ".txt", ".md", ".cfg", ".gdshader"}
# Jamais copiés : caches du moteur et des outils.
EXCLUS = {".godot", "reports", "__pycache__", ".import", ".usine_rapports"}
# Extensions tierces que le juge injecte lui-même (usine/juge/projet.py) : jamais copiées. Les autres
# (un personnage, un outil d'éditeur) font partie du jeu et suivent le projet.
ADDONS_INJECTES = {"gdUnit4"}


def est_texte(chemin: Path | str) -> bool:
    return Path(chemin).suffix in EXTENSIONS_TEXTE


def dossiers_ignores(source: Path) -> set[Path]:
    """Dossiers que Godot ignore (un fichier .gdignore à leur racine), relatifs à `source`."""
    source = Path(source)
    return {g.parent.relative_to(source) for g in source.rglob(".gdignore")}


def exclu(rel: Path, ignores: set[Path] | frozenset = frozenset()) -> bool:
    """Caches, extensions injectées par le juge et dossiers ignorés par Godot : hors des tâches."""
    parts = Path(rel).parts
    if EXCLUS & set(parts):
        return True
    if len(parts) > 1 and parts[0] == "addons" and parts[1] in ADDONS_INJECTES:
        return True
    return any(parent in ignores for parent in Path(rel).parents)


def fichiers_socle(source: Path) -> list[Path]:
    """Fichiers non textuels du projet source, hors caches, GdUnit4 et dossiers ignorés, triés."""
    source = Path(source)
    ignores = dossiers_ignores(source)
    resultat = []
    # Tri par composants relatifs, sensible à la casse : même ordre sous Linux et Windows.
    for f in sorted(source.rglob("*"), key=lambda p: p.relative_to(source).parts):
        if not f.is_file():
            continue
        rel = f.relative_to(source)
        if exclu(rel, ignores) or est_texte(f) or f.suffix == ".uid" or rel.as_posix() == MARQUEUR:
            continue
        resultat.append(f)
    return resultat


def empreinte(racine: Path, fichiers: list[Path]) -> str:
    h = hashlib.sha256()
    for f in fichiers:
        h.update(f"{f.relative_to(racine).as_posix()}\n".encode("utf-8"))
        h.update(hashlib.sha256(f.read_bytes()).hexdigest().encode("ascii"))
    return h.hexdigest()


def nom_socle(source: Path, nom: str | None = None) -> str | None:
    """Nom du socle de `source`, ou None si le projet n'a aucun fichier non textuel.
    `nom` : nom de la source (par défaut, celui de son dossier, comme godot/<source>/)."""
    fichiers = fichiers_socle(source)
    if not fichiers:
        return None
    return f"{nom or Path(source).name}-{empreinte(Path(source), fichiers)[:12]}"


def dossier_socles() -> Path:
    return cfg.dossier_donnees() / "socles"


def construire(source: Path, nom_source: str | None = None) -> str | None:
    """Écrit donnees/socles/<nom>/ depuis `source` (une seule fois) et renvoie le nom."""
    source = Path(source)
    nom = nom_socle(source, nom_source)
    if nom is None:
        return None
    cible = dossier_socles() / nom
    if cible.is_dir():
        return nom
    dossier_socles().mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix=f".{nom}_", dir=dossier_socles()))
    for f in fichiers_socle(source):
        dest = tmp / f.relative_to(source)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, dest)
    try:
        os.replace(tmp, cible)
    except OSError:  # construit en parallèle par un autre processus
        shutil.rmtree(tmp, ignore_errors=True)
    return nom


def chemin(nom: str) -> Path:
    """Dossier du socle `nom`, reconstruit depuis godot/<source>/ s'il manque ; empreinte vérifiée."""
    cible = dossier_socles() / nom
    if not cible.is_dir():
        base = nom.rsplit("-", 1)[0]
        source = cfg.chemin_source(base) or cfg.RACINE / "godot" / base
        if source.is_dir() and nom_socle(source, base) == nom:
            construire(source, base)
    if not cible.is_dir():
        raise FileNotFoundError(f"socle {nom} introuvable (ni dans {dossier_socles()}, ni reconstructible "
                                "depuis godot/)")
    fichiers = sorted((f for f in cible.rglob("*") if f.is_file()), key=lambda f: f.relative_to(cible).parts)
    if f"{nom.rsplit('-', 1)[0]}-{empreinte(cible, fichiers)[:12]}" != nom:
        raise ValueError(f"socle {nom} : contenu modifié (empreinte différente)")
    return cible


def etendre(projet: Path) -> None:
    """Si `projet` porte un marqueur, y pose les fichiers du socle (sans rien remplacer)."""
    projet = Path(projet)
    marqueur = projet / MARQUEUR
    if not marqueur.is_file():
        return
    socle = chemin(marqueur.read_text(encoding="utf-8").strip())
    for f in sorted(socle.rglob("*"), key=lambda p: p.relative_to(socle).parts):
        if not f.is_file():
            continue
        dest = projet / f.relative_to(socle)
        if dest.exists():
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, dest)
