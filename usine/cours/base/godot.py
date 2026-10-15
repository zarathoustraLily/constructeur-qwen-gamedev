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

import hashlib
import json
import os
import re
import shutil
from contextlib import contextmanager
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
    texte: str          # la sortie nettoyée (règle 5.1), lue par le générateur
    code: int
    brut: str = ""      # la sortie entière, pour le format d'OpenCode (opencode.sortie_godot)


# Godot donne la même sortie pour le même projet : un projet matérialisé est repéré par l'empreinte de ses fichiers,
# et chaque commande déjà lancée sur cette empreinte rend sa sortie gardée (une étape essaie plusieurs découpages qui
# repassent par les mêmes états). Un projet qu'on modifie ensuite (sessions) est oublié : rien n'y est gardé.
# Le même état peut revenir sous un autre nom de dossier (la dernière partie s'appelle p2 ou p3 selon la découpe) :
# la sortie entière est gardée avec une marque à la place du chemin du projet, remise au chemin du nouveau dossier.
_EMPREINTES: dict[str, str] = {}
_IMPORTES: set[str] = set()
_GARDEES: dict[tuple[str, tuple[str, ...]], tuple[str, int, str]] = {}
_IMAGES: dict[tuple[str, tuple[str, ...]], Path] = {}
MARQUE = "\x00PROJET\x00"
# Estimation sans Godot (creation.exemples) : chaque genre de commande rend une sortie type, gardée avec la marque.
_SIMULATION: dict[str, tuple[str, int, str]] | None = None


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
    _EMPREINTES[str(cible)] = hashlib.sha256(json.dumps(sorted(fichiers.items())).encode("utf-8")).hexdigest()
    _IMPORTES.discard(str(cible))
    return str(cible)


def oublier(projet: str) -> None:
    """Le projet va être modifié hors de `materialiser` : ses sorties ne sont plus gardées."""
    _EMPREINTES.pop(str(projet), None)


def nettoyer(sortie: str, projet: str) -> str:
    """La sortie montrée : sans codes de couleur, lignes vides, lignes d'information ni avertissements dus à la
    machine ; le chemin du projet y devient relatif."""
    lignes = [COULEURS.sub("", l).rstrip() for l in sortie.splitlines()]
    lignes = [l for l in lignes if not BRUIT.search(l)]
    absolu = str(Path(projet).resolve())
    return "\n".join(lignes).replace(absolu + os.sep, "").replace(absolu + "/", "").replace(absolu, ".")


def genre(arguments: list[str]) -> str:
    """Le genre d'une commande : import, analyse, rendu ou test."""
    if "--import" in arguments:
        return "import"
    if "--check-only" in arguments:
        return "analyse"
    if "--rendering-method" in arguments:
        return "rendu"
    return "test"


def _avec_marque(res: tuple[str, int, str], projet: str) -> tuple[str, int, str]:
    texte, code, brut = res
    return texte, code, brut.replace(str(Path(projet).resolve()), MARQUE)


def _sans_marque(res: tuple[str, int, str], projet: str) -> tuple[str, int, str]:
    texte, code, brut = res
    return texte, code, brut.replace(MARQUE, str(Path(projet).resolve()))


@contextmanager
def simulation(types: dict[str, tuple[str, int, str]]):
    """Le temps du bloc, aucune commande ne lance Godot : chacune rend la sortie type de son genre (`types`, avec la
    marque à la place du chemin du projet). Sert à estimer la taille d'un exemple avant de lancer Godot."""
    global _SIMULATION
    _SIMULATION = types
    try:
        yield
    finally:
        _SIMULATION = None


def sortie_type(s: Sortie, projet: str) -> tuple[str, int, str]:
    """Une sortie réelle, prête à servir de sortie type (`simulation`)."""
    return _avec_marque((s.texte, s.code, s.brut), projet)


def _lancer(arguments: list[str], projet: str, delai: int = 300, prefixe: list[str] | None = None,
            env: dict[str, str] | None = None) -> tuple[str, int, str]:
    """(sortie nettoyée, code de sortie, sortie entière), gardée pour un projet matérialisé et non modifié."""
    projet = str(projet)
    if _SIMULATION is not None:
        return _sans_marque(_SIMULATION[genre(arguments)], projet)
    empreinte = _EMPREINTES.get(projet)
    cle = (empreinte, tuple(arguments)) if empreinte else None
    if cle in _GARDEES:
        return _sans_marque(_GARDEES[cle], projet)
    import_ = "--import" in arguments
    if empreinte and not import_ and projet not in _IMPORTES:
        # L'import a été rendu de mémoire : on le fait vraiment avant une commande qui en a besoin.
        _lancer_vraiment(["--headless", "--path", ".", "--import"], projet, 300, None, None)
        _IMPORTES.add(projet)
    res = _lancer_vraiment(arguments, projet, delai, prefixe, env)
    if import_:
        _IMPORTES.add(projet)
    if cle:
        _GARDEES[cle] = _avec_marque(res, projet)
    return res


def _lancer_vraiment(arguments: list[str], projet: str, delai: int, prefixe: list[str] | None,
                     env: dict[str, str] | None) -> tuple[str, int, str]:
    res = executer([*(prefixe or []), cfg.chemin_godot(), *arguments], cwd=Path(projet), delai_s=delai, env=env)
    texte = nettoyer(res.sortie, projet)
    if res.expire:
        return texte + f"\n[délai dépassé : {delai} s]", -1, res.sortie
    return texte, res.code if res.code is not None else -1, res.sortie


def commande(arguments: list[str]) -> str:
    """La commande telle que les exemples la montrent : celle qui a tourné (voir l'en-tête du module)."""
    return " ".join(["godot", *arguments])


def importer(projet: str) -> Sortie:
    arguments = ["--headless", "--path", ".", "--import"]
    texte, code, brut = _lancer(arguments, projet)
    return Sortie(commande(arguments), texte, code, brut)


def verifier_script(projet: str, res: str) -> Sortie:
    arguments = ["--headless", "--path", ".", "--check-only", "-s", res]
    texte, code, brut = _lancer(arguments, projet, 120)
    return Sortie(commande(arguments), texte, code, brut)


def tester(projet: str, res: str, delai: int = 90) -> Sortie:
    arguments = ["--headless", "--path", ".", "-s", res]
    texte, code, brut = _lancer(arguments, projet, delai)
    return Sortie(commande(arguments), texte, code, brut)


def rendre(projet: str, copie_png: Path | str | None = None, scene: str | None = None,
           resolution: str = "960x540") -> Sortie:
    """Une image en Compatibilité (OpenGL 3) : c'est là que les shaders se compilent (règle 5.4). La visite de l'étape
    rend l'image, l'enregistre dans `IMAGE_RENDU` et quitte (`--shot`) ; `--quit-after` borne le lancement si elle ne
    quittait pas. Les arguments de la visite suivent `++`, l'autre séparateur que donne la référence de
    `OS.get_cmdline_user_args` (« when -- is intercepted by another program ») : chez laurent, les commandes passent
    par PowerShell, dont le traitement de `--` n'a pas été vérifié. L'image est ensuite copiée dans `copie_png`,
    s'il est donné (preuve gardée hors du projet)."""
    prefixe, env = prefixe_ecran()
    image = Path(projet) / IMAGE_RENDU
    image.unlink(missing_ok=True)
    arguments = ["--path", ".", "--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3",
                 "--audio-driver", "Dummy", "--resolution", resolution, "--quit-after", "6000"]
    if scene:
        arguments.append(scene)
    arguments += ["++", f"--shot={IMAGE_RENDU}"]
    texte, code, brut = _lancer(arguments, projet, 180, prefixe, env)
    if copie_png is not None and _SIMULATION is None:
        copie = Path(copie_png)
        copie.parent.mkdir(parents=True, exist_ok=True)
        cle = (_EMPREINTES.get(str(projet)), tuple(arguments))
        if image.is_file():
            shutil.copyfile(image, copie)
            if cle[0]:
                _IMAGES[cle] = copie
        elif cle in _IMAGES and _IMAGES[cle] != copie and _IMAGES[cle].is_file():
            # Sortie gardée : l'image vient du premier rendu de ce même état.
            shutil.copyfile(_IMAGES[cle], copie)
    return Sortie(commande(arguments), texte, code, brut)


def image_enregistree(s: Sortie) -> tuple[int, int] | None:
    """(largeur, hauteur) de l'image si la visite a écrit « capture: … erreur=0 », sinon None."""
    m = CAPTURE.search(s.texte)
    return (int(m[2]), int(m[3])) if m and m[1] == IMAGE_RENDU and m[4] == "0" else None
