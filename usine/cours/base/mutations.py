"""Erreurs introduites exprès dans le code d'une étape : celles qu'un modèle fait le plus souvent sous
Godot 4 (noms de Godot 3, annotations oubliées, types, appels), chacune avec l'explication juste."""
from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass
class Mutation:
    genre: str          # godot3_annotation, godot3_nom, godot3_shader, type, non_type, parametre, retour, appel,
                        # shader_litteral
    fichier: str
    ligne: int          # 1-based, dans le fichier muté
    avant: str          # ligne juste
    apres: str          # ligne fautive
    detail: dict


# Noms de Godot 3 et leur équivalent dans Godot 4 (guide « Upgrading to Godot 4 » ; vérifiés ici dans
# l'API 4.7.2 : le nom de Godot 4 existe, celui de Godot 3 n'existe plus).
RENOMS_METHODES = {
    "randf_range": "rand_range", "deg_to_rad": "deg2rad", "rad_to_deg": "rad2deg", "snappedf": "stepify",
    "is_empty": "empty", "instantiate": "instance", "set_shader_parameter": "set_shader_param",
    "get_shader_parameter": "get_shader_param",
    # Code des jeux (cours du kart et du roguelike, 2026-10-22).
    "find_child": "find_node", "get_world_3d": "get_world", "remap": "range_lerp", "limit_length": "clamped",
    "change_scene_to_file": "change_scene", "str_to_var": "str2var", "is_valid_int": "is_valid_integer",
    "get_slide_collision_count": "get_slide_count",
}
RENOMS_CLASSES = {
    "Node3D": "Spatial", "MeshInstance3D": "MeshInstance", "StandardMaterial3D": "SpatialMaterial",
    "Transform3D": "Transform", "PackedStringArray": "PoolStringArray", "PackedVector3Array": "PoolVector3Array",
    "PackedColorArray": "PoolColorArray", "PackedInt32Array": "PoolIntArray",
    # Code des jeux (cours du kart et du roguelike, 2026-10-22).
    "CharacterBody3D": "KinematicBody", "Area3D": "Area", "CollisionShape3D": "CollisionShape", "Camera3D": "Camera",
    "RigidBody3D": "RigidBody", "StaticBody3D": "StaticBody", "GPUParticles3D": "Particles", "Sprite2D": "Sprite",
    "PackedFloat32Array": "PoolRealArray", "Marker3D": "Position3D", "RayCast3D": "RayCast",
    "NavigationAgent3D": "NavigationAgent", "Shortcut": "ShortCut",
}
# Déclarations typées : une variable inférée (« := ») ou typée d'une classe, un paramètre, un type de retour. Sans
# type, l'avertissement UNTYPED_DECLARATION (traité en erreur par le projet) les signale.
VAR_TYPEE = re.compile(r"^(\s*)var (\w+)(?: := |: ((?:[A-Z]\w*|float|int|bool)(?:\[[\w, ]+\])?) = )(.+)$")
FONCTION = re.compile(r"^(\s*(?:static\s+)?func\s+(\w+)\()([^)]*)(\))(\s*->\s*[\w\[\], ]+?)(\s*:.*)$")
PARAMETRE = re.compile(r"\b(\w+): ([A-Za-z]\w*(?:\[[\w, ]+\])?)(?=\s*(?:,|$))")
RENOMS_SHADER = {"MODEL_MATRIX": "WORLD_MATRIX", "INV_VIEW_MATRIX": "CAMERA_MATRIX", "source_color": "hint_color",
                 "NORMAL_MAP": "NORMALMAP", "VIEW_MATRIX": "INV_CAMERA_MATRIX",
                 # Le reste de shaders_renames (renames_map_3_to_4.cpp, 4.7.2), pour les shaders des jeux.
                 "ALPHA_SCISSOR_THRESHOLD": "ALPHA_SCISSOR", "NORMAL_MAP_DEPTH": "NORMALMAP_DEPTH",
                 "BACKLIGHT": "TRANSMISSION", "depth_prepass_alpha": "depth_draw_alpha_prepass",
                 "hint_anisotropy": "hint_aniso", "hint_default_black": "hint_black",
                 "hint_default_white": "hint_white"}


def candidates(fichier: str, texte: str, lignes_nouvelles: set[int]) -> list[Mutation]:
    """Toutes les mutations possibles sur les lignes nouvelles de l'étape (numéros 1-based)."""
    lignes = texte.split("\n")
    sortie: list[Mutation] = []
    shader = fichier.endswith((".gdshader", ".gdshaderinc"))
    for n in sorted(lignes_nouvelles):
        l = lignes[n - 1]
        code = l.split("//", 1)[0] if shader else (l.split("#", 1)[0] if not l.strip().startswith("#") else "")
        if not code.strip():
            continue
        if not shader:
            m = re.match(r"^(\s*)@(export|onready)(\s+var\b.*)$", l)
            if m:
                sortie.append(Mutation("godot3_annotation", fichier, n, l, f"{m[1]}{m[2]}{m[3]}", {"mot": m[2]}))
            for neuf, ancien in RENOMS_METHODES.items():
                if re.search(rf"\b{neuf}\(", code):
                    sortie.append(Mutation("godot3_nom", fichier, n, l, re.sub(rf"\b{neuf}\(", ancien + "(", l, count=1),
                                           {"neuf": neuf, "ancien": ancien, "sorte": "méthode"}))
            for neuf, ancien in RENOMS_CLASSES.items():
                if re.search(rf"\b{neuf}\b", code):
                    sortie.append(Mutation("godot3_nom", fichier, n, l, re.sub(rf"\b{neuf}\b", ancien, l, count=1),
                                           {"neuf": neuf, "ancien": ancien, "sorte": "classe"}))
            m = re.match(r"^(\s*)var (\w+): (float|int|bool|Color|Vector3|Vector2|String) = (.+)$", l)
            if m and n > 0:
                sortie.append(Mutation("non_type", fichier, n, l, f"{m[1]}var {m[2]} = {m[4]}", {"nom": m[2], "type": m[3]}))
            else:
                m = VAR_TYPEE.match(l)
                if m:
                    sortie.append(Mutation("non_type", fichier, n, l, f"{m[1]}var {m[2]} = {m[4]}",
                                           {"nom": m[2], "type": m[3] or "inféré"}))
            f = FONCTION.match(l)
            if f:
                sortie.append(Mutation("retour", fichier, n, l, f[1] + f[3] + f[4] + f[6],
                                       {"nom": f[2], "type": f[5].strip()}))
                p = PARAMETRE.search(f[3])
                if p:
                    debut = len(f[1]) + p.start()
                    sortie.append(Mutation("parametre", fichier, n, l, l[:debut] + p[1] + l[debut + len(p[0]):],
                                           {"nom": p[1], "type": p[2], "fonction": f[2]}))
            m = re.match(r"^(\s*)var (\w+): float = (.+)$", l)
            if m and re.search(r"\d\.\d|randf|float\(|_range\(|\*|/", m[3]):
                sortie.append(Mutation("type", fichier, n, l, f"{m[1]}var {m[2]}: int = {m[3]}", {"nom": m[2]}))
        else:
            for neuf, ancien in RENOMS_SHADER.items():
                if re.search(rf"\b{neuf}\b", code):
                    sortie.append(Mutation("godot3_shader", fichier, n, l, re.sub(rf"\b{neuf}\b", ancien, l, count=1),
                                           {"neuf": neuf, "ancien": ancien}))
            # Une déclaration float qui reçoit une valeur décimale, écrite int : le shader ne convertit pas.
            d = re.match(r"^(\s*(?:const\s+|uniform\s+)?)float(\s+(\w+)\b[^=;]*=\s*)([^;]*\d\.\d[^;]*);", l)
            if d:
                sortie.append(Mutation("shader_type", fichier, n, l, l.replace(d[0], f"{d[1]}int{d[2]}{d[4]};", 1),
                                       {"nom": d[3]}))
            m = re.search(r"(?<![\w.])(\d+)\.0\b", code)
            if m and m[1] != "0":
                debut, fin = m.span()
                sortie.append(Mutation("shader_litteral", fichier, n, l, l[:debut] + m[1] + l[fin:],
                                       {"litteral": m[0], "entier": m[1]}))
    return sortie


def appels_internes(fichier: str, texte: str, lignes_nouvelles: set[int]) -> list[Mutation]:
    """Un appel à une fonction du script, renommé : la fonction appelée n'existe pas."""
    lignes = texte.split("\n")
    definies = set(re.findall(r"^(?:static )?func (\w+)\(", texte, re.M))
    sortie = []
    for n in sorted(lignes_nouvelles):
        l = lignes[n - 1]
        if l.lstrip().startswith(("func ", "static func ", "#")):
            continue
        for f in re.findall(r"(?<![.\w])(_\w+)\(", l):
            if f in definies:
                faux = f + "_choix" if not f.endswith("s") else f[:-1]
                sortie.append(Mutation("appel", fichier, n, l, l.replace(f + "(", faux + "(", 1),
                                       {"neuf": f, "ancien": faux}))
                break
    return sortie
