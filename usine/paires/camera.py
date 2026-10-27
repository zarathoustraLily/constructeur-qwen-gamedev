"""Famille « situer la caméra et les objets » (étape A8 du suivi).

Origine : un vrai débogage du roguelike de laurent (2026-10-26) ; la caméra, à 12 m au-dessus du joueur et sans
rotation, regardait l'horizon ; Qwen a cherché du côté de la fenêtre au lieu de situer la caméra et les objets.

Chaque cas part d'un niveau généré d'après une graine (sol, caisses, piliers, bancs, joueur avec son modèle, pivot de
caméra et caméra ; caméra de dessus orthographique inclinée, ou en perspective). Le niveau sain est rendu par
`voir_scene` : la caméra doit y voir le joueur et tous les objets, sinon le niveau est rejeté. Puis un défaut est posé
par une seule édition du `.tscn` (texte unique, règle 5.7) ; la scène fautive est rendue et doit montrer le symptôme
attendu, lu dans les mesures du moteur (et non supposé) ; la correction est l'édition inverse, déjà vérifiée par le
rendu sain. La vérité vient donc de Godot (décision 18.1) ; les réponses sont écrites par le générateur d'après ces
mesures (décision 19.3).

Paires (palier 1, 1 024 jetons au plus, sans plan : le plan n'y joue aucun rôle, exception de la section 3) :
- analyse : la sortie de `voir_scene` d'un niveau sain → où est la caméra, où elle regarde, ce qu'elle voit ;
- débogage : un symptôme, la sortie de `voir_scene` et l'extrait de la scène → ce que montre la carte, la cause, le
  texte à remplacer (la faute n'apparaît que là, règle 7.3) et ce que doit montrer le rendu suivant.

    python -m usine.paires camera [--niveaux N] [--graine G] [--paires P]
"""

from __future__ import annotations

import json
import math
import random
import shutil
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from usine.paires import format as fmt
from usine.retour import vues

FAMILLE = "situer_camera"
SUJET = "graphisme 3D"
SCENE = "res://niveau.tscn"
VUES = ["jeu", "cote", "dessus"]


# ------------------------------------------------------------------ niveaux

@dataclass
class Niveau:
    graine: int
    style: str  # "dessus" (orthographique incliné) ou "perspective"
    inclinaison: float  # en radians, vers le bas
    distance: float
    objets: list[dict[str, Any]] = field(default_factory=list)  # nom, genre, position, hauteur
    reglage: str = ""  # ligne de projection : « projection = 1\nsize = … » ou « fov = … »

    @property
    def rotation_pivot(self) -> str:
        return f"rotation = Vector3({-self.inclinaison:.6f}, 0, 0)"

    @property
    def position_camera(self) -> tuple[float, float, float]:
        return (0.0, self.distance * math.sin(self.inclinaison), self.distance * math.cos(self.inclinaison))


GENRES = {  # genre : (ressource, hauteur)
    "Caisse": ("BoxMesh_caisse", 1.0),
    "Pilier": ("CylinderMesh_pilier", 2.0),
    "Banc": ("BoxMesh_banc", 0.5),
}


def niveau(graine: int) -> Niveau:
    rng = random.Random(graine)
    style = ("dessus", "perspective")[graine % 2]
    if style == "dessus":
        n = Niveau(graine, style, math.radians(rng.choice([50, 55, 60, 65])), 20.0)
    else:
        n = Niveau(graine, style, math.radians(rng.choice([30, 35, 40])), rng.choice([10.0, 12.0]))
    cote = rng.choice([8, 10, 12])
    n.objets.append({"nom": "Sol", "genre": "Sol", "position": (0.0, -0.1, 0.0), "hauteur": 0.2, "cote": cote})
    places: list[tuple[float, float]] = [(0.0, 0.0)]
    # Peu d'objets : la sortie réelle de voir_scene tient dans 1 024 jetons. Avec 4, les paires de débogage des
    # défauts au long extrait (autre caméra, modèle couché, objet derrière) dépassaient : mesuré le 2026-10-27.
    for k in range(rng.randint(2, 3)):
        genre = rng.choice(sorted(GENRES))
        for _ in range(50):
            x = rng.randint(-(cote // 2 - 1), cote // 2 - 1)
            z = rng.randint(-(cote // 2 - 1), cote // 2 - 1)
            if all(abs(x - a) + abs(z - b) >= 3 for a, b in places):
                break
        places.append((x, z))
        h = GENRES[genre][1]
        n.objets.append({"nom": f"{genre}{k + 1}", "genre": genre, "position": (float(x), h / 2, float(z)),
                         "hauteur": h})
    if style == "dessus":
        n.reglage = f"projection = 1\nsize = {cote * 1.3:.1f}"
    else:
        n.reglage = "fov = 70.0"
    return n


def _v(v: tuple[float, float, float]) -> str:
    return "Vector3(" + ", ".join(f"{x:g}" for x in v) + ")"


def scene(n: Niveau) -> str:
    sol = next(o for o in n.objets if o["genre"] == "Sol")
    blocs = [
        "[gd_scene format=3]",
        f'[sub_resource type="BoxMesh" id="BoxMesh_sol"]\nsize = Vector3({sol["cote"]}, 0.2, {sol["cote"]})',
        '[sub_resource type="BoxMesh" id="BoxMesh_caisse"]',
        '[sub_resource type="CylinderMesh" id="CylinderMesh_pilier"]\ntop_radius = 0.5\nbottom_radius = 0.5',
        '[sub_resource type="BoxMesh" id="BoxMesh_banc"]\nsize = Vector3(2, 0.5, 0.6)',
        '[sub_resource type="CapsuleMesh" id="CapsuleMesh_corps"]\nradius = 0.35\nheight = 1.2',
        '[sub_resource type="SphereMesh" id="SphereMesh_tete"]\nradius = 0.22\nheight = 0.44',
        '[node name="Niveau" type="Node3D"]',
        '[node name="Soleil" type="DirectionalLight3D" parent="."]\nrotation = Vector3(-0.9, 0.6, 0)',
        f'[node name="Sol" type="MeshInstance3D" parent="."]\nposition = {_v(sol["position"])}\n'
        'mesh = SubResource("BoxMesh_sol")',
    ]
    for o in n.objets:
        if o["genre"] != "Sol":
            blocs.append(f'[node name="{o["nom"]}" type="MeshInstance3D" parent="."]\nposition = {_v(o["position"])}\n'
                         f'mesh = SubResource("{GENRES[o["genre"]][0]}")')
    blocs += [
        '[node name="Joueur" type="Node3D" parent="."]',
        '[node name="Modele" type="Node3D" parent="Joueur"]',
        '[node name="Corps" type="MeshInstance3D" parent="Joueur/Modele"]\nposition = Vector3(0, 0.6, 0)\n'
        'mesh = SubResource("CapsuleMesh_corps")',
        '[node name="Tete" type="MeshInstance3D" parent="Joueur/Modele"]\nposition = Vector3(0, 1.42, 0)\n'
        'mesh = SubResource("SphereMesh_tete")',
        f'[node name="Pivot" type="Node3D" parent="Joueur"]\n{n.rotation_pivot}',
        f'[node name="Camera3D" type="Camera3D" parent="Joueur/Pivot"]\nposition = Vector3(0, 0, {n.distance:g})\n'
        f'{n.reglage}',
    ]
    return "\n\n".join(blocs) + "\n"


def bloc(texte: str, nom: str) -> str:
    """Le bloc d'un nœud dans le texte de la scène (de son en-tête à la ligne vide)."""
    debut = texte.index(f'[node name="{nom}"')
    fin = texte.find("\n\n", debut)
    return texte[debut:fin if fin >= 0 else len(texte)].rstrip("\n")


# ------------------------------------------------------------------ défauts

@dataclass
class Defaut:
    nom: str
    symptome: str
    styles: tuple[str, ...]
    editer: Callable[[Niveau, str], tuple[str, str]]  # (texte sain, texte fautif)
    verifier: Callable[[dict[str, Any], Niveau], bool]  # le symptôme dans les mesures du rendu fautif
    cause: Callable[[dict[str, Any], Niveau], str]
    blocs: Callable[[Niveau], list[str]]  # nœuds à montrer dans l'extrait de la scène


def _objet(d: dict[str, Any], nom: str) -> dict[str, Any] | None:
    return next((o for o in d.get("objets", []) if o["nom"] == nom), None)


def _hors(d: dict[str, Any], nom: str, raison: str | None = None) -> bool:
    o = _objet(d, nom)
    return o is not None and not o.get("dans_le_champ", True) and (raison is None or raison in o["hors_champ"])


def _cible(n: Niveau) -> str:
    """L'objet qui reçoit les défauts d'objet : le premier qui n'est pas le sol."""
    return next(o["nom"] for o in n.objets if o["genre"] != "Sol")


def _pivot(n: Niveau) -> str:
    return f'[node name="Pivot" type="Node3D" parent="Joueur"]\n{n.rotation_pivot}'


def _camera(n: Niveau) -> str:
    return f'[node name="Camera3D" type="Camera3D" parent="Joueur/Pivot"]\nposition = Vector3(0, 0, {n.distance:g})'


def _objet_bloc(n: Niveau, nom: str) -> str:
    o = next(x for x in n.objets if x["nom"] == nom)
    return f'[node name="{nom}" type="MeshInstance3D" parent="."]\nposition = {_v(o["position"])}'


def _direction(v: list[float]) -> str:
    return vues._direction(v)


def _cap(v: list[float]) -> str:
    """La visée projetée sur le sol, en mots (haut de la carte = -Z)."""
    x, z = v[0], v[2]
    if abs(x) + abs(z) < 0.1:
        return "verticale"
    if abs(z) >= abs(x):
        return "vers -Z (le haut de la carte)" if z < 0 else "vers +Z (le bas de la carte)"
    return "vers +X (la droite de la carte)" if x > 0 else "vers -X (la gauche de la carte)"


CAMERA = ["Joueur", "Modele", "Pivot", "Camera3D"]

DEFAUTS = [
    Defaut(
        # Le bug réel du roguelike de laurent : caméra posée en hauteur, sans aucune rotation.
        "inclinaison_absente", "La 3D ne s'affiche pas : l'écran montre le fond et le HUD, rien d'autre.", ("dessus",),
        lambda n, t: (_pivot(n) + "\n\n" + _camera(n),
                      '[node name="Pivot" type="Node3D" parent="Joueur"]\n\n'
                      '[node name="Camera3D" type="Camera3D" parent="Joueur/Pivot"]\n'
                      f"position = {_v(tuple(round(c, 2) for c in n.position_camera))}"),
        lambda d, n: abs(d["camera"]["regarde_vers"][1]) < 0.1 and _hors(d, "Corps"),
        lambda d, n: (f"ni le pivot ni la caméra n'ont de rotation : la caméra, posée à {d['camera']['position'][1]:g} m "
                      "de haut, garde la visée par défaut d'une Camera3D, vers -Z, à l'horizontale ; le niveau est "
                      f"sous son champ. Il faut incliner le pivot de {math.degrees(n.inclinaison):.0f}° vers le bas "
                      "(rotation négative autour de X) et reculer la caméra le long de son axe"),
        lambda n: ["Pivot", "Camera3D"]),
    Defaut(
        "visee_vers_le_haut", "La caméra ne montre que le fond, le niveau n'apparaît jamais.", ("dessus", "perspective"),
        lambda n, t: (_camera(n), _camera(n) + f"\nrotation = Vector3({2 * n.inclinaison:.6f}, 0, 0)"),
        lambda d, n: d["camera"]["regarde_vers"][1] > 0.3 and _hors(d, "Corps"),
        lambda d, n: (f"la caméra a sa propre rotation de {2 * n.inclinaison:.6f} rad autour de X : elle annule "
                      f"l'inclinaison du pivot ({-n.inclinaison:.6f} rad) et tourne la caméra vers le haut, vers le "
                      "ciel ; sans cette rotation, la caméra suit le pivot, inclinée vers le joueur"),
        lambda n: ["Pivot", "Camera3D"]),
    Defaut(
        "camera_sous_le_sol", "Écran vide : ni le sol ni le joueur ne s'affichent.", ("dessus", "perspective"),
        lambda n, t: (_pivot(n), f'[node name="Pivot" type="Node3D" parent="Joueur"]\nposition = Vector3(0, -30, 0)\n'
                                 f"{n.rotation_pivot}"),
        lambda d, n: d["camera"]["position"][1] < 0 and _hors(d, "Corps"),
        lambda d, n: (f"le pivot est descendu à y = -30 : la caméra se trouve à y = {d['camera']['position'][1]:g}, "
                      "sous le sol, et le niveau est au-dessus de son champ. Le pivot doit rester à hauteur du joueur"),
        lambda n: ["Pivot", "Camera3D"]),
    Defaut(
        "far_trop_court", "Le niveau ne s'affiche pas, alors que la caméra est bien placée.", ("dessus", "perspective"),
        lambda n, t: (_camera(n), _camera(n) + "\nfar = 2.0"),
        lambda d, n: _hors(d, "Corps", "lointain (far)"),
        lambda d, n: (f"`far = 2.0` : la caméra ne dessine rien au-delà de 2 m, or le joueur est à "
                      f"{_objet(d, 'Corps')['distance']:g} m d'elle ; sans `far`, la valeur par défaut (4000) suffit"),
        lambda n: ["Pivot", "Camera3D"]),
    Defaut(
        "near_trop_loin", "Rien ne s'affiche à l'écran, sauf le fond.", ("dessus", "perspective"),
        lambda n, t: (_camera(n), _camera(n) + "\nnear = 60.0"),
        lambda d, n: _hors(d, "Corps", "plus près que near"),
        lambda d, n: (f"`near = 60.0` : la caméra ne dessine rien à moins de 60 m, or tout le niveau est plus près "
                      f"(le joueur à {_objet(d, 'Corps')['distance']:g} m) ; sans `near`, la valeur par défaut (0,05) "
                      "convient"),
        lambda n: ["Pivot", "Camera3D"]),
    Defaut(
        "champ_trop_etroit", "On ne voit qu'un petit bout du niveau, le reste manque.", ("dessus",),
        lambda n, t: ("projection = 1\nsize = " + n.reglage.split("size = ")[1], "projection = 1\nsize = 0.5"),
        lambda d, n: sum(o.get("dans_le_champ", False) for o in d["objets"]) <= 3 and any(
            set(o.get("hors_champ", [])) & {"gauche", "droite", "haut", "bas"} for o in d["objets"]),
        lambda d, n: ("`size = 0.5` : en orthographique, `size` est la hauteur du champ en mètres ; 0,5 m ne montre "
                      f"que le centre de l'image. Il faut couvrir le niveau ({n.reglage.split('size = ')[1]} m)"),
        lambda n: ["Camera3D"]),
    Defaut(
        "fov_trop_etroit", "On ne voit qu'un petit bout du niveau, le reste manque.", ("perspective",),
        lambda n, t: ("fov = 70.0", "fov = 2.0"),
        lambda d, n: sum(o.get("dans_le_champ", False) for o in d["objets"]) <= 3 and any(
            set(o.get("hors_champ", [])) & {"gauche", "droite", "haut", "bas"} for o in d["objets"]),
        lambda d, n: ("`fov = 2.0` : l'angle de vue n'est que de 2° ; la caméra ne voit qu'un point du niveau. "
                      "70° couvre le niveau"),
        lambda n: ["Camera3D"]),
    Defaut(
        "cull_mask_sans_la_couche", "La caméra ne montre aucun objet du niveau.", ("dessus", "perspective"),
        lambda n, t: (_camera(n), _camera(n) + "\ncull_mask = 1048574"),
        lambda d, n: _hors(d, "Corps", "couche exclue par cull_mask"),
        lambda d, n: ("`cull_mask = 1048574` retire la couche 1 (valeur 1) de ce que dessine la caméra ; tous les "
                      "objets sont sur la couche 1 (`layers` par défaut). Sans `cull_mask`, la caméra voit les 20 "
                      "couches"),
        lambda n: ["Camera3D"]),
    Defaut(
        "autre_camera_courante", "Le jeu montre une vue vide au lieu du niveau.", ("dessus", "perspective"),
        lambda n, t: ('[node name="Joueur" type="Node3D" parent="."]',
                      '[node name="CameraDebug" type="Camera3D" parent="."]\nposition = Vector3(0, 2, 40)\n'
                      'rotation = Vector3(0, 3.14159, 0)\ncurrent = true\n\n[node name="Joueur" type="Node3D" parent="."]'),
        lambda d, n: d["camera"]["chemin"].endswith("CameraDebug") and _hors(d, "Corps"),
        # Retirer seulement `current = true` ne suffit pas (mesuré le 2026-10-27, sur les deux styles) : CameraDebug
        # reste courante. Référence de Camera3D.current : « one will always be made current ».
        lambda d, n: ("la caméra courante n'est pas celle du joueur mais `CameraDebug` (`current = true`), posée en "
                      "(0, 2, 40) et tournée vers +Z, à l'opposé du niveau. Retirer `current = true` ne suffit pas : "
                      "avec plusieurs caméras, l'une est toujours courante, et ce reste `CameraDebug`. Il faut retirer "
                      "le nœud `CameraDebug`"),
        lambda n: ["CameraDebug", "Pivot", "Camera3D"]),
    Defaut(
        "modele_couche", "Le joueur apparaît couché au sol au lieu d'être debout.", ("dessus", "perspective"),
        lambda n, t: ('[node name="Modele" type="Node3D" parent="Joueur"]',
                      '[node name="Modele" type="Node3D" parent="Joueur"]\nrotation = Vector3(-1.570796, 0, 0)'),
        lambda d, n: (_objet(d, "Corps") or {"taille": [0, 1, 0]})["taille"][1] < (_objet(d, "Corps") or {
            "taille": [0, 0, 1]})["taille"][2],
        lambda d, n: (f"le corps mesure {_objet(d, 'Corps')['taille'][1]:g} m de haut pour "
                      f"{_objet(d, 'Corps')['taille'][2]:g} m de long, la tête est à côté du corps et non au-dessus : "
                      "`Modele` est tourné de -90° autour de X, il est couché ; sans cette rotation, il est debout"),
        lambda n: ["Modele", "Corps", "Tete"]),
    Defaut(
        "objet_sous_le_sol", "Un objet du niveau a disparu.", ("dessus", "perspective"),
        lambda n, t: (_objet_bloc(n, _cible(n)), _objet_bloc(n, _cible(n)).replace(
            "position = " + _v(next(o for o in n.objets if o["nom"] == _cible(n))["position"]),
            "position = " + _v((next(o for o in n.objets if o["nom"] == _cible(n))["position"][0], -2.5,
                                next(o for o in n.objets if o["nom"] == _cible(n))["position"][2])))),
        lambda d, n: (o := _objet(d, _cible(n))) is not None and o["centre"][1] + o["taille"][1] / 2 < 0,
        lambda d, n: (f"`{_cible(n)}` est dans le champ de la caméra mais sous le sol : son centre est à y = "
                      f"{_objet(d, _cible(n))['centre'][1]:g} et son sommet à y = "
                      f"{_objet(d, _cible(n))['centre'][1] + _objet(d, _cible(n))['taille'][1] / 2:g}, sous le dessus "
                      "du sol (y = 0) qui le cache ; il doit être posé sur le sol"),
        lambda n: [_cible(n)]),
    Defaut(
        "objet_cache", "Un objet du niveau a disparu.", ("dessus", "perspective"),
        lambda n, t: (_objet_bloc(n, _cible(n)), _objet_bloc(n, _cible(n)) + "\nvisible = false"),
        lambda d, n: any(c.endswith("/" + _cible(n)) for c in d.get("caches", [])),
        lambda d, n: (f"`{_cible(n)}` est dans la liste des objets cachés : `visible = false` ; sans cette ligne, il "
                      "s'affiche"),
        lambda n: [_cible(n)]),
    Defaut(
        "objet_derriere_la_camera", "Un objet du niveau n'apparaît pas à l'écran.", ("dessus", "perspective"),
        lambda n, t: (_objet_bloc(n, _cible(n)), _objet_bloc(n, _cible(n)).replace(
            "position = " + _v(next(o for o in n.objets if o["nom"] == _cible(n))["position"]),
            "position = " + _v(tuple(round(c + 3 * u, 2) for c, u in zip(
                n.position_camera, (0.0, math.sin(n.inclinaison), math.cos(n.inclinaison))))))),
        lambda d, n: _hors(d, _cible(n), "derrière la caméra"),
        # La position et la visée de la caméra sont dans la ligne qui précède la cause : pas de redite.
        lambda d, n: (f"`{_cible(n)}` est en {vues._f(_objet(d, _cible(n))['centre'])}, derrière la caméra, du mauvais "
                      "côté de son plan proche. Il doit être posé dans le niveau, devant elle"),
        lambda n: [_cible(n), "Pivot", "Camera3D"]),
]


# ------------------------------------------------------------------ rendus et vérification

def rendre(texte: str, travail: Path) -> dict[str, Any]:
    """`voir_scene` sur un petit projet qui ne contient que cette scène."""
    projet = travail / "projet"
    if projet.exists():
        shutil.rmtree(projet)
    projet.mkdir(parents=True)
    (projet / "project.godot").write_text(
        f'config_version=5\n\n[application]\n\nrun/main_scene="{SCENE}"\nconfig/features=PackedStringArray("4.7")\n',
        encoding="utf-8")
    (projet / "niveau.tscn").write_text(texte, encoding="utf-8")
    return vues.voir(projet, image=10, vues=VUES, sortie=travail / "vues")


def niveau_sain(d: dict[str, Any]) -> bool:
    return bool(d.get("camera")) and all(o.get("dans_le_champ") for o in d["objets"])


@dataclass
class Cas:
    niveau: Niveau
    defaut: Defaut | None
    sain: str
    fautif: str | None
    rendu_sain: dict[str, Any]
    rendu_fautif: dict[str, Any] | None
    edition: tuple[str, str] | None  # (texte fautif, texte correct)


def cas_du_niveau(graine: int, travail: Path) -> tuple[list[Cas], list[str]]:
    """Le niveau sain, puis chaque défaut applicable, rendus et vérifiés. Rend les cas retenus et les rejets."""
    n = niveau(graine)
    sain = scene(n)
    r = rendre(sain, travail)
    if not r["ok"] or not niveau_sain(r["donnees"]):
        return [], [f"graine {graine} : niveau sain non conforme ({r.get('erreur') or 'objet hors champ'})"]
    retenus = [Cas(n, None, sain, None, r, None, None)]
    rejets = []
    for defaut in DEFAUTS:
        if n.style not in defaut.styles:
            continue
        correct, faux = defaut.editer(n, sain)
        if sain.count(correct) != 1:
            rejets.append(f"graine {graine}, {defaut.nom} : texte à remplacer absent ou répété")
            continue
        fautif = sain.replace(correct, faux)
        rf = rendre(fautif, travail)
        if not rf["ok"] or not defaut.verifier(rf["donnees"], n):
            rejets.append(f"graine {graine}, {defaut.nom} : symptôme absent du rendu "
                          f"({rf.get('erreur') or 'mesures non conformes'})")
            continue
        retenus.append(Cas(n, defaut, sain, fautif, r, rf, (faux, correct)))
    return retenus, rejets


# ------------------------------------------------------------------ paires

def _carte(r: dict[str, Any]) -> str:
    """La sortie de voir_scene sans la carte en caractères ni la légende des images : la paire courte n'a pas
    d'image (les paires de 2 048 jetons, avec image, garderont tout)."""
    texte = vues.carte(r["donnees"], VUES, plan=False)
    erreurs = [l for l in r.get("erreurs", []) if l.startswith(("ERROR", "SCRIPT ERROR"))][:3]
    return texte + (("\nerreurs de la partie : " + " | ".join(erreurs)) if erreurs else "")


def _liste(noms: list[str]) -> str:
    return ", ".join(noms[:-1]) + " et " + noms[-1] if len(noms) > 1 else (noms[0] if noms else "aucun")


def paire_analyse(c: Cas) -> dict[str, Any]:
    d = c.rendu_sain["donnees"]
    cam = d["camera"]
    proj = (f"orthographique, d'un champ de {cam['size']:g} m de haut" if cam["projection"] == "orthographique"
            else f"en perspective, angle de vue {cam['fov']:g}°")
    noms = [o["nom"] for o in d["objets"]]
    corps = _objet(d, "Corps")
    demande = (f"Voici la sortie de voir_scene pour {SCENE}. Où est la caméra, où regarde-t-elle, et que voit-elle ?"
               f"\n\n{_carte(c.rendu_sain)}")
    reponse = (f"La caméra du jeu, `{cam['chemin'].removeprefix('/root/')}`, est en {vues._f(cam['position'])} et "
               f"regarde vers {vues._f(cam['regarde_vers'])} : {_direction(cam['regarde_vers'])}, "
               f"{_cap(cam['regarde_vers'])}. Elle est {proj}.\n"
               f"Ses {len(noms)} objets visibles sont tous dans son champ : {_liste(noms)}. Rien n'est hors champ.\n"
               f"Le joueur (`Corps`, `Tete`) est à {corps['distance']:g} m d'elle, à l'écran en "
               f"{tuple(corps['ecran'])}.")
    return fmt.paire(FAMILLE, SUJET, "analyse", demande, reponse,
                     {"outil": "voir_scene", "graine": c.niveau.graine, "style": c.niveau.style,
                      "dans_le_champ": len(noms)})


def _vu(d: dict[str, Any]) -> str:
    cam = d["camera"]
    dedans = [o["nom"] for o in d["objets"] if o.get("dans_le_champ")]
    return (f"La caméra courante, `{cam['chemin'].removeprefix('/root/')}`, est en {vues._f(cam['position'])} et "
            f"regarde vers {vues._f(cam['regarde_vers'])} ({_direction(cam['regarde_vers'])}) ; "
            f"{len(dedans)} objet(s) sur {len(d['objets'])} dans son champ.")


def paire_diagnostic(c: Cas) -> dict[str, Any]:
    """Analyse d'un cas fautif : situer la caméra et les objets, dire la cause, sans écrire la correction."""
    assert c.defaut and c.rendu_fautif
    d = c.rendu_fautif["donnees"]
    demande = (f"{c.defaut.symptome} Voici la sortie de voir_scene pour {SCENE}. Où sont la caméra et les objets, "
               f"et pourquoi ?\n\n{_carte(c.rendu_fautif)}")
    reponse = f"{_vu(d)}\nCause : {c.defaut.cause(d, c.niveau)}."
    return fmt.paire(FAMILLE, SUJET, "analyse", demande, reponse,
                     {"outil": "voir_scene", "graine": c.niveau.graine, "style": c.niveau.style,
                      "defaut": c.defaut.nom, "symptome_mesure": True})


def paire_debogage(c: Cas) -> dict[str, Any]:
    assert c.defaut and c.rendu_fautif and c.edition and c.fautif
    d = c.rendu_fautif["donnees"]
    extrait = "\n\n".join(bloc(c.fautif, nom) for nom in c.defaut.blocs(c.niveau))
    demande = (f"{c.defaut.symptome}\n\nSortie de voir_scene :\n\n{_carte(c.rendu_fautif)}\n\n"
               f"Extrait de {SCENE} :\n```\n{extrait}\n```")
    apres = c.rendu_sain["donnees"]
    reponse = (f"{_vu(d)}\nCause : {c.defaut.cause(d, c.niveau)}.\n\nDans {SCENE}, remplacer :\n```\n{c.edition[0]}\n```\n"
               f"par :\n```\n{c.edition[1]}\n```\n"
               f"Puis relancer voir_scene : la caméra doit regarder {_direction(apres['camera']['regarde_vers'])} et "
               f"les {len(apres['objets'])} objets être dans son champ.")
    return fmt.paire(FAMILLE, SUJET, "débogage", demande, reponse,
                     {"outil": "voir_scene", "graine": c.niveau.graine, "style": c.niveau.style,
                      "defaut": c.defaut.nom, "symptome_mesure": True, "correction_mesuree": True})


def generer(niveaux: int, graine: int = 1, donnees: Path | None = None,
            journal: Callable[[str], None] = print, cible: int | None = None) -> dict[str, Any]:
    """`niveaux` niveaux au plus ; avec `cible`, on s'arrête au niveau qui l'atteint. Les niveaux restent complets :
    couper le dernier retirerait les défauts de fin de liste, chaque défaut doit peser autant."""
    sortie = fmt.dossier(FAMILLE, donnees)
    paires: list[dict[str, Any]] = []
    rejets: list[str] = []
    faits = 0
    with tempfile.TemporaryDirectory(prefix="usine_camera_") as tmp:
        for g in range(graine, graine + niveaux):
            cas, rej = cas_du_niveau(g, Path(tmp))
            rejets += rej
            faits += 1
            for c in cas:
                paires += [paire_analyse(c)] if c.defaut is None else [paire_diagnostic(c), paire_debogage(c)]
            journal(f"graine {g} : {len(cas)} cas retenus, {len(rej)} rejetés")
            if cible is not None and sum(p["jetons"] <= 1024 for p in paires) >= cible:
                break
    trop_longues = [p for p in paires if p["jetons"] > 1024]
    retenues = [p for p in paires if p["jetons"] <= 1024]
    fmt.ecrire(retenues, sortie / "paires.jsonl")
    bilan = {"niveaux": faits, "graine": graine, "paires": len(retenues), "trop_longues": len(trop_longues),
             "rejets": rejets, "par_type": {t: sum(p["type"] == t for p in retenues) for t in fmt.TYPES},
             "par_defaut": {}, "jetons_max": max((p["jetons"] for p in paires), default=0),
             "jetons_moyens": round(sum(p["jetons"] for p in paires) / max(len(paires), 1))}
    bilan["trop_longues_par_defaut"] = {}
    for cle_bilan, liste in (("par_defaut", retenues), ("trop_longues_par_defaut", trop_longues)):
        for p in liste:
            cle = p["preuve"].get("defaut", "aucun (analyse)")
            bilan[cle_bilan][cle] = bilan[cle_bilan].get(cle, 0) + 1
    (sortie / "bilan.json").write_text(json.dumps(bilan, indent=1, ensure_ascii=False), encoding="utf-8")
    return bilan
