"""Lancer Godot 4.7.2 sur un état de projet, et garder ses vraies sorties (règle 5.1).

Chaque commande tourne dans le dossier du projet (`--path .`). La commande montrée dans les exemples est celle qui a
tourné, arguments compris, à deux détails près : l'exécutable s'y appelle `godot`, et le préfixe propre à la machine
qui produit la base n'y figure pas (sous Linux sans écran, le rendu passe par `xvfb-run` et un rendu logiciel).
La sortie standard et la sortie d'erreur arrivent mêlées, dans l'ordre où Godot les écrit, sans leurs codes de
couleur. On n'en retire que les lignes vides, les lignes d'information (version, pilote, progression de l'import) et
deux avertissements dus à la machine (V-Sync d'un écran virtuel, cache de shaders à reconstruire). Seuls nos
processus sont arrêtés (règle 8).
"""

from __future__ import annotations

import os
import re
import shutil
from dataclasses import dataclass
from pathlib import Path

from usine import config as cfg
from usine.cours.base import chemins
from usine.cours.verifier import prefixe_ecran
from usine.processus import executer

COULEURS = re.compile(r"\x1b\[[0-9;]*m")
BRUIT = re.compile(r"^\s*$|^Godot Engine v|^OpenGL API|^Vulkan \d|V-Sync mode|gl_manager_x11|^Using present mode"
                   r"|Failed to load cached shader|_load_from_cache|^\[\s*\d+% \]|^\[ DONE \]")
# L'image du rendu : dans le dossier caché du projet, que Godot n'importe pas (aucun fichier ajouté à la racine).
IMAGE_RENDU = ".godot/rendu.png"
# La ligne que la visite écrit après avoir enregistré l'image (step_viewer.gd, _capture).
CAPTURE = re.compile(r"^capture: (\S+) \((\d+), (\d+)\) erreur=(\d+)$", re.M)


@dataclass
class Sortie:
    commande: str
    texte: str
    code: int


def materialiser(fichiers: dict[str, str], nom: str) -> str:
    """Écrit un projet complet à partir de ses fichiers texte (les projets du cours n'ont aucun fichier binaire)."""
    cible = chemins.actuels().travail / nom
    shutil.rmtree(cible, ignore_errors=True)
    cible.mkdir(parents=True)
    for rel, texte in fichiers.items():
        chemin = cible / rel
        chemin.parent.mkdir(parents=True, exist_ok=True)
        with open(chemin, "w", encoding="utf-8", newline="") as h:
            h.write(texte)
    return str(cible)


def nettoyer(sortie: str, projet: str) -> str:
    """La sortie montrée : sans codes de couleur, lignes vides, lignes d'information ni avertissements dus à la
    machine ; le chemin du projet y devient relatif."""
    lignes = [COULEURS.sub("", l).rstrip() for l in sortie.splitlines()]
    lignes = [l for l in lignes if not BRUIT.search(l)]
    absolu = str(Path(projet).resolve())
    return "\n".join(lignes).replace(absolu + os.sep, "").replace(absolu + "/", "").replace(absolu, ".")


def _lancer(arguments: list[str], projet: str, delai: int = 300, prefixe: list[str] | None = None,
            env: dict[str, str] | None = None) -> tuple[str, int]:
    res = executer([*(prefixe or []), cfg.chemin_godot(), *arguments], cwd=Path(projet), delai_s=delai, env=env)
    texte = nettoyer(res.sortie, projet)
    if res.expire:
        return texte + f"\n[délai dépassé : {delai} s]", -1
    return texte, res.code if res.code is not None else -1


def commande(arguments: list[str]) -> str:
    """La commande telle que les exemples la montrent : celle qui a tourné (voir l'en-tête du module)."""
    return " ".join(["godot", *arguments])


def importer(projet: str) -> Sortie:
    arguments = ["--headless", "--path", ".", "--import"]
    texte, code = _lancer(arguments, projet)
    return Sortie(commande(arguments), texte, code)


def verifier_script(projet: str, res: str) -> Sortie:
    arguments = ["--headless", "--path", ".", "--check-only", "-s", res]
    texte, code = _lancer(arguments, projet, 120)
    return Sortie(commande(arguments), texte, code)


def tester(projet: str, res: str, delai: int = 90) -> Sortie:
    arguments = ["--headless", "--path", ".", "-s", res]
    texte, code = _lancer(arguments, projet, delai)
    return Sortie(commande(arguments), texte, code)


def rendre(projet: str, copie_png: Path | str | None = None, scene: str | None = None,
           resolution: str = "960x540") -> Sortie:
    """Une image en Compatibilité (OpenGL 3) : c'est là que les shaders se compilent (règle 5.4). La visite de l'étape
    rend l'image, l'enregistre dans `IMAGE_RENDU` et quitte (`--shot`) ; `--quit-after` borne le lancement si elle ne
    quittait pas. L'image est ensuite copiée dans `copie_png`, s'il est donné (preuve gardée hors du projet)."""
    prefixe, env = prefixe_ecran()
    image = Path(projet) / IMAGE_RENDU
    image.unlink(missing_ok=True)
    arguments = ["--path", ".", "--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3",
                 "--audio-driver", "Dummy", "--resolution", resolution, "--quit-after", "6000"]
    if scene:
        arguments.append(scene)
    arguments += ["--", f"--shot={IMAGE_RENDU}"]
    texte, code = _lancer(arguments, projet, 180, prefixe, env)
    if copie_png is not None and image.is_file():
        copie = Path(copie_png)
        copie.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(image, copie)
    return Sortie(commande(arguments), texte, code)


def image_enregistree(s: Sortie) -> tuple[int, int] | None:
    """(largeur, hauteur) de l'image si la visite a écrit « capture: … erreur=0 », sinon None."""
    m = CAPTURE.search(s.texte)
    return (int(m[2]), int(m[3])) if m and m[1] == IMAGE_RENDU and m[4] == "0" else None
