"""Famille de paires « regarder un fluide » : des séquences de 5 images, chacune avec son instant (décision 19, points 3, 5 et 6 ; demande de
laurent du 2026-11-01 : « fait un maximum de paires sur le sujet que qwen apprennen a code des fluide sous godot »).

Sans fenêtre ni carte : `cours/fluides/outils/voir_fluide.gd` joue les solveurs sur le processeur, enregistre 12 images par scène et rend
ce qu'elles montrent en chiffres. Rien n'est écrit à la main : le code d'une scène est le texte qui a tourné, et chaque chiffre d'une
réponse vient de la mesure de cette image. Six genres : fumée et feu (`FluidSolver`), vagues (`WaveSolver`), crue (`FloodSolver`), eau en
particules (`FlipSolver`, `SphSolver`).

Pour 40/40/20, en jetons de réponse :
- création : les images voulues → le `build()` et le `feed()` qui les donnent, ceux qui ont tourné ;
- débogage : une seule faute posée dans un solveur (mêmes règles que `faute_calcul`), gardée si elle se voit : un écart franc avec la scène
  saine, jugé par les mesures. La réponse ne cite que ce que montrent les images fautives : la scène saine ne sert qu'à décider ;
- analyse : reconnaître, comparer deux instants, dire si c'est normal, lire la séquence, ou dire si ces 5 images montrent ce qu'on cherche
  et quelles images prendre ensuite. Le prochain essai se déduit des images, et il n'est gardé que s'il encadre le vrai instant.

Deux paliers, les mêmes images : au palier 2, 5 images avec le plan (554 jetons + 1 100 d'images : environ 370 jetons de texte, 2 040 au plus) ;
au palier 1, une ou deux images sans le plan (1 024 au plus), les quatre niveaux de la décision 19.3. C'est au palier 1 que la création manque
et au palier 2 que le débogage et l'analyse manquent : le partage des scènes et des fautes suit ce besoin.

    python -m usine.paires voir_fluide [--scenes N] [--fautes N] [--graine G] [--genres gaz,feu,vagues,crue,flip,sph]
"""

from __future__ import annotations

import json
import math
import random
import shutil
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Callable

from usine import config as cfg
from usine.paires import faute_calcul
from usine.paires import format as fmt

FAMILLE = "voir_fluide"
PLAFOND, PLAFOND_COURT = 2040, 1024
OUTIL =cfg.RACINE / "cours" / "fluides" / "outils" / "voir_fluide.gd"
GENRES = ("gaz", "feu", "vagues", "crue", "flip", "sph")
ETAPE = 27
IMAGES = 12
TOUS_LES = 5
DELAI_SCENE = 60
LARGEUR_IMAGE = 640
SOLVEUR = "1_core/fluid/"
SUJET = "physique"          # le partage 40/40/20 se fait par sujet : au palier 2, c'est celui où ces trois types se complètent
NOMS = {"gaz": "la fumée", "feu": "le feu", "vagues": "l'onde", "crue": "l'eau", "flip": "l'eau", "sph": "le liquide"}
PRONOMS = {"gaz": "Elle", "feu": "Il", "vagues": "Elle", "crue": "Elle", "flip": "Elle", "sph": "Il"}
CLASSES = {"gaz": "FluidSolver", "feu": "FluidSolver", "vagues": "WaveSolver", "crue": "FloodSolver", "flip": "FlipSolver", "sph": "SphSolver"}
_POINTS = "De l'eau en particules, vue de côté dans une cuve : chaque point est une particule, plus clair quand elle va vite."
NATURES = {"gaz": "De la fumée : une simulation de fluide sur une grille, où la clarté donne la densité.",
           "feu": "Du feu : une simulation de fluide sur une grille, où la couleur donne la température.",
           "vagues": "Une surface d'eau vue de dessus : le clair montre les crêtes, le sombre les creux.",
           "crue": "De l'eau vue de dessus sur un terrain : le bleu est l'eau, le brun clair le sol qui monte.",
           "flip": _POINTS, "sph": _POINTS}
FICHIERS = {"gaz": ("fluid_solver", "advection", "fluid_projection", "obstacle_mask", "fluid_field", "vorticity"),
            "feu": ("fluid_solver", "combustion", "advection", "fluid_projection", "obstacle_mask", "fluid_field"),
            "vagues": ("wave_solver",), "crue": ("flood_solver",), "flip": ("flip_solver", "staggered_grid"),
            "sph": ("sph_solver", "sph_kernels")}
POUSSEES = ((0, -60), (0, -40), (0, -80), (30, -50), (-30, -50), (60, 0), (-60, 0))
# Écarts francs entre les images saines et les fautives, à la dernière image : en dessous, la faute ne se voit pas.
MOUVEMENT_MIN = 3.0
TROP_LENT, TROP_VITE = 0.35, 2.2
ECART_CENTRE = 0.2
ECART_FRONT = 0.2
AIRE_PETITE, AIRE_GRANDE = 0.45, 2.2
PIC_BAS, PIC_HAUT = 0.35, 2.8
TOT = 2                     # l'image où un anneau n'a pas encore touché les bords
LARGEUR_PETITE, LARGEUR_GRANDE = 0.6, 1.5
FENETRES_LARGES = ([0, 2, 4, 6, 8], [0, 3, 6, 9, 11], [0, 1, 3, 6, 10], [0, 2, 5, 8, 11])
IMAGES_FAUTE = [0, 3, 6, 9, 11]
ECART_DEUX = 3


@dataclass
class Scene:
    nom: str
    genre: str
    code: str                       # `build()` et `feed()`, le texte qui tourne
    delta: float
    couleurs: int
    clair: float
    largeur: int
    hauteur: int
    depart: tuple[int, int]         # où ça commence, en cases
    decor: str                      # ce que montrent les images, en mots
    attendu: str                    # ce que la scène doit faire
    reglages: str                   # ce que les images ne disent pas
    cible: tuple[str, str, float, int]    # (ce qu'on attend, bord mesuré, valeur, sens)
    fichiers: tuple[str, ...]
    mur: tuple[int, int, int, int] | None = None
    mortes: tuple[str, ...] = ()    # les fonctions que cette scène n'appelle pas : une faute y serait invisible
    repere: str = ""                # ce qui ne bouge pas dans l'image, en mots

    def instants(self) -> list[float]:
        return [(pas + 1) * self.delta for pas in self.pas()]

    def pas(self) -> list[int]:
        """La première image dès le premier pas : c'est elle qui montre la scène de départ."""
        return [TOUS_LES * i for i in range(IMAGES)]

    def pour_godot(self) -> dict[str, Any]:
        return {"nom": self.nom, "genre": self.genre, "code": self.code, "delta": self.delta, "images": self.pas(),
                "couleurs": self.couleurs, "clair": self.clair}


# ------------------------------------------------------------------ les scènes

def _x(valeur: float) -> str:
    """Un nombre comme GDScript l'écrit, toujours à virgule."""
    return repr(round(float(valeur), 3))


def _s(secondes: float) -> str:
    return f"{secondes:.2f} s".replace(".", ",")


def _n(valeur: float, chiffres: int = 1) -> str:
    return f"{valeur:.{chiffres}f}".replace(".", ",")


def _pas(delta: float) -> str:
    return f"1/{round(1 / delta)} s"


def panache(rng: random.Random, nom: str, feu: bool) -> Scene:
    """Une fumée poussée, ou un feu qui monte par sa chaleur ; un mur en travers, le plus souvent."""
    largeur, hauteur = 64, 36
    x, y = rng.randrange(14, 50), rng.randrange(29, 33) if feu else rng.randrange(20, 31)
    rayon = rng.choice((4.0, 5.0, 6.0) if feu else (3.0, 4.0, 5.0))
    fx, fy = (0, -1) if feu else rng.choice(POUSSEES)
    passes, perte, tourbillons = 12, rng.choice((0.1, 0.25, 0.5)), rng.choice((0.0, 4.0, 8.0))
    delta = rng.choice((1 / 30, 1 / 20))
    nette = rng.random() < 0.3
    lignes = ["func build() -> FluidSolver:", "\tvar settings: FluidSettings = FluidSettings.new()", f"\tsettings.width = {largeur}",
              f"\tsettings.height = {hauteur}", f"\tsettings.iterations = {passes}"]
    reglages = [f"{passes} passes de pression", "transport de MacCormack" if nette else "transport simple"]
    mortes = ("total", "peak", "fill", "copy_from") + (() if nette else ("mac_cormack",))
    mortes += ("burn", "lift", "cool", "_step_fire", "_transport_fire", "_carried") if not feu else ()
    mortes += ("curl", "confine") if tourbillons == 0.0 else ()
    if not nette:
        lignes.append("\tsettings.sharp_transport = false")
    if perte != 0.1:
        lignes.append(f"\tsettings.dissipation = {perte}")
        reglages.append(f"perte de {_n(perte, 2)} par seconde")
    if tourbillons != 4.0:
        lignes.append(f"\tsettings.vortex_strength = {tourbillons}")
        reglages.append(f"confinement à {_n(tourbillons, 0)}")
    lignes.append("\tvar solver: FluidSolver = FluidSolver.new(settings)")
    mur = None
    if rng.random() < 0.7:
        ecart, demi = rng.randrange(10, 15), rng.randrange(6, 11)
        if abs(fx) > abs(fy):
            colonne = x + (ecart if fx > 0 else -ecart)
            mur = (colonne, y - demi, colonne + 1, min(y + demi, hauteur - 2))
        else:
            rangee = y - ecart
            mur = (x - demi, rangee - 1, x + demi, rangee)
        if mur[0] < 2 or mur[1] < 2 or mur[2] > largeur - 3:
            mur = None
    if mur:
        lignes.append(f"\tsolver.walls.add_box({mur[0]}, {mur[1]}, {mur[2]}, {mur[3]})")
    if feu:
        pousse, froid = rng.choice((25.0, 40.0, 60.0)), rng.choice((0.8, 1.5, 2.5))
        lignes += ["\tsolver.fire = FireSettings.new()", "\tsolver.fire.ignition = 0.25", f"\tsolver.fire.buoyancy = {pousse}",
                   f"\tsolver.fire.cooling = {froid}"]
        reglages += [f"poussée de {_n(pousse, 0)}", f"refroidissement de {_n(froid)}"]
    lignes += ["\treturn solver", "", "", "func feed(solver: FluidSolver, delta: float) -> void:"]
    centre = f"{_x(x)}, {_x(y)}, {_x(rayon)}"
    if feu:
        lignes += [f"\tsolver.fuel.add_disc({centre}, 8.0 * delta)", f"\tsolver.temperature.add_disc({centre}, 3.0 * delta)"]
    else:
        lignes += [f"\tsolver.density.add_disc({centre}, 6.0 * delta)", f"\tsolver.add_force({centre}, {_x(fx)} * delta, {_x(fy)} * delta)"]
    sens = "le haut" if abs(fy) >= abs(fx) else "la droite" if fx > 0 else "la gauche"
    if mur and abs(fx) > abs(fy):
        cible = ("le mur", "droite", mur[0] - 1, 1) if fx > 0 else ("le mur", "gauche", mur[2] + 2, -1)
    elif mur:
        cible = ("le mur", "haut", mur[3] + 2, -1)
    elif abs(fy) >= abs(fx):
        cible = ("le haut de la grille", "haut", 2, -1)
    else:
        cible = ("le bord droit", "droite", largeur - 2, 1) if fx > 0 else ("le bord gauche", "gauche", 2, -1)
    decor = (f"un feu en ({x}, {y}), qui monte par sa chaleur" if feu else f"une fumée naît en ({x}, {y}), poussée vers {sens}")
    if mur:
        decor += f" ; un mur va de ({mur[0]}, {mur[1]}) à ({mur[2]}, {mur[3]})"
    genre = "feu" if feu else "gaz"
    return Scene(nom, genre, "\n".join(lignes) + "\n", delta, 1 if feu else rng.choice((0, 2)), 2.0 if feu else 1.0, largeur, hauteur, (x, y), decor,
                 f"monter depuis ({x}, {y})" if feu else f"aller vers {sens} depuis ({x}, {y})", ", ".join(reglages), cible, FICHIERS[genre], mur, mortes,
                 f"Le trait gris est un mur, de ({mur[0]}, {mur[1]}) à ({mur[2]}, {mur[3]})." if mur else "")


def vagues(rng: random.Random, nom: str) -> Scene:
    """Une goutte dans un bassin : un anneau s'élargit, touche les bords et repart."""
    largeur, hauteur = 64, 36
    x, y = rng.randrange(14, 50), rng.randrange(10, 26)
    rayon, hauteur_goutte = rng.choice((3.0, 4.0, 5.0)), rng.choice((0.6, 1.0, 1.5))
    vitesse, amorti = rng.choice((20.0, 30.0, 45.0, 60.0)), rng.choice((0.99, 0.995, 0.999))
    delta = rng.choice((1 / 30, 1 / 60))
    code = (f"func build() -> WaveSolver:\n\tvar settings: WaveSettings = WaveSettings.new()\n\tsettings.width = {largeur}\n"
            f"\tsettings.height = {hauteur}\n\tsettings.speed = {vitesse}\n\tsettings.damping = {amorti}\n"
            f"\tvar solver: WaveSolver = WaveSolver.new(settings)\n\tsolver.drop({_x(x)}, {_x(y)}, {_x(rayon)}, {hauteur_goutte})\n\treturn solver\n")
    bord = min((x, "gauche", 1, -1), (largeur - x, "droite", largeur - 1, 1), (y, "haut", 1, -1), (hauteur - y, "bas", hauteur - 1, 1))
    return Scene(nom, "vagues", code, delta, 2, 0.3, largeur, hauteur, (x, y), f"une goutte en ({x}, {y}), de rayon {_n(rayon, 0)}",
                 f"s'élargir en anneau depuis ({x}, {y}), puis repartir des bords", f"vitesse de {_n(vitesse, 0)} cases par seconde, amorti de {amorti}, hauteur {hauteur_goutte}".replace(".", ","),
                 ("le bord le plus proche", bord[1], bord[2], bord[3]), FICHIERS["vagues"])


def crue(rng: random.Random, nom: str) -> Scene:
    """De l'eau posée sur un sol, et une colline sur son chemin."""
    largeur, hauteur = 64, 36
    gauche = rng.random() < 0.5
    x, y = (rng.randrange(10, 18) if gauche else rng.randrange(46, 54)), rng.randrange(12, 24)
    colline_x, colline_y = (rng.randrange(36, 46) if gauche else rng.randrange(18, 28)), rng.randrange(10, 26)
    rayon, haut = rng.choice((8.0, 10.0, 12.0)), rng.choice((1.0, 1.5, 2.0))
    eau, volume = rng.choice((6.0, 8.0, 10.0)), rng.choice((1.0, 1.5, 2.0))
    pousse, frein = rng.choice((60.0, 100.0)), rng.choice((0.98, 0.99))
    code = (f"func build() -> FloodSolver:\n\tvar settings: FloodSettings = FloodSettings.new()\n\tsettings.width = {largeur}\n"
            f"\tsettings.height = {hauteur}\n\tsettings.pull = {pousse}\n\tsettings.friction = {frein}\n"
            f"\tvar ground: FluidField = FluidField.new({largeur}, {hauteur})\n"
            f"\tground.add_disc({_x(colline_x)}, {_x(colline_y)}, {_x(rayon)}, {haut})\n"
            f"\tvar solver: FloodSolver = FloodSolver.new(settings, ground)\n"
            f"\tsolver.add_water({_x(x)}, {_x(y)}, {_x(eau)}, {volume})\n\treturn solver\n")
    bord = (f"la colline", "droite", colline_x - rayon * 0.7, 1) if gauche else ("la colline", "gauche", colline_x + rayon * 0.7, -1)
    return Scene(nom, "crue", code, 1 / 30, 0, volume, largeur, hauteur, (x, y),
                 f"l'eau part de ({x}, {y}), rayon {_n(eau, 0)} ; une colline en ({colline_x}, {colline_y}), rayon {_n(rayon, 0)}",
                 f"s'étaler depuis ({x}, {y}) et contourner la colline", f"tirage de {_n(pousse, 0)}, frein de {_n(frein, 2)}, colline de hauteur {_n(haut)}, eau de hauteur {_n(volume)}",
                 bord, FICHIERS["crue"], repere=f"La tache claire en ({colline_x}, {colline_y}) est une colline.")


def particules(rng: random.Random, nom: str, genre: str) -> Scene:
    """Un bloc d'eau qui s'effondre dans une cuve (barrage rompu), ou qui tombe du haut."""
    flip = genre == "flip"
    largeur, hauteur = (40, 22) if flip else (32, 18)
    forme = rng.choice(("gauche", "droite", "chute"))
    l, h = rng.randrange(8, 15), rng.randrange(8, 15)
    if forme == "gauche":
        un, deux = (1, hauteur - h - 2), (1 + l, hauteur - 2)
        attendu, cible = "s'effondrer vers la droite", ("la paroi droite", "droite", largeur - 1.5, 1)
    elif forme == "droite":
        un, deux = (largeur - l - 2, hauteur - h - 2), (largeur - 2, hauteur - 2)
        attendu, cible = "s'effondrer vers la gauche", ("la paroi gauche", "gauche", 1.0, -1)
    else:
        x = rng.randrange(6, largeur - l - 6)
        un, deux = (x, 1), (x + l, 1 + min(h, 6))
        attendu, cible = "tomber et s'étaler sur le fond", ("le fond", "bas", hauteur - 1.5, 1)
    gravite = rng.choice((30.0, 60.0, 120.0) if flip else (10.0, 20.0, 40.0))
    premier, dernier = f"Vector2({_x(un[0])}, {_x(un[1])})", f"Vector2({_x(deux[0])}, {_x(deux[1])})"
    delta = rng.choice((1 / 30, 1 / 60))
    if flip:
        melange = rng.choice((0.8, 0.95))
        code = (f"func build() -> FlipSolver:\n\tvar settings: FlipSettings = FlipSettings.new()\n\tsettings.width = {largeur}\n"
                f"\tsettings.height = {hauteur}\n\tsettings.iterations = 16\n\tsettings.gravity = {gravite}\n\tsettings.flip_ratio = {melange}\n"
                f"\tvar solver: FlipSolver = FlipSolver.new(settings)\n\tsolver.add_block({premier}, {dernier}, 0.5)\n\treturn solver\n")
        reglages = f"gravité de {_n(gravite, 0)}, 16 passes, FLIP à {_n(melange, 2)}, une particule toutes les 0,5 case"
    else:
        raideur = rng.choice((40.0, 60.0, 90.0))
        code = (f"func build() -> SphSolver:\n\tvar settings: SphSettings = SphSettings.new()\n\tsettings.width = {_x(largeur)}\n"
                f"\tsettings.height = {_x(hauteur)}\n\tsettings.gravity = {gravite}\n\tsettings.stiffness = {raideur}\n"
                f"\tvar solver: SphSolver = SphSolver.new(settings)\n\tsolver.add_block({premier}, {dernier})\n\treturn solver\n")
        reglages = f"gravité de {_n(gravite, 0)}, raideur de {_n(raideur, 0)}"
    return Scene(nom, genre, code, delta, 0, 40.0 if flip else 20.0, largeur, hauteur, un,
                 f"un bloc d'eau de ({un[0]}, {un[1]}) à ({deux[0]}, {deux[1]}), au repos à la première image", attendu, reglages, cible, FICHIERS[genre])


def scene(genre: str, rng: random.Random, nom: str) -> Scene:
    if genre in ("gaz", "feu"):
        return panache(rng, nom, genre == "feu")
    if genre == "vagues":
        return vagues(rng, nom)
    if genre == "crue":
        return crue(rng, nom)
    return particules(rng, nom, genre)


# ------------------------------------------------------------------ jouer

def jouer(projet: Any, scenes: list[Scene], travail: Path) -> tuple[dict[str, dict[str, Any]], Any]:
    """(vérité par nom de scène, sortie de Godot) ; les images dans `travail`. Une scène qui plante ne donne rien."""
    from usine.cours.base import godot
    travail.mkdir(parents=True, exist_ok=True)
    entree, verite = travail / "scenes.json", travail / "verite.json"
    verite.unlink(missing_ok=True)
    entree.write_text(json.dumps([s.pour_godot() for s in scenes], ensure_ascii=False), encoding="utf-8")
    sortie = godot.tester(projet.chemin, "res://voir_fluide.gd", DELAI_SCENE * len(scenes), [str(entree), str(travail), str(verite)])
    if not verite.is_file():
        return {}, sortie
    resultats = json.loads(verite.read_text(encoding="utf-8"))
    for r in resultats:
        for m in r.get("mesures", []):
            # Un NaN sort du JSON en null : le calcul s'est emballé, quelle que soit la mesure touchée.
            if any(v is None for v in (m.get("total"), m.get("pic"), *m.get("centre", (None,)))):
                m["emballe"] = True
    # Une erreur d'exécution pendant la scène laisse un résultat vide : sans nom, la scène ne donne rien.
    return {r["nom"]: r for r in resultats if "nom" in r}, sortie


def atteint(s: Scene, m: dict[str, Any]) -> bool:
    _, cle, valeur, sens = s.cible
    return not m.get("emballe") and m[cle] * sens >= valeur * sens


def premier_contact(s: Scene, mesures: list[dict[str, Any]]) -> int | None:
    return next((i for i, m in enumerate(mesures) if atteint(s, m)), None)


def _garder(travail: Path, s: Scene, indices: list[int], images: Path, prefixe: str = "") -> list[str]:
    """Les images choisies, rangées avec les paires ; leurs chemins absolus, comme LLaMA-Factory les lit."""
    chemins = []
    for i in indices:
        cible = images / f"{prefixe}{s.nom}_{i:02d}.png"
        if not cible.exists():
            shutil.copy2(travail / f"{s.nom}_{i}.png", cible)
        chemins.append(cible.resolve().as_posix())
    return chemins


# ------------------------------------------------------------------ les paires

def _images(s: Scene, indices: list[int]) -> str:
    return "\n".join(f"{fmt.MARQUE_IMAGE} {_s(s.instants()[i])}" for i in indices)


def _paire(s: Scene, type_: str, demande: str, reponse: str, indices: list[int], chemins: list[str], preuve: dict[str, Any],
           court: bool = False) -> dict[str, Any]:
    """Palier 2 avec le plan ; `court` : palier 1, sans le plan."""
    return fmt.paire(FAMILLE, SUJET, type_, f"{_images(s, indices)}\n{demande}", reponse, dict(preuve, palier=1 if court else 2),
                     systeme=None if court else fmt.plan(), images=chemins)


def tient(p: dict[str, Any]) -> bool:
    return p["jetons"] <= (PLAFOND if p["preuve"]["palier"] == 2 else PLAFOND_COURT)


def _preuve(s: Scene, indices: list[int], mesures: list[dict[str, Any]], question: str) -> dict[str, Any]:
    return {"outil": "voir_fluide", "genre": s.genre, "scene": s.nom, "question": question, "code_scene": s.code, "delta": s.delta,
            "instants": [s.instants()[i] for i in indices], "mesures": [mesures[i] for i in indices], "etape": f"fluides-{ETAPE:03d}"}


def _grille(s: Scene) -> str:
    return f"grille de {s.largeur} × {s.hauteur} cases (une case fait {LARGEUR_IMAGE // s.largeur} pixels)"


def _direction(dx: float, dy: float) -> str:
    """Là où va un déplacement, à l'écran : les y vont vers le bas."""
    horizontal = "la droite" if dx > 0 else "la gauche"
    vertical = "le haut" if dy < 0 else "le bas"
    if abs(dx) > 2 * abs(dy):
        return horizontal
    if abs(dy) > 2 * abs(dx):
        return vertical
    return f"{vertical} et {horizontal}"


def paire_creation(s: Scene, indices: list[int], chemins: list[str], mesures: list[dict[str, Any]], court: bool = False) -> dict[str, Any]:
    nourrit = "feed(" in s.code
    demande = (f"Je veux ce résultat avec `{CLASSES[s.genre]}`, sur une {_grille(s)}, par pas de {_pas(s.delta)}. {s.reglages[:1].upper()}{s.reglages[1:]}. "
               f"Écris `build()`{' et `feed(solver, delta)`' if nourrit else ''}.")
    reponse = f"Je lis les images : {s.decor}.\n```gdscript\n{s.code.strip()}\n```"
    return _paire(s, "création", demande, reponse, indices, chemins, _preuve(s, indices, mesures, "code"), court)


def texte_reconnaitre(s: Scene, m: dict[str, Any]) -> str:
    etendue = f"Ce qui se voit va de la colonne {m['gauche']:.0f} à la colonne {m['droite']:.0f}, et de la ligne {m['haut']:.0f} à la ligne {m['bas']:.0f}."
    return " ".join(x for x in (NATURES[s.genre], s.repere, etendue, f"C'est le rendu de `{CLASSES[s.genre]}`.") if x)


def paire_reconnaitre(s: Scene, i: int, chemins: list[str], mesures: list[dict[str, Any]]) -> dict[str, Any]:
    """Niveau 1 de la décision 19.3 : reconnaître ce qu'on voit."""
    demande = f"Qu'est-ce que cette image montre ? Une {_grille(s)}."
    return _paire(s, "analyse", demande, texte_reconnaitre(s, mesures[i]), [i], chemins, _preuve(s, [i], mesures, "reconnaitre"), True)


def paire_comparer(s: Scene, indices: list[int], chemins: list[str], mesures: list[dict[str, Any]]) -> dict[str, Any]:
    """Niveau 2 : comparer deux instants."""
    demande = f"Qu'est-ce qui change entre ces deux images ? Une {_grille(s)}."
    return _paire(s, "analyse", demande, lecture(s, indices, mesures), indices, chemins, _preuve(s, indices, mesures, "comparer"), True)


def paire_normale(s: Scene, indices: list[int], chemins: list[str], mesures: list[dict[str, Any]], vus: list[str] | None = None) -> dict[str, Any]:
    """Niveau 3 : voulu ou défaut. La même question sur des images saines : sans elles, la bonne réponse serait toujours non."""
    demande = f"{NOMS[s.genre][:1].upper()}{NOMS[s.genre][1:]} doit {s.attendu}. Ce que je vois est-il normal ?"
    reponse = f"Non. {_phrase(vus)}." if vus else f"Oui. {lecture(s, indices, mesures)}"
    return _paire(s, "analyse", demande, reponse, indices, chemins, _preuve(s, indices, mesures, "normal"), True)


def _contact(s: Scene, indices: list[int], mesures: list[dict[str, Any]]) -> str:
    """La phrase sur ce qu'on attendait, vue dans ces images seulement."""
    ce = s.cible[0]
    pronom = PRONOMS[s.genre]
    atteintes = [j for j, i in enumerate(indices) if atteint(s, mesures[i])]
    if not atteintes:
        return f"{pronom} n'a pas atteint {ce} à {_s(mesures[indices[-1]]['instant'])}."
    j = atteintes[0]
    if j == 0:
        return f"{pronom} a déjà atteint {ce} à {_s(mesures[indices[0]]['instant'])}."
    return f"{pronom} atteint {ce} entre {_s(mesures[indices[j - 1]]['instant'])} et {_s(mesures[indices[j]]['instant'])}."


def lecture(s: Scene, indices: list[int], mesures: list[dict[str, Any]]) -> str:
    a, b = mesures[indices[0]], mesures[indices[-1]]
    duree = b["instant"] - a["instant"]
    ax, ay, bx, by = *a["centre"], *b["centre"]
    nom = NOMS[s.genre][:1].upper() + NOMS[s.genre][1:]
    if s.genre in ("gaz", "feu"):
        texte = (f"{nom} part de ({s.depart[0]}, {s.depart[1]}) et va vers {_direction(bx - ax, by - ay)}. Son centre passe de ({ax:.0f}, {ay:.0f}) à "
                 f"({bx:.0f}, {by:.0f}), soit {_n(math.hypot(bx - ax, by - ay) / duree)} cases par seconde. Son bord haut va de la ligne {a['haut']} à la ligne {b['haut']}.")
    elif s.genre == "vagues":
        texte = (f"{nom} s'élargit depuis ({s.depart[0]}, {s.depart[1]}) : de {a['droite'] - a['gauche']} à {b['droite'] - b['gauche']} cases de large. "
                 f"Le plus grand écart à l'eau plate passe de {_n(a['pic'], 2)} à {_n(b['pic'], 2)}.")
    else:
        debut, fini = (round(a["gauche"]), round(a["droite"])), (round(b["gauche"]), round(b["droite"]))
        texte = (f"{nom} reste entre les colonnes {debut[0]} et {debut[1]}." if debut == fini
                 else f"{nom} va de la colonne {debut[0]} à la colonne {debut[1]} au début, de {fini[0]} à {fini[1]} à la fin.")
        texte += f" Son centre passe de ({ax:.0f}, {ay:.0f}) à ({bx:.0f}, {by:.0f})."
        if s.genre == "crue":
            texte += f" Le volume reste à {_n(b['total'], 0)} : l'eau ne se perd pas." if abs(b["total"] / a["total"] - 1) < 0.01 else ""
        else:
            texte += f" La plus grande vitesse est de {_n(b['pic'], 0)} cases par seconde à la fin."
    return f"{texte} {_contact(s, indices, mesures)}"


def paire_lecture(s: Scene, indices: list[int], chemins: list[str], mesures: list[dict[str, Any]]) -> dict[str, Any]:
    demande = f"Que montre cette séquence ? {s.decor[:1].upper()}{s.decor[1:]}, sur une {_grille(s)}. On doit y voir {NOMS[s.genre]} {s.attendu}."
    return _paire(s, "analyse", demande, lecture(s, indices, mesures), indices, chemins, _preuve(s, indices, mesures, "lecture"))


def _position(s: Scene, m: dict[str, Any]) -> float:
    return m[s.cible[1]]


def reponse_tempo(s: Scene, indices: list[int], mesures: list[dict[str, Any]]) -> str | None:
    """Ces images montrent-elles l'instant cherché ? Sinon, quelles images prendre : déduit des images, gardé s'il encadre le vrai instant."""
    vrai = premier_contact(s, mesures)
    if vrai is None or vrai == 0:
        return None
    instants = [mesures[i]["instant"] for i in indices]
    _, _, valeur, sens = s.cible
    if vrai > indices[-1]:
        avant, dernier = mesures[indices[-2]], mesures[indices[-1]]
        vitesse = (_position(s, dernier) - _position(s, avant)) * sens / (dernier["instant"] - avant["instant"])
        reste = (valeur - _position(s, dernier)) * sens
        if vitesse <= 0 or reste <= 0:
            return None
        attente = reste / vitesse
        debut, fin = dernier["instant"] + 0.5 * attente, dernier["instant"] + 1.5 * attente
        if not debut <= mesures[vrai]["instant"] <= fin:
            return None
        return (f"Non, c'est trop tôt. À {_s(instants[-1])}, le bord en est encore à {reste:.0f} cases, et il en fait {_n(vitesse, 0)} par seconde : "
                f"il faut compter environ {_s(attente)} de plus. Je prends 5 images de {_s(debut)} à {_s(fin)}.")
    if vrai < indices[0]:
        return f"Non, c'est trop tard : à {_s(instants[0])}, c'est déjà fait. Je reprends plus tôt, 5 images de 0 à {_s(instants[0])}."
    j = next(k for k, i in enumerate(indices) if i >= vrai)
    if j == 0:
        return None
    ecart = instants[j] - instants[j - 1]
    return (f"Oui, entre les images {j} et {j + 1}, de {_s(instants[j - 1])} à {_s(instants[j])}. Cet écart de {_s(ecart)} est trop large pour donner "
            f"l'instant : je resserre, 5 images dans cet intervalle.")


def paire_tempo(s: Scene, indices: list[int], chemins: list[str], mesures: list[dict[str, Any]]) -> dict[str, Any] | None:
    reponse = reponse_tempo(s, indices, mesures)
    if reponse is None:
        return None
    question = f"Je cherche l'instant où {NOMS[s.genre]} atteint {s.cible[0]}. Ces 5 images le montrent-elles ?"
    return _paire(s, "analyse", question, reponse, indices, chemins, _preuve(s, indices, mesures, "tempo"))


# ------------------------------------------------------------------ les fautes

def _aire(m: dict[str, Any]) -> float:
    return max((m["droite"] - m["gauche"]) * (m["bas"] - m["haut"]), 1)


def symptomes(s: Scene, sain: list[dict[str, Any]], fautif: list[dict[str, Any]]) -> list[str]:
    """Ce qui se voit dans les images fautives et ne se verrait pas dans les saines. Les chiffres cités viennent des images fautives, seules
    visibles : les saines ne servent qu'à décider."""
    nom = NOMS[s.genre][:1].upper() + NOMS[s.genre][1:]
    emballe = next((i for i, m in enumerate(fautif) if m.get("emballe")), None)
    if emballe is not None:
        return [f"le calcul s'emballe : à {_s(fautif[emballe]['instant'])}, les valeurs n'ont plus de sens"]
    a0, b0, a1, b1 = sain[0], sain[-1], fautif[0], fautif[-1]
    vus: list[str] = []
    if s.genre == "vagues":
        # Un anneau touche vite les bords : sa largeur ne dit quelque chose qu'au début, et son centre ne bouge pas s'il est sain.
        l0, l1 = sain[TOT]["droite"] - sain[TOT]["gauche"], fautif[TOT]["droite"] - fautif[TOT]["gauche"]
        if l1 < LARGEUR_PETITE * l0:
            vus.append(f"{nom} s'élargit trop lentement : {l1} cases de large à {_s(fautif[TOT]['instant'])}")
        elif l1 > LARGEUR_GRANDE * l0:
            vus.append(f"{nom} s'élargit trop vite : {l1} cases de large à {_s(fautif[TOT]['instant'])}")
    else:
        depl_s = (b0["centre"][0] - a0["centre"][0], b0["centre"][1] - a0["centre"][1])
        depl_f = (b1["centre"][0] - a1["centre"][0], b1["centre"][1] - a1["centre"][1])
        long_s, long_f = math.hypot(*depl_s), math.hypot(*depl_f)
        duree = b1["instant"] - a1["instant"]
        if long_s >= MOUVEMENT_MIN:
            if depl_s[0] * depl_f[0] + depl_s[1] * depl_f[1] < 0 and long_f >= MOUVEMENT_MIN:
                vus.append(f"{nom} va vers {_direction(*depl_f)}, pas vers {_direction(*depl_s)} : son centre fait {long_f:.0f} cases dans ce sens")
            elif long_f < TROP_LENT * long_s:
                vus.append(f"{nom} n'avance presque pas : son centre ne fait que {long_f:.0f} cases en {_s(duree)}")
            elif long_f > TROP_VITE * long_s:
                vus.append(f"{nom} va bien trop vite : son centre fait {long_f:.0f} cases en {_s(duree)}")
    if not vus and math.dist(b0["centre"], b1["centre"]) >= ECART_CENTRE * s.largeur:
        vus.append(f"{nom} dévie : son centre finit en ({b1['centre'][0]:.0f}, {b1['centre'][1]:.0f})")
    if s.mur:
        passe = {"haut": b1["haut"] < s.mur[1] - 1 <= b0["haut"], "droite": b1["droite"] > s.mur[2] + 2 >= b0["droite"],
                 "gauche": b1["gauche"] < s.mur[0] - 1 <= b0["gauche"]}
        if passe.get(s.cible[1]):
            vus.append(f"{nom} passe à travers le mur : son bord arrive en {b1[s.cible[1]]:.0f}")
    if b0["pic"] > 0:
        rapport = b1["pic"] / b0["pic"]
        # Le sens du mot suit les images fautives : un pic bien plus haut que le sain peut quand même descendre, moins vite.
        va = f"{'de ' + _n(a1['pic'], 2) + ' à ' + _n(b1['pic'], 2)}"
        if s.genre in ("flip", "sph"):
            if rapport < PIC_BAS and b1["pic"] < a1["pic"]:
                vus.append(f"{nom} se fige : sa plus grande vitesse tombe {va} cases par seconde")
            elif rapport > PIC_HAUT and b1["pic"] > a1["pic"]:
                vus.append(f"{nom} accélère sans fin : sa plus grande vitesse passe {va} cases par seconde")
        elif rapport < PIC_BAS and b1["pic"] < a1["pic"]:
            vus.append(f"{nom} s'éteint : le pic tombe {va}")
        elif rapport < PIC_BAS:
            vus.append(f"{nom} reste faible : le pic n'est que de {_n(b1['pic'], 2)}")
        elif rapport > PIC_HAUT and b1["pic"] > a1["pic"]:
            vus.append(f"{nom} s'accumule : le pic monte {va}")
        elif rapport > PIC_HAUT:
            vus.append(f"{nom} se disperse à peine : le pic ne descend que {va}")
    if s.genre != "vagues":
        rapport = _aire(b1) / _aire(b0)
        large, epais = b1["droite"] - b1["gauche"], b1["bas"] - b1["haut"]
        taille_vue = f"{large:.0f} × {epais:.0f} cases" if epais >= 1 else f"une simple ligne de {large:.0f} cases"
        if rapport < AIRE_PETITE:
            vus.append(f"{nom} reste ramassé{'e' if PRONOMS[s.genre] == 'Elle' else ''} : {taille_vue}")
        elif rapport > AIRE_GRANDE:
            vus.append(f"{nom} s'étale bien trop : {taille_vue}")
        cle = s.cible[1]
        taille = s.hauteur if cle in ("haut", "bas") else s.largeur
        if not vus and abs(b1[cle] - b0[cle]) >= ECART_FRONT * taille:
            vus.append(f"{nom} n'arrive pas où il faut : à {_s(b1['instant'])}, son bord {cle if cle in ('haut', 'bas') else 'de ' + cle} est en {b1[cle]:.0f}")
    return vus[:2]


def _phrase(vus: list[str]) -> str:
    return vus[0][:1].upper() + vus[0][1:] + "".join(f" ; {v[:1].lower()}{v[1:]}" for v in vus[1:])


def _extrait(code: str, f: faute_calcul.Faute) -> str | None:
    """La signature et quelques lignes autour de la faute, pour une fonction trop longue. Le plan et les images ne laissent pas la place d'une
    fonction entière ; la faute reste à trouver parmi ces lignes."""
    lignes = [l for l in code.split("\n") if not l.startswith("##")]
    cherchee = f.fautif.split("\n")[-1]
    if cherchee not in lignes:
        return None
    k = lignes.index(cherchee)
    debut, fin = max(k - 3, 1), min(k + 4, len(lignes))
    return "\n".join(lignes[:1] + (["\t# [...]"] if debut > 1 else []) + lignes[debut:fin] + (["\t# [...]"] if fin < len(lignes) else []))


def paire_faute(s: Scene, f: faute_calcul.Faute, vus: list[str], indices: list[int], chemins: list[str], mesures: list[dict[str, Any]],
                saines: list[dict[str, Any]], sortie: Any, court: bool = False) -> tuple[dict[str, Any] | None, str]:
    """Niveau 4 : relier le défaut à sa ligne. `court` : deux images, sans le plan."""
    trouve = faute_calcul.fonction_de(f.fichier, f.texte, f.ligne)
    if trouve is None:
        return None, "hors d'une fonction"
    nom, _, code = trouve
    diagnostic = faute_calcul.DIAGNOSTICS[f.genre].format(de=f.de, vers=f.vers)
    diagnostic = diagnostic[:1].upper() + diagnostic[1:]
    lignes = code.split("\n")
    # Une même ligne peut revenir dans la fonction : la ligne d'avant dit laquelle change. La demande ne montre pas de numéros de ligne.
    cherchee = f.fautif.split("\n")[-1]
    place = "Cette ligne devient"
    if lignes.count(cherchee) > 1:
        place = f"Après `{f.texte.split(chr(10))[f.ligne - 2].strip()}`, la ligne devient"
    reponse = f"**Voir.** {_phrase(vus)}.\n\n**Chercher.** {diagnostic}.\n\n**Corriger.** {place} :\n```gdscript\n{f.juste}\n```"
    preuve = dict(_preuve(s, indices, mesures, "faute"), fichier=f.fichier, ligne=f.ligne, genre_faute=f.genre, fonction=nom,
                  mesures_saines=[saines[i] for i in indices], commande=sortie.commande, code_sortie=sortie.code)
    p = None
    for corps in (code, "\n".join(l for l in lignes if not l.startswith("##")), _extrait(code, f)):
        if corps is None:
            continue
        demande = (f"{NOMS[s.genre][:1].upper()}{NOMS[s.genre][1:]} devrait {s.attendu}. Le code, dans `res://{f.fichier}` :\n```gdscript\n{corps}\n```\nTrouve la faute.")
        p = _paire(s, "débogage", demande, reponse, indices, chemins, preuve, court)
        if tient(p):
            return p, ""
    return None, f"trop longue ({p['jetons'] if p else '?'} jetons)"


def essayer_faute(projet: Any, s: Scene, f: faute_calcul.Faute, saines: list[dict[str, Any]], travail: Path, images: Path,
                  rang: int) -> tuple[list[dict[str, Any]], str]:
    """Les paires de cette faute sur cette scène, ou ([], raison). Le projet revient à l'état de l'étape. Une faute donne une paire au
    palier 2, où le débogage manque, et une au palier 1 : à tour de rôle, relier le défaut à sa ligne ou dire que ce n'est pas normal."""
    projet.remettre()
    projet.ecrire(f.fichier, f.texte)
    try:
        dossier = travail / f"faute_{rang}"
        verite, sortie = jouer(projet, [s], dossier)
    finally:
        projet.remettre()
    r = verite.get(s.nom)
    if r is None or "erreur" in r or len(r.get("mesures", [])) != IMAGES:
        return [], "ne tourne plus : une erreur, pas une faute de calcul"
    # Une grille à zéro case tourne sans erreur et donne ses mesures, mais aucune image.
    if not all((dossier / f"{s.nom}_{i}.png").is_file() for i in range(IMAGES)):
        return [], "rien à voir : la scène ne donne pas ses images"
    fautif = r["mesures"]
    vus = symptomes(s, saines, fautif)
    if not vus:
        return [], "ne se voit pas"
    emballe = next((i for i, m in enumerate(fautif) if m.get("emballe")), None)
    if emballe == 0:
        return [], "rien à voir : le calcul est faux dès la première image"
    if emballe is None:
        indices, deux = IMAGES_FAUTE, [IMAGES_FAUTE[2], IMAGES_FAUTE[-1]]
    else:
        debut = min(max(emballe - 3, 0), IMAGES - 5)
        indices, deux = list(range(debut, debut + 5)), [emballe - 1, emballe]
    prefixe = f"f{rang:04d}_"
    p, raison = paire_faute(s, f, vus, indices, _garder(dossier, s, indices, images, prefixe), fautif, saines, sortie)
    if p is None:
        shutil.rmtree(dossier, ignore_errors=True)
        return [], raison
    paires = [p]
    vues_courtes = _garder(dossier, s, deux, images, prefixe)
    if rang % 2 == 0:
        paires.append(paire_normale(s, deux, vues_courtes, fautif, vus))
    else:
        courte, _ = paire_faute(s, f, vus, deux, vues_courtes, fautif, saines, sortie, court=True)
        paires += [courte] if courte else []
    shutil.rmtree(dossier, ignore_errors=True)
    return paires, ""


def fautes_de(s: Scene, apres: dict[str, str], vues: set[tuple[str, str, str]]) -> list[faute_calcul.Faute]:
    sortie: list[faute_calcul.Faute] = []
    for fichier in s.fichiers:
        if fichier == "obstacle_mask" and not s.mur:
            continue
        rel = f"{SOLVEUR}{fichier}.gd"
        for f in faute_calcul.fautes(rel, apres[rel]):
            trouve = faute_calcul.fonction_de(f.fichier, f.texte, f.ligne)
            if f.cle() not in vues and trouve is not None and trouve[0] not in s.mortes:
                sortie.append(f)
    return sortie


# ------------------------------------------------------------------ générer

def _fenetres(rng: random.Random) -> tuple[list[int], list[int]]:
    """(5 images régulières sur toute la scène, 5 images d'un balayage serré ou d'un autre tempo) : l'espacement n'est pas toujours le même."""
    pas = rng.choice((1, 2))
    debut = rng.randrange(0, IMAGES - 4 * pas)
    return rng.choice(FENETRES_LARGES), [debut + k * pas for k in range(5)]


def _deux_instants(rng: random.Random) -> list[int]:
    """Deux images assez éloignées pour que la différence se voie."""
    a = rng.randrange(0, IMAGES - ECART_DEUX)
    return [a, rng.randrange(a + ECART_DEUX, IMAGES)]


def paires_saines(s: Scene, k: int, rng: random.Random, dossier: Path, images: Path, mesures: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[str]]:
    """Les paires d'une scène saine, et ce qui en a été écarté. Le palier 1 manque de création : chaque scène lui en donne une ; le palier 2
    en a assez : une scène sur trois. L'analyse suit, pour rester au cinquième."""
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    large, autre = _fenetres(rng)

    def vues(indices: list[int]) -> list[str]:
        return _garder(dossier, s, indices, images)

    fin = rng.randrange(6, IMAGES)
    paires.append(paire_creation(s, [0, fin], vues([0, fin]), mesures, court=True))
    if k % 3 == 0:
        paires.append(paire_creation(s, large, vues(large), mesures))
    if k % 2 == 0:
        paires.append(paire_lecture(s, autre, vues(autre), mesures))
    else:
        p = paire_tempo(s, autre, vues(autre), mesures)
        if p is None:
            rejets.append(f"{s.nom} : pas de question de tempo")
        else:
            paires.append(p)
    i = rng.randrange(2, IMAGES)
    paires.append(paire_reconnaitre(s, i, vues([i]), mesures))
    if k % 2 == 1:
        deux = _deux_instants(rng)
        paires.append(paire_comparer(s, deux, vues(deux), mesures))
    if k % 3 == 1:
        deux = _deux_instants(rng)
        paires.append(paire_normale(s, deux, vues(deux), mesures))
    return paires, rejets


def generer(genres: tuple[str, ...] = GENRES, scenes: int = 40, fautes: int = 60, graine: int = 1, donnees: Path | None = None,
            journal: Callable[[str], None] = print) -> dict[str, Any]:
    """`scenes` scènes et `fautes` fautes essayées par genre, tirées à graine fixe : une nouvelle graine donne de nouvelles scènes."""
    from usine.cours.base import assembler, chemins, creation, sessions
    chemins.configurer(cours="fluides")
    sortie = fmt.dossier(FAMILLE, donnees)
    images = sortie / "images"
    images.mkdir(parents=True, exist_ok=True)
    rng = random.Random(graine)
    ville = next(iter(assembler.ordre_lignes()))
    _, apres = creation.etats(ville, ETAPE)
    projet = sessions.Projet(ville, ETAPE, apres, espace="voir")
    shutil.copyfile(OUTIL, Path(projet.chemin) / "voir_fluide.gd")
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    fichier = sortie / f"paires_g{graine:03d}.jsonl"
    with tempfile.TemporaryDirectory(prefix="usine_voir_fluide_") as tmp:
        travail = Path(tmp)
        rang = 0
        for genre in genres:
            jouees: list[tuple[Scene, list[dict[str, Any]]]] = []
            for k in range(scenes):
                s = scene(genre, rng, f"g{graine:03d}_{genre}_{k:03d}")
                dossier = travail / s.nom
                verite, _ = jouer(projet, [s], dossier)
                r = verite.get(s.nom)
                if r is None or "erreur" in r or any(m.get("emballe") for m in r.get("mesures", [])) or len(r.get("mesures", [])) != IMAGES:
                    rejets.append(f"{s.nom} : la scène saine ne tourne pas ({(r or {}).get('erreur') or 'calcul emballé'})")
                    continue
                mesures = r["mesures"]
                jouees.append((s, mesures))
                nouvelles, ecartees = paires_saines(s, k, rng, dossier, images, mesures)
                paires += nouvelles
                rejets += ecartees
                shutil.rmtree(dossier, ignore_errors=True)
            journal(f"{genre} : {len(jouees)}/{scenes} scènes saines, {len(paires)} paires")
            vues: set[tuple[str, str, str]] = set()
            gardees = 0
            for k in range(fautes):
                if not jouees:
                    break
                s, saines = jouees[k % len(jouees)]
                possibles = fautes_de(s, apres, vues)
                if not possibles:
                    break
                f = rng.choice(possibles)
                vues.add(f.cle())
                rang += 1
                nouvelles, raison = essayer_faute(projet, s, f, saines, travail, images, rang)
                if not nouvelles:
                    rejets.append(f"{s.nom} {f.fichier}:{f.ligne} {f.genre} : {raison}")
                    continue
                paires += nouvelles
                gardees += 1
            journal(f"{genre} : {gardees}/{fautes} fautes visibles")
            fmt.ecrire([p for p in paires if tient(p)], fichier)
    retenues = [p for p in paires if tient(p)]
    rejets += [f"{p['preuve']['scene']} {p['preuve']['question']} : trop longue ({p['jetons']} jetons)" for p in paires if not tient(p)]
    fmt.ecrire(retenues, fichier)
    bilan: dict[str, Any] = {"famille": FAMILLE, "graine": graine, "paires": len(retenues), "rejets": rejets, "par_type": {}, "par_question": {},
                             "par_genre": {}, "par_palier": {}, "jetons_max": max((p["jetons"] for p in retenues), default=0),
                             "jetons_reponse": {str(n): {t: sum(p["jetons_reponse"] for p in retenues if p["type"] == t and p["preuve"]["palier"] == n)
                                                         for t in fmt.TYPES} for n in (1, 2)}}
    for p in retenues:
        for cle, val in (("par_type", p["type"]), ("par_question", p["preuve"]["question"]), ("par_genre", p["preuve"]["genre"]),
                         ("par_palier", p["preuve"]["palier"])):
            bilan[cle][val] = bilan[cle].get(val, 0) + 1
    (sortie / f"bilan_g{graine:03d}.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
