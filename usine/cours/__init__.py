"""Cours en étapes : un projet Godot par étape, fabriqué à partir de fichiers maîtres balisés.

Un cours vit dans `cours/<nom>/` : ses maîtres (par ville), ses fichiers communs, ses notes d'étape et son
manifeste. `fabriquer.py` en tire un projet Godot complet par étape, dans `donnees/cours/<nom>/projets/`
(ignoré par git) : on corrige les maîtres, jamais les projets fabriqués (règle 5).

    python -m usine.cours fabriquer batiments_proceduraux [ville] [étape …]
    python -m usine.cours juger batiments_proceduraux
"""

from __future__ import annotations

from pathlib import Path

from usine import config as cfg

RACINE_COURS = cfg.RACINE / "cours"


def dossier_cours(nom: str) -> Path:
    """Le dossier source d'un cours (`cours/<nom>/`)."""
    chemin = RACINE_COURS / nom
    if not (chemin / "manifeste.py").is_file():
        raise ValueError(f"cours inconnu : {nom} (aucun {chemin / 'manifeste.py'})")
    return chemin


def dossier_projets(nom: str, config: dict | None = None) -> Path:
    """Où vont les projets fabriqués d'un cours : `donnees/cours/<nom>/projets/`."""
    return cfg.dossier_donnees(config) / "cours" / nom / "projets"
