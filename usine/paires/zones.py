"""Couverture des paires par zone de Godot (critique du 2026-11-18, point 6 : « Auditer la diversité par zone, pas par
nombre »). Une paire touche une zone quand sa demande ou sa réponse en emploie les marques ; une paire peut en toucher
plusieurs. Déterministe : des motifs, aucun jugement.

    python -m usine.paires zones
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from usine import config as cfg

ZONES: dict[str, re.Pattern[str]] = {
    "project.godot": re.compile(r"project\.godot|config_version|run/main_scene|\[application\]"),
    "autoload": re.compile(r"\[autoload\]|\bautoload"),
    "InputMap": re.compile(r"\bInputMap\b|\[input\]|is_action_(?:just_)?(?:pressed|released)|\bget_vector\("),
    "class_name": re.compile(r"^class_name\s|\bclass_name\b", re.M),
    "scène .tscn": re.compile(r"\[gd_scene|\[node name=|\[ext_resource|\.tscn\b"),
    "ressource .tres": re.compile(r"\[gd_resource|\.tres\b"),
    "signaux": re.compile(r"\bsignal\s+\w+|\.connect\(|\.emit\("),
    "physique": re.compile(r"CharacterBody[23]D|RigidBody[23]D|move_and_slide|PhysicsDirectSpaceState|"
                           r"collision_(?:layer|mask)|Area[23]D|RayCast[23]D|ShapeCast"),
    "particules": re.compile(r"GPUParticles[23]D|CPUParticles[23]D|ParticleProcessMaterial"),
    "UI": re.compile(r"\b(?:Control|Label|Button|Container|VBoxContainer|HBoxContainer|ItemList|Tree|"
                     r"RichTextLabel|LineEdit|TextureRect|Panel)\b|focus_neighbor"),
    "animation": re.compile(r"AnimationPlayer|AnimationTree|\bTween\b|create_tween|\bAnimation\b"),
    "sauvegarde": re.compile(r"ConfigFile|FileAccess|user://|ResourceSaver|DirAccess"),
    "shaders": re.compile(r"shader_type|\.gdshader|ShaderMaterial|uniform\s"),
    "audio": re.compile(r"AudioStreamPlayer|AudioServer|\bbus\b"),
    "maillages": re.compile(r"ArrayMesh|SurfaceTool|MeshInstance3D|MultiMesh"),
    "caméra": re.compile(r"Camera[23]D|SpringArm3D"),
    "tests GdUnit4": re.compile(r"GdUnitTestSuite|assert_(?:int|float|bool|str|that|object|array|vector)"),
}


def zones(p: dict[str, Any]) -> set[str]:
    texte = "\n".join((m.get("content") or "") + json.dumps(m.get("tool_calls") or "", ensure_ascii=False)
                      for m in p["messages"] if m["role"] != "system")
    return {z for z, motif in ZONES.items() if motif.search(texte)}


def compter(racine: Path | None = None) -> dict[str, Any]:
    from usine.paires import assembler
    racine = Path(racine or cfg.dossier_donnees()) / "paires"
    total: dict[int, int] = {1: 0, 2: 0}
    par_zone: dict[str, dict[int, int]] = {z: {1: 0, 2: 0} for z in ZONES}
    for p in assembler.lire_familles(racine):
        n, _ = assembler.palier(p)
        if n is None:
            continue
        total[n] += 1
        for z in zones(p):
            par_zone[z][n] += 1
    return {"total": total, "par_zone": par_zone}
