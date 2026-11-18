"""Fabrique les assets d'exemple du cours « visualiseur_animations » : trois modèles 3D animés au format glTF binaire
(un héros et un golem à squelette, un coffre sans squelette), une animation 2D en atlas au format de l'optimiseur de
l'éditeur de cartes (`atlas_animation`, version 1) et une animation 2D en dossier d'images numérotées. Même graine,
mêmes fichiers.

Demande de laurent du 2026-11-18 : « un cours qui permette de créer un visualiseur d'animation des assets du jeu, les
ennemis, les boss, les props, de visualiser sous tous les angles (quand ils sont en 3D) ou en 2D […] et d'en contrôler
l'enchaînement des animations avec la manette » ; premier ennemi en « 3D Blender (.glb) ».

Les modèles sont faits de pavés, chacun rigide sur un os (poids 1) : le pantin suffit à voir une pose, un angle, une
ombre ; les vrais modèles viennent de Blender. Le héros regarde vers +Z (avant de glTF, celui d'un export de Blender).
Les noms d'animations sont ceux du cycle de laurent : pause, debut_course, course, fin_course, dash, attaque, coup_recu.

Sorties, dans le jeu source (clé `visualiseur_animations` de [sources]), sous `6_assets/exemple/` (un `.gdignore` :
Godot ne les importe pas, le visualiseur les lit comme des fichiers, comme il lira ceux de Blender) :
- `heros/heros.glb`, `ennemis/golem.glb`, `props/coffre.glb` ;
- `effets/flamme/flamme.atlas.json` et `flamme_0.png` ; `effets/etincelle/001.png` … `008.png`.

    python cours/visualiseur_animations/outils/fabriquer_exemple.py [--source <dossier>]
"""

from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path
from typing import Callable

from PIL import Image, ImageDraw, ImageFilter

SOURCE_DEFAUT = Path(r"D:\GODOT\PROJETS_DEMOS\PROJET_VISUALISEUR_ANIMATIONS")
IPS = 30  # images par seconde des clés d'animation

Vec3 = tuple[float, float, float]
Euler = tuple[float, float, float]  # degrés, autour de X, Y, Z


# --- quaternions -------------------------------------------------------------------------------------------------

def _q_axe(axe: Vec3, degres: float) -> tuple[float, float, float, float]:
    a = math.radians(degres) / 2.0
    s = math.sin(a)
    return (axe[0] * s, axe[1] * s, axe[2] * s, math.cos(a))


def _q_mul(a: tuple[float, ...], b: tuple[float, ...]) -> tuple[float, float, float, float]:
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
            aw * bw - ax * bx - ay * by - az * bz)


def quat(e: Euler) -> tuple[float, float, float, float]:
    """Rotation Y, puis X, puis Z (lacet, tangage, roulis), en degrés."""
    q = _q_mul(_q_axe((0, 1, 0), e[1]), _q_mul(_q_axe((1, 0, 0), e[0]), _q_axe((0, 0, 1), e[2])))
    return tuple(round(c, 6) for c in q)  # type: ignore[return-value]


# --- écrivain glTF binaire --------------------------------------------------------------------------------------

class Gltf:
    def __init__(self, generateur: str) -> None:
        self.doc: dict = {"asset": {"version": "2.0", "generator": generateur}, "scene": 0, "scenes": [{"nodes": []}],
                          "nodes": [], "meshes": [], "materials": [], "accessors": [], "bufferViews": [],
                          "buffers": [{"byteLength": 0}]}
        self.binaire = bytearray()

    def vue(self, donnees: bytes, cible: int | None = None) -> int:
        while len(self.binaire) % 4:
            self.binaire.append(0)
        vue = {"buffer": 0, "byteOffset": len(self.binaire), "byteLength": len(donnees)}
        if cible is not None:
            vue["target"] = cible
        self.binaire += donnees
        self.doc["bufferViews"].append(vue)
        return len(self.doc["bufferViews"]) - 1

    def accesseur(self, valeurs: list[tuple[float, ...]] | list[float] | list[int], type_: str, composante: int,
                  cible: int | None = None, bornes: bool = False) -> int:
        formats = {5126: "f", 5123: "H", 5121: "B"}
        plat: list[float] = []
        for v in valeurs:
            plat.extend(v if isinstance(v, tuple) else (v,))
        donnees = struct.pack("<" + formats[composante] * len(plat), *plat)
        acc = {"bufferView": self.vue(donnees, cible), "componentType": composante,
               "count": len(valeurs), "type": type_}
        if bornes:
            n = len(plat) // len(valeurs)
            acc["min"] = [min(plat[i::n]) for i in range(n)]
            acc["max"] = [max(plat[i::n]) for i in range(n)]
        self.doc["accessors"].append(acc)
        return len(self.doc["accessors"]) - 1

    def materiau(self, nom: str, couleur: tuple[int, int, int]) -> int:
        self.doc["materials"].append({"name": nom, "pbrMetallicRoughness": {
            "baseColorFactor": [round(c / 255.0, 4) for c in couleur] + [1.0], "metallicFactor": 0.0,
            "roughnessFactor": 0.85}})
        return len(self.doc["materials"]) - 1

    def noeud(self, **champs: object) -> int:
        self.doc["nodes"].append({k: v for k, v in champs.items() if v is not None})
        return len(self.doc["nodes"]) - 1

    def ecrire(self, chemin: Path) -> None:
        while len(self.binaire) % 4:
            self.binaire.append(0)
        self.doc["buffers"][0]["byteLength"] = len(self.binaire)
        for cle in ("materials", "meshes"):
            if not self.doc[cle]:
                del self.doc[cle]
        texte = json.dumps(self.doc, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        texte += b" " * ((4 - len(texte) % 4) % 4)
        total = 12 + 8 + len(texte) + 8 + len(self.binaire)
        sortie = struct.pack("<III", 0x46546C67, 2, total)
        sortie += struct.pack("<II", len(texte), 0x4E4F534A) + texte
        sortie += struct.pack("<II", len(self.binaire), 0x004E4942) + bytes(self.binaire)
        chemin.parent.mkdir(parents=True, exist_ok=True)
        chemin.write_bytes(sortie)


_FACES = [((1, 0, 0), (0, 1, 0), (0, 0, 1)), ((-1, 0, 0), (0, 1, 0), (0, 0, -1)),
          ((0, 1, 0), (0, 0, 1), (1, 0, 0)), ((0, -1, 0), (0, 0, -1), (1, 0, 0)),
          ((0, 0, 1), (1, 0, 0), (0, 1, 0)), ((0, 0, -1), (-1, 0, 0), (0, 1, 0))]


def pave(centre: Vec3, taille: Vec3) -> tuple[list[Vec3], list[Vec3], list[int]]:
    """Les sommets (faces plates), normales et indices d'un pavé, faces tournées vers l'extérieur."""
    sommets: list[Vec3] = []
    normales: list[Vec3] = []
    indices: list[int] = []
    h = [t / 2.0 for t in taille]
    for n, u, v in _FACES:
        base = len(sommets)
        for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            sommets.append(tuple(round(centre[i] + n[i] * h[i] + u[i] * su * h[i] + v[i] * sv * h[i], 5)
                                 for i in range(3)))  # type: ignore[arg-type]
            normales.append(tuple(float(c) for c in n))  # type: ignore[arg-type]
        # u × v = n : le sens (0, 1, 2) est direct vu de l'extérieur, celui que glTF attend.
        indices += [base, base + 1, base + 2, base, base + 2, base + 3]
    return sommets, normales, indices


# --- pantins à squelette ----------------------------------------------------------------------------------------

class Os:
    def __init__(self, nom: str, parent: str | None, position: Vec3,
                 paves: list[tuple[Vec3, Vec3, str]]) -> None:
        self.nom, self.parent, self.position, self.paves = nom, parent, position, paves


def _global(os_: dict[str, Os], nom: str) -> Vec3:
    p = os_[nom]
    if p.parent is None:
        return p.position
    g = _global(os_, p.parent)
    return (g[0] + p.position[0], g[1] + p.position[1], g[2] + p.position[2])


Pose = dict[str, Euler]
Clip = tuple[float, bool, Callable[[float], tuple[Pose, Vec3]]]  # durée, boucle, phase → (rotations, décalage du bassin)


def ecrire_pantin(chemin: Path, nom: str, os_liste: list[Os], couleurs: dict[str, tuple[int, int, int]],
                  clips: dict[str, Clip]) -> None:
    g = Gltf("usine · visualiseur_animations · fabriquer_exemple.py")
    os_ = {o.nom: o for o in os_liste}
    noms = [o.nom for o in os_liste]
    materiaux = {cle: g.materiau(cle, c) for cle, c in couleurs.items()}

    # Le maillage : un primitif par matériau, chaque sommet rigide sur son os (poids 1).
    primitifs = []
    for cle, mat in materiaux.items():
        sommets: list[Vec3] = []
        normales: list[Vec3] = []
        indices: list[int] = []
        articulations: list[tuple[int, int, int, int]] = []
        for i, o in enumerate(os_liste):
            origine = _global(os_, o.nom)
            for centre, taille, couleur in o.paves:
                if couleur != cle:
                    continue
                s, n, ind = pave((origine[0] + centre[0], origine[1] + centre[1], origine[2] + centre[2]), taille)
                indices += [len(sommets) + k for k in ind]
                sommets += s
                normales += n
                articulations += [(i, 0, 0, 0)] * len(s)
        if not sommets:
            continue
        primitifs.append({"attributes": {
            "POSITION": g.accesseur(sommets, "VEC3", 5126, 34962, bornes=True),
            "NORMAL": g.accesseur(normales, "VEC3", 5126, 34962),
            "JOINTS_0": g.accesseur(articulations, "VEC4", 5121, 34962),
            "WEIGHTS_0": g.accesseur([(1.0, 0.0, 0.0, 0.0)] * len(sommets), "VEC4", 5126, 34962)},
            "indices": g.accesseur(indices, "SCALAR", 5123, 34963), "material": mat})
    g.doc["meshes"].append({"name": nom + "_corps", "primitives": primitifs})

    # Les os : un nœud par os, en arbre ; le pose de repos est sans rotation.
    index: dict[str, int] = {}
    for o in os_liste:
        index[o.nom] = g.noeud(name=o.nom, translation=list(o.position))
    for o in os_liste:
        enfants = [index[e.nom] for e in os_liste if e.parent == o.nom]
        if enfants:
            g.doc["nodes"][index[o.nom]]["children"] = enfants
    inverses: list[tuple[float, ...]] = []
    for o in os_liste:
        p = _global(os_, o.nom)
        inverses.append((1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -p[0], -p[1], -p[2], 1))
    racine = index[os_liste[0].nom]
    g.doc["skins"] = [{"name": nom + "_squelette", "joints": [index[n] for n in noms], "skeleton": racine,
                       "inverseBindMatrices": g.accesseur(inverses, "MAT4", 5126)}]
    corps = g.noeud(name=nom + "_corps", mesh=0, skin=0)
    haut = g.noeud(name=nom, children=[racine, corps])
    g.doc["scenes"][0]["nodes"] = [haut]

    # Les animations : des clés à IPS images par seconde, rotations de chaque os, translation du bassin.
    animations = []
    bassin = os_liste[1].nom
    for nom_clip, (duree, boucle, pose) in clips.items():
        n = max(2, round(duree * IPS) + 1)
        temps = [round(duree * k / (n - 1), 5) for k in range(n)]
        poses = [pose(k / (n - 1)) for k in range(n)]
        if boucle:
            poses[-1] = poses[0]
        entree = g.accesseur(temps, "SCALAR", 5126, bornes=True)
        echantillons, canaux = [], []
        for o in os_liste:
            rotations = [quat(p[0].get(o.nom, (0.0, 0.0, 0.0))) for p in poses]
            echantillons.append({"input": entree, "output": g.accesseur(rotations, "VEC4", 5126),
                                 "interpolation": "LINEAR"})
            canaux.append({"sampler": len(echantillons) - 1, "target": {"node": index[o.nom], "path": "rotation"}})
        base = os_[bassin].position
        positions = [(round(base[0] + p[1][0], 5), round(base[1] + p[1][1], 5), round(base[2] + p[1][2], 5))
                     for p in poses]
        echantillons.append({"input": entree, "output": g.accesseur(positions, "VEC3", 5126),
                             "interpolation": "LINEAR"})
        canaux.append({"sampler": len(echantillons) - 1, "target": {"node": index[bassin], "path": "translation"}})
        animations.append({"name": nom_clip, "samplers": echantillons, "channels": canaux})
    g.doc["animations"] = animations
    g.ecrire(chemin)


def _lerp_pose(a: tuple[Pose, Vec3], b: tuple[Pose, Vec3], s: float) -> tuple[Pose, Vec3]:
    cles = set(a[0]) | set(b[0])
    zero = (0.0, 0.0, 0.0)
    rot = {k: tuple(a[0].get(k, zero)[i] + (b[0].get(k, zero)[i] - a[0].get(k, zero)[i]) * s for i in range(3))
           for k in cles}
    dec = tuple(a[1][i] + (b[1][i] - a[1][i]) * s for i in range(3))
    return rot, dec  # type: ignore[return-value]


def _lisse(s: float) -> float:
    return s * s * (3.0 - 2.0 * s)


REPOS: tuple[Pose, Vec3] = ({}, (0.0, 0.0, 0.0))


def squelette_bipede(echelle: float, carrure: float, couleurs: tuple[str, str, str]) -> list[Os]:
    """Un bipède de pavés : bassin, torse, tête (avec un nez vers +Z), bras et jambes en deux os. `carrure` élargit
    le tronc et les membres (le golem)."""
    peau, habit, sombre = couleurs
    e, c = echelle, carrure
    hanche = 0.95 * e
    return [
        Os("racine", None, (0.0, 0.0, 0.0), []),
        Os("bassin", "racine", (0.0, hanche, 0.0), [((0, 0, 0), (0.36 * c * e, 0.2 * e, 0.22 * c * e), habit)]),
        Os("torse", "bassin", (0.0, 0.12 * e, 0.0), [((0, 0.26 * e, 0), (0.46 * c * e, 0.5 * e, 0.28 * c * e), habit)]),
        Os("tete", "torse", (0.0, 0.55 * e, 0.0), [((0, 0.15 * e, 0), (0.26 * e, 0.3 * e, 0.26 * e), peau),
                                                    ((0, 0.15 * e, 0.15 * e), (0.06 * e, 0.06 * e, 0.06 * e), sombre)]),
        Os("bras_g", "torse", (0.28 * c * e, 0.46 * e, 0.0), [((0.04 * e, -0.15 * e, 0), (0.12 * c * e, 0.32 * e, 0.12 * c * e), habit)]),
        Os("avant_bras_g", "bras_g", (0.04 * e, -0.32 * e, 0.0), [((0, -0.15 * e, 0), (0.1 * c * e, 0.3 * e, 0.1 * c * e), peau)]),
        Os("bras_d", "torse", (-0.28 * c * e, 0.46 * e, 0.0), [((-0.04 * e, -0.15 * e, 0), (0.12 * c * e, 0.32 * e, 0.12 * c * e), habit)]),
        Os("avant_bras_d", "bras_d", (-0.04 * e, -0.32 * e, 0.0), [((0, -0.15 * e, 0), (0.1 * c * e, 0.3 * e, 0.1 * c * e), peau)]),
        Os("cuisse_g", "bassin", (0.11 * c * e, -0.05 * e, 0.0), [((0, -0.22 * e, 0), (0.15 * c * e, 0.45 * e, 0.15 * c * e), sombre)]),
        Os("jambe_g", "cuisse_g", (0.0, -0.45 * e, 0.0), [((0, -0.21 * e, 0), (0.13 * c * e, 0.42 * e, 0.13 * c * e), sombre),
                                                         ((0, -0.42 * e, 0.05 * e), (0.14 * c * e, 0.06 * e, 0.24 * e), peau)]),
        Os("cuisse_d", "bassin", (-0.11 * c * e, -0.05 * e, 0.0), [((0, -0.22 * e, 0), (0.15 * c * e, 0.45 * e, 0.15 * c * e), sombre)]),
        Os("jambe_d", "cuisse_d", (0.0, -0.45 * e, 0.0), [((0, -0.21 * e, 0), (0.13 * c * e, 0.42 * e, 0.13 * c * e), sombre),
                                                         ((0, -0.42 * e, 0.05 * e), (0.14 * c * e, 0.06 * e, 0.24 * e), peau)]),
    ]


def _course(p: float, ampleur: float = 1.0, penche: float = 10.0) -> tuple[Pose, Vec3]:
    s = math.sin(2 * math.pi * p)
    genou_g = 45 * (0.5 - 0.5 * math.cos(2 * math.pi * p)) * ampleur
    genou_d = 45 * (0.5 + 0.5 * math.cos(2 * math.pi * p)) * ampleur
    return ({"torse": (penche, 0.0, 0.0), "cuisse_g": (-40 * s * ampleur, 0, 0), "cuisse_d": (40 * s * ampleur, 0, 0),
             "jambe_g": (genou_g, 0, 0), "jambe_d": (genou_d, 0, 0), "bras_g": (35 * s * ampleur, 0, 0),
             "bras_d": (-35 * s * ampleur, 0, 0), "avant_bras_g": (-40, 0, 0), "avant_bras_d": (-40, 0, 0)},
            (0.0, -0.03 + 0.04 * abs(s) * ampleur, 0.0))


def clips_heros() -> dict[str, Clip]:
    def pause(p: float) -> tuple[Pose, Vec3]:
        r = math.sin(2 * math.pi * p)
        return ({"torse": (2 * r, 0, 0), "bras_g": (0, 0, 4 + 2 * r), "bras_d": (0, 0, -4 - 2 * r)},
                (0.0, 0.01 * r, 0.0))

    def debut(p: float) -> tuple[Pose, Vec3]:
        return _lerp_pose(REPOS, _course(0.0), _lisse(p))

    def fin(p: float) -> tuple[Pose, Vec3]:
        return _lerp_pose(_course(0.0), REPOS, _lisse(p))

    def dash(p: float) -> tuple[Pose, Vec3]:
        e = math.sin(math.pi * p)
        return ({"torse": (30 * e, 0, 0), "bras_g": (60 * e, 0, 0), "bras_d": (60 * e, 0, 0),
                 "cuisse_g": (-50 * e, 0, 0), "cuisse_d": (40 * e, 0, 0), "jambe_d": (50 * e, 0, 0)},
                (0.0, -0.1 * e, 0.0))

    def attaque(p: float) -> tuple[Pose, Vec3]:
        if p < 0.4:
            s = _lisse(p / 0.4)
            bras, torse = -160 * s, -20 * s
        elif p < 0.6:
            s = _lisse((p - 0.4) / 0.2)
            bras, torse = -160 + 140 * s, -20 + 45 * s
        else:
            s = _lisse((p - 0.6) / 0.4)
            bras, torse = -20 + 20 * s, 25 - 25 * s
        return ({"bras_d": (bras, 0, 0), "avant_bras_d": (bras * 0.2, 0, 0), "torse": (0, torse, 0)}, (0.0, 0.0, 0.0))

    def coup(p: float) -> tuple[Pose, Vec3]:
        e = math.sin(math.pi * p) ** 0.5
        return ({"torse": (-25 * e, 0, 0), "tete": (-20 * e, 0, 0), "bras_g": (30 * e, 0, 20 * e),
                 "bras_d": (30 * e, 0, -20 * e)}, (0.0, 0.0, -0.08 * e))

    def salut(bras: dict[str, float]) -> Callable[[float], tuple[Pose, Vec3]]:
        def pose(p: float) -> tuple[Pose, Vec3]:
            e = math.sin(math.pi * p)
            return ({os_: (-hauteur * e, 0.0, 0.0) for os_, hauteur in bras.items()}, (0.0, 0.0, 0.0))
        return pose

    # Un clip par angle de vue (choix de laurent : « refaire toutes les animations sous tous les angles ») : le
    # visualiseur prend celui dont l'angle est le plus proche de la caméra. Chaque variante lève un bras différent,
    # pour qu'on voie laquelle joue.
    return {"pause": (1.6, True, pause), "debut_course": (0.3, False, debut), "course": (0.6, True, _course),
            "fin_course": (0.35, False, fin), "dash": (0.4, False, dash), "attaque": (0.5, False, attaque),
            "coup_recu": (0.4, False, coup), "salut_angle_0": (1.0, False, salut({"bras_d": 150.0})),
            "salut_angle_90": (1.0, False, salut({"bras_g": 150.0})),
            "salut_angle_180": (1.0, False, salut({"bras_g": 90.0, "bras_d": 90.0})),
            "salut_angle_270": (1.0, False, salut({"bras_d": 90.0}))}


def clips_golem() -> dict[str, Clip]:
    def pause(p: float) -> tuple[Pose, Vec3]:
        r = math.sin(2 * math.pi * p)
        return ({"torse": (6 + 2 * r, 0, 0), "tete": (-4, 0, 0), "bras_g": (0, 0, 8), "bras_d": (0, 0, -8)},
                (0.0, -0.05 + 0.015 * r, 0.0))

    def marche(p: float) -> tuple[Pose, Vec3]:
        return _course(p, ampleur=0.5, penche=8.0)

    def attaque(p: float) -> tuple[Pose, Vec3]:
        if p < 0.55:
            s = _lisse(p / 0.55)
            bras, torse = -150 * s, -12 * s
        elif p < 0.7:
            s = _lisse((p - 0.55) / 0.15)
            bras, torse = -150 + 130 * s, -12 + 40 * s
        else:
            s = _lisse((p - 0.7) / 0.3)
            bras, torse = -20 + 20 * s, 28 - 28 * s
        return ({"bras_g": (bras, 0, 0), "bras_d": (bras, 0, 0), "torse": (torse, 0, 0)}, (0.0, -0.15 * (torse > 20), 0.0))

    def coup(p: float) -> tuple[Pose, Vec3]:
        e = math.sin(math.pi * p) ** 0.5
        return ({"torse": (-15 * e, 0, 0), "tete": (-15 * e, 0, 0)}, (0.0, 0.0, -0.05 * e))

    def mort(p: float) -> tuple[Pose, Vec3]:
        s = _lisse(min(1.0, p / 0.8))
        return ({"racine": (-88 * s, 0, 0), "torse": (-10 * s, 0, 0), "bras_g": (0, 0, 50 * s), "bras_d": (0, 0, -50 * s)},
                (0.0, 0.0, 0.0))

    return {"pause": (2.0, True, pause), "marche": (1.0, True, marche), "attaque": (0.9, False, attaque),
            "coup_recu": (0.45, False, coup), "mort": (1.2, False, mort)}


# --- le coffre : sans squelette, un nœud animé -----------------------------------------------------------------

def ecrire_coffre(chemin: Path) -> None:
    g = Gltf("usine · visualiseur_animations · fabriquer_exemple.py")
    bois = g.materiau("bois", (130, 84, 46))
    fer = g.materiau("fer", (70, 74, 82))

    def maillage(nom: str, paves: list[tuple[Vec3, Vec3, int]]) -> int:
        primitifs = []
        for mat in sorted({m for _, _, m in paves}):
            sommets: list[Vec3] = []
            normales: list[Vec3] = []
            indices: list[int] = []
            for centre, taille, m in paves:
                if m != mat:
                    continue
                s, n, ind = pave(centre, taille)
                indices += [len(sommets) + k for k in ind]
                sommets += s
                normales += n
            primitifs.append({"attributes": {"POSITION": g.accesseur(sommets, "VEC3", 5126, 34962, bornes=True),
                                             "NORMAL": g.accesseur(normales, "VEC3", 5126, 34962)},
                              "indices": g.accesseur(indices, "SCALAR", 5123, 34963), "material": mat})
        g.doc["meshes"].append({"name": nom, "primitives": primitifs})
        return len(g.doc["meshes"]) - 1

    base = maillage("coffre_base", [((0, 0.25, 0), (1.0, 0.5, 0.6), bois), ((0, 0.25, 0.305), (0.16, 0.18, 0.02), fer)])
    # Le couvercle tourne autour de sa charnière, à l'arrière du haut de la base.
    couvercle = maillage("coffre_couvercle", [((0, 0.08, 0.3), (1.02, 0.16, 0.62), bois),
                                              ((0, 0.08, 0.615), (0.2, 0.1, 0.02), fer)])
    n_base = g.noeud(name="base", mesh=base)
    n_couvercle = g.noeud(name="couvercle", mesh=couvercle, translation=[0.0, 0.5, -0.3])
    haut = g.noeud(name="coffre", children=[n_base, n_couvercle])
    g.doc["scenes"][0]["nodes"] = [haut]

    def anim(nom: str, angles: list[tuple[float, float]]) -> dict:
        entree = g.accesseur([t for t, _ in angles], "SCALAR", 5126, bornes=True)
        sortie = g.accesseur([quat((-a, 0, 0)) for _, a in angles], "VEC4", 5126)
        return {"name": nom, "samplers": [{"input": entree, "output": sortie, "interpolation": "LINEAR"}],
                "channels": [{"sampler": 0, "target": {"node": n_couvercle, "path": "rotation"}}]}

    ouverture = [(round(0.6 * k / 18, 5), 105 * _lisse(k / 18)) for k in range(19)]
    fermeture = [(t, 105 - a) for t, a in ouverture]
    g.doc["animations"] = [anim("ferme", [(0.0, 0.0), (1.0, 0.0)]), anim("ouverture", ouverture),
                           anim("ouvert", [(0.0, 105.0), (1.0, 105.0)]), anim("fermeture", fermeture)]
    g.ecrire(chemin)


# --- animations 2D ----------------------------------------------------------------------------------------------

def image_flamme(k: int, n: int, cadre: int) -> Image.Image:
    im = Image.new("RGBA", (cadre, cadre), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    p = k / n
    for couche, (couleur, ech) in enumerate((((230, 80, 20), 1.0), ((250, 170, 40), 0.7), ((255, 240, 170), 0.4))):
        cx = cadre / 2 + math.sin(2 * math.pi * (p + couche * 0.13)) * 10 * ech
        hauteur = cadre * 0.62 * ech * (0.9 + 0.1 * math.sin(2 * math.pi * 2 * p + couche))
        largeur = cadre * 0.34 * ech
        bas = cadre * 0.86
        d.polygon([(cx - largeur / 2, bas), (cx + largeur / 2, bas),
                   (cx + largeur * 0.15, bas - hauteur * 0.6), (cx + math.sin(2 * math.pi * p) * 6, bas - hauteur),
                   (cx - largeur * 0.15, bas - hauteur * 0.6)], fill=couleur + (255,))
        d.ellipse([cx - largeur / 2, bas - largeur * 0.5, cx + largeur / 2, bas + largeur * 0.1], fill=couleur + (255,))
    return im.filter(ImageFilter.GaussianBlur(1.2))


def ecrire_flamme(dossier: Path, n: int = 12, cadre: int = 192) -> None:
    """12 images de 192 × 192, rognées et rangées en étagère dans une page, au format de l'optimiseur."""
    images = [image_flamme(k, n, cadre) for k in range(n)]
    zones, marge, page_l = [], 2, 512
    x = y = haut_ligne = 0
    for im in images:
        b = im.getbbox()
        l, h = b[2] - b[0], b[3] - b[1]
        if x + l + marge > page_l:
            x, y, haut_ligne = 0, y + haut_ligne + marge, 0
        zones.append((b, (x, y, l, h)))
        x += l + marge
        haut_ligne = max(haut_ligne, h)
    page = Image.new("RGBA", (page_l, (y + haut_ligne + 3) // 4 * 4), (0, 0, 0, 0))
    entrees = []
    for im, (b, (px, py, l, h)) in zip(images, zones):
        page.paste(im.crop(b), (px, py))
        entrees.append({"page": 0, "zone": [px, py, l, h], "decalage": [b[0], b[1]], "echelle": 1, "taille": [l, h]})
    dossier.mkdir(parents=True, exist_ok=True)
    page.save(dossier / "flamme_0.png")
    donnees = {"format": "atlas_animation", "version": 1, "melange": "normal", "pages": ["flamme_0.png"],
               "animations": {"flamme": {"ips": 12.0, "cadre": [cadre, cadre], "images": entrees}}}
    (dossier / "flamme.atlas.json").write_text(json.dumps(donnees, ensure_ascii=False, indent=1) + "\n",
                                               encoding="utf-8", newline="\n")


def ecrire_etincelle(dossier: Path, n: int = 8, cadre: int = 96) -> None:
    dossier.mkdir(parents=True, exist_ok=True)
    for k in range(n):
        im = Image.new("RGBA", (cadre, cadre), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        r = 6 + k * 5
        a = int(255 * (1 - k / n))
        for i in range(8):
            ang = 2 * math.pi * i / 8
            d.line([(cadre / 2 + math.cos(ang) * r * 0.4, cadre / 2 + math.sin(ang) * r * 0.4),
                    (cadre / 2 + math.cos(ang) * r, cadre / 2 + math.sin(ang) * r)], fill=(255, 230, 120, a), width=3)
        im.save(dossier / f"{k + 1:03d}.png")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=SOURCE_DEFAUT)
    args = parser.parse_args()
    exemple = args.source / "6_assets" / "exemple"
    exemple.mkdir(parents=True, exist_ok=True)
    (exemple / ".gdignore").write_text("", encoding="utf-8")
    ecrire_pantin(exemple / "heros" / "heros.glb", "heros",
                  squelette_bipede(1.0, 1.0, ("peau", "habit", "sombre")),
                  {"peau": (226, 186, 150), "habit": (52, 92, 170), "sombre": (40, 40, 52)}, clips_heros())
    ecrire_pantin(exemple / "ennemis" / "golem.glb", "golem",
                  squelette_bipede(1.35, 1.6, ("pierre_claire", "pierre", "mousse")),
                  {"pierre_claire": (150, 146, 138), "pierre": (104, 100, 96), "mousse": (70, 110, 60)}, clips_golem())
    ecrire_coffre(exemple / "props" / "coffre.glb")
    ecrire_flamme(exemple / "effets" / "flamme")
    ecrire_etincelle(exemple / "effets" / "etincelle")
    # Les fichiers d'accompagnement : ce que glTF et les images ne disent pas (les animations qui bouclent, la cadence
    # d'un dossier d'images). Le visualiseur les lit et les réécrit.
    accompagnements = {"heros/heros.visu.json": {"boucles": ["course", "pause"]},
                       "ennemis/golem.visu.json": {"boucles": ["marche", "pause"]},
                       "props/coffre.visu.json": {"boucles": ["ferme", "ouvert"]},
                       "effets/flamme/flamme.visu.json": {"boucles": ["flamme"]},
                       "effets/etincelle/visu.json": {"ips": 16.0}}
    for rel, donnees in accompagnements.items():
        (exemple / rel).write_text(json.dumps(donnees, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8",
                                   newline="\n")
    for f in sorted(exemple.rglob("*")):
        if f.is_file():
            print(f"{f.relative_to(args.source).as_posix()} : {f.stat().st_size} octets")


if __name__ == "__main__":
    main()
