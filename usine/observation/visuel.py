"""Observation visuelle (compétence O1, « corriger en observant », par l'image).

Un défaut qui ne se voit qu'à l'image (des fenêtres noires, un toit décalé, une face retournée, une teinte
fausse) passe la compilation et les tests : il se voit en regardant le rendu. Demande de laurent du
2026-10-20 : inclure la vérification visuelle et la correction ; Qwen regarde l'image elle-même.

  rendre      lance le projet avec le vrai rendu (Compatibilité, 960×540), une image par vue. La fenêtre
              est placée hors de l'écran : même image, octet pour octet, qu'une fenêtre visible (vérifié le
              2026-10-20 sur la machine de laurent), sans gêner son travail. Sous Linux sans écran, xvfb-run.
  comparer    gd/comparer_images.gd (Godot, aucune dépendance Python) : pixels qui changent, boîte
              englobante, grille, couleur avant et après.
  decrire     l'écart en mots : où (en haut à gauche…), combien (part de l'image), comment (plus sombre,
              plus clair, d'une autre couleur).

Vues : arguments de la scène principale du projet, après « -- ». Pour les étapes du cours « bâtiments
procéduraux », la scène principale est la visite (2_sequence/step_viewer) : --night, --sun=…, --cam=…
Seuls nos processus sont arrêtés (règle 8).
"""

from __future__ import annotations

import json
import os
import re
import shutil
import sys
from pathlib import Path
from typing import Any, Iterable

from usine import config as cfg
from usine.processus import executer

RACINE = Path(__file__).resolve().parent
SCRIPT_COMPARER = RACINE / "gd" / "comparer_images.gd"
MARQUEUR = "@@IMAGES@@"
RESOLUTION = "960x540"
POSITION_HORS_ECRAN = "-6000,-6000"
# Un pixel change quand une composante diffère de plus de SEUIL_PIXEL (sur 255). Un rendu est « identique »
# à la référence quand au plus PART_IDENTIQUE de ses pixels changent ; un défaut est « visible » quand une vue
# change sur au moins PART_VISIBLE de l'image.
SEUIL_PIXEL = 24
PART_IDENTIQUE = 0.001
PART_VISIBLE = 0.015

# Les vues de la visite du cours : de jour (cadrage automatique), de nuit (l'éclairage des pièces derrière les
# vitres), et sous un soleil rasant (le relief, les normales).
VUES_COURS: list[dict[str, Any]] = [
    {"nom": "jour", "args": []},
    {"nom": "nuit", "args": ["--night"]},
    {"nom": "soleil_rasant", "args": ["--sun=-12,60"]},
]

_BRUIT = re.compile(r"Failed to load cached shader|_load_from_cache|V-Sync|^\s*$")
_ERREUR = re.compile(r"SCRIPT ERROR|SHADER ERROR|^ERROR:|^\s*ERROR:")


class ErreurComparaison(RuntimeError):
    pass


def prefixe_ecran() -> tuple[list[str], dict[str, str]]:
    """(préfixe de commande, variables d'environnement) : xvfb-run sous Linux sans écran."""
    if sys.platform.startswith("linux") and not os.environ.get("DISPLAY") and shutil.which("xvfb-run"):
        return ["xvfb-run", "-a", "-s", "-screen 0 960x540x24"], {"LIBGL_ALWAYS_SOFTWARE": "1"}
    return [], {}


def erreurs_sortie(texte: str) -> list[str]:
    """Les lignes d'erreur d'une sortie de Godot, sans le bruit propre à la machine (règle 5.1), avec la
    ligne « at: » qui suit, qui fait foi pour un shader (règle 5.6)."""
    lignes = texte.splitlines()
    sortie: list[str] = []
    for k, l in enumerate(lignes):
        if _ERREUR.search(l) and not _BRUIT.search(l):
            sortie.append(l.strip())
            if k + 1 < len(lignes) and lignes[k + 1].strip().startswith("at:"):
                sortie.append(lignes[k + 1].strip())
    return sortie


def commande_rendu(godot: Path, projet: Path, png: Path, args: Iterable[str]) -> list[str | Path]:
    return [godot, "--path", projet, "--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3",
            "--audio-driver", "Dummy", "--resolution", RESOLUTION, "--position", POSITION_HORS_ECRAN,
            "--", f"--shot={Path(png).resolve()}", *args]


def rendre(projet: Path, vues: Iterable[dict[str, Any]], dossier: Path, godot: Path | None = None,
           delai_s: float = 180) -> dict[str, dict[str, Any]]:
    """Une image par vue dans `dossier` (<nom>.png). Renvoie {nom: {image (Path ou None), erreurs, code}}.
    Le projet doit être importé. Une vue dont le rendu affiche une erreur (shader qui ne compile pas, script
    qui plante) garde son image si elle existe, mais ses erreurs sont rapportées."""
    godot = Path(godot) if godot else cfg.chemin_godot()
    dossier = Path(dossier)
    dossier.mkdir(parents=True, exist_ok=True)
    prefixe, env = prefixe_ecran()
    resultat: dict[str, dict[str, Any]] = {}
    for vue in vues:
        png = dossier / f"{vue['nom']}.png"
        png.unlink(missing_ok=True)
        r = executer([*prefixe, *commande_rendu(godot, Path(projet), png, vue.get("args", []))],
                     delai_s=delai_s, env=env or None)
        erreurs = erreurs_sortie(r.sortie)
        if r.expire:
            erreurs.append(f"rendu interrompu au bout de {delai_s} s")
        resultat[vue["nom"]] = {"image": png if png.is_file() else None, "erreurs": erreurs, "code": r.code}
    return resultat


def comparer(a: Path, b: Path, projet: Path, seuil: int = SEUIL_PIXEL, godot: Path | None = None) -> dict[str, Any]:
    """Écart entre deux images de même taille (rapport de gd/comparer_images.gd). `projet` : un projet Godot
    importé quelconque, où lancer le script."""
    godot = Path(godot) if godot else cfg.chemin_godot()
    r = executer([godot, "--headless", "--path", projet, "-s", SCRIPT_COMPARER, "--",
                  f"a={Path(a).resolve()}", f"b={Path(b).resolve()}", f"seuil={seuil}"], delai_s=120)
    for ligne in r.sortie.splitlines():
        if ligne.startswith(MARQUEUR):
            rapport = json.loads(ligne[len(MARQUEUR):])
            if "erreur" in rapport:
                raise ErreurComparaison(rapport["erreur"])
            return rapport
    raise ErreurComparaison("comparaison sans réponse :\n" + "\n".join(r.sortie.splitlines()[-10:]))


def identique(c: dict[str, Any]) -> bool:
    return c["part"] <= PART_IDENTIQUE


def visible(c: dict[str, Any]) -> bool:
    return c["part"] >= PART_VISIBLE


def zone(boite: list[int], largeur: int, hauteur: int) -> str:
    """Où est la boîte dans l'image, en mots : « en haut à gauche », « au centre », « sur toute l'image »…"""
    if not boite:
        return "nulle part"
    x0, y0, x1, y1 = boite
    if (x1 - x0 + 1) >= 0.8 * largeur and (y1 - y0 + 1) >= 0.8 * hauteur:
        return "sur presque toute l'image"
    cx, cy = (x0 + x1) / 2 / largeur, (y0 + y1) / 2 / hauteur
    v = "en haut" if cy < 1 / 3 else ("en bas" if cy > 2 / 3 else "")
    h = "à gauche" if cx < 1 / 3 else ("à droite" if cx > 2 / 3 else "")
    if v and h:
        return f"{v} {h}"
    if v:
        return f"{v}, au centre"
    if h:
        return f"au milieu, {h}"
    return "au centre"


def _pourcent(part: float) -> str:
    p = part * 100
    return (f"{p:.1f}" if p < 10 else f"{p:.0f}").replace(".", ",") + " %"


def nuance(c: dict[str, Any]) -> str:
    """Comment la zone a changé : plus sombre, plus claire, ou d'une autre couleur."""
    if "lum_a" not in c:
        return "inchangée"
    dl = c["lum_b"] - c["lum_a"]
    if dl <= -20:
        return "plus sombre"
    if dl >= 20:
        return "plus claire"
    return "d'une autre couleur"


def decrire(c: dict[str, Any], vue: str) -> str:
    """L'écart d'une vue par rapport à la référence, en une phrase."""
    if identique(c):
        return f"vue « {vue} » : identique à la référence"
    return (f"vue « {vue} » : {_pourcent(c['part'])} de l'image diffère de la référence, "
            f"{zone(c['boite'], c['largeur'], c['hauteur'])} (zone {nuance(c)})")
