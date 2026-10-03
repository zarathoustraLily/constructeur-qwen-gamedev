"""Lecture de config.toml et résolution des chemins de la machine.

Ordre de résolution du binaire Godot :
1. `[godot].console` de config.toml, s'il est renseigné et existe ;
2. un binaire Godot déposé dans `godot_bin/` (session cloud, voir outils/installer_godot_cloud.sh).
"""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path
from typing import Any

RACINE = Path(__file__).resolve().parent.parent
FICHIER_CONFIG = RACINE / "config.toml"
DOSSIER_GODOT_BIN = RACINE / "godot_bin"
VERSION_GODOT_DEFAUT = "4.7.2"
A_RENSEIGNER = "A_RENSEIGNER"


class GodotIntrouvable(RuntimeError):
    """Aucun binaire Godot utilisable."""


def charger_config(chemin: Path | None = None) -> dict[str, Any]:
    """Charge config.toml ; renvoie un dictionnaire vide s'il n'existe pas."""
    chemin = Path(chemin) if chemin else FICHIER_CONFIG
    if not chemin.is_file():
        return {}
    with chemin.open("rb") as f:
        return tomllib.load(f)


def _valeur(config: dict[str, Any], section: str, cle: str) -> str | None:
    valeur = config.get(section, {}).get(cle)
    if not valeur or valeur == A_RENSEIGNER:
        return None
    return str(valeur)


def _chemin_machine(valeur: str) -> Path:
    chemin = Path(valeur).expanduser()
    return chemin if chemin.is_absolute() else RACINE / chemin


def version_godot(config: dict[str, Any] | None = None) -> str:
    config = charger_config() if config is None else config
    return _valeur(config, "godot", "version") or VERSION_GODOT_DEFAUT


def chemin_godot(config: dict[str, Any] | None = None) -> Path:
    """Binaire Godot console à utiliser en mode headless."""
    config = charger_config() if config is None else config
    valeur = _valeur(config, "godot", "console")
    if valeur:
        chemin = _chemin_machine(valeur)
        if chemin.is_file():
            return chemin
    if DOSSIER_GODOT_BIN.is_dir():
        motifs = ["Godot_v*_win64_console.exe"] if sys.platform == "win32" else ["Godot_v*_linux.x86_64"]
        for motif in motifs:
            candidats = sorted(DOSSIER_GODOT_BIN.glob(motif))
            if candidats:
                return candidats[-1]
    message = "Godot introuvable : renseigner [godot].console dans config.toml"
    if valeur:
        message += f" (le chemin configuré n'existe pas : {valeur})"
    raise GodotIntrouvable(message + " ou lancer outils/installer_godot_cloud.sh.")


def godot_disponible(config: dict[str, Any] | None = None) -> bool:
    try:
        chemin_godot(config)
    except GodotIntrouvable:
        return False
    return True


def dossier_donnees(config: dict[str, Any] | None = None) -> Path:
    config = charger_config() if config is None else config
    return _chemin_machine(_valeur(config, "chemins", "donnees") or "donnees")


def chemin_gdunit4(config: dict[str, Any] | None = None) -> Path:
    """Copie de l'addon GdUnit4 injectée dans les copies de travail qui n'en ont pas."""
    config = charger_config() if config is None else config
    valeur = _valeur(config, "juge", "gdunit4")
    return _chemin_machine(valeur) if valeur else RACINE / "godot" / "reference" / "addons" / "gdUnit4"


def delai_juge(config: dict[str, Any] | None = None) -> float:
    """Délai maximal (secondes) d'un appel à Godot par le juge."""
    config = charger_config() if config is None else config
    return float(config.get("juge", {}).get("delai_s", 300))
