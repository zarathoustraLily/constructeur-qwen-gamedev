"""Cinq specs de scène générées pour la preuve de l'écrivain (dans le projet de référence).

Elles couvrent ce que les scènes de référence n'ont pas : interface (Control, surcharges de
thème), 3D (Transform3D, ressources internes imbriquées), connexions avec binds/unbinds/flags,
instances avec surcharge de variables de script, groupes, metadata typées, texte multiligne.
Chaque type, propriété, signal et méthode employé existe dans extension_api.json ou dans les
scripts de godot/reference (valider_spec le vérifie).
"""

from __future__ import annotations

from typing import Any

DOSSIER = "res://scenes/generees"


def specs_generees() -> list[dict[str, Any]]:
    return [
        {
            "spec": 1,
            "chemin": f"{DOSSIER}/menu_pause.tscn",
            "racine": {
                "nom": "MenuPause", "type": "Control",
                "proprietes": {"layout_mode": 3, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
                               "grow_horizontal": 2, "grow_vertical": 2},
                "groupes": ["interface", "pause"],
                "enfants": [
                    {"nom": "Fond", "type": "ColorRect",
                     "proprietes": {"layout_mode": 1, "anchors_preset": 15, "anchor_right": 1.0,
                                    "anchor_bottom": 1.0, "color": {"Color": [0, 0, 0, 0.6]}}},
                    {"nom": "Colonne", "type": "VBoxContainer",
                     "proprietes": {"layout_mode": 1, "offset_left": 220, "offset_top": 100,
                                    "offset_right": 420, "offset_bottom": 260,
                                    "theme_override_constants/separation": 12},
                     "enfants": [
                         {"nom": "Titre", "type": "Label",
                          "proprietes": {"layout_mode": 2, "theme_override_colors/font_color": {"Color": [1, 0.85, 0.2, 1]},
                                         "theme_override_font_sizes/font_size": 24,
                                         "text": "Pause\n« Échap » pour \"reprendre\"", "horizontal_alignment": 1}},
                         {"nom": "Reprendre", "type": "Button",
                          "proprietes": {"layout_mode": 2, "text": "Reprendre", "unique_name_in_owner": True}},
                         {"nom": "Quitter", "type": "Button", "proprietes": {"layout_mode": 2, "text": "Quitter"}},
                     ]},
                ],
            },
            "connexions": [
                {"signal": "pressed", "source": "Colonne/Reprendre", "cible": ".", "methode": "hide"},
                {"signal": "pressed", "source": "Colonne/Quitter", "cible": ".", "methode": "queue_free",
                 "flags": 3},
            ],
        },
        {
            "spec": 1,
            "chemin": f"{DOSSIER}/arene_3d.tscn",
            "ressources_internes": [
                {"nom": "materiau_sol", "type": "StandardMaterial3D",
                 "proprietes": {"albedo_color": {"Color": [0.25, 0.3, 0.35, 1]}, "roughness": 0.8}},
                {"nom": "maille_sol", "type": "BoxMesh",
                 "proprietes": {"material": {"SubResource": "materiau_sol"}, "size": {"Vector3": [20, 0.5, 20]}}},
                {"nom": "forme_sol", "type": "BoxShape3D", "proprietes": {"size": {"Vector3": [20, 0.5, 20]}}},
            ],
            "racine": {
                "nom": "Arene", "type": "Node3D",
                "enfants": [
                    {"nom": "Soleil", "type": "DirectionalLight3D",
                     "proprietes": {"transform": {"Transform3D": [1, 0, 0, 0, 0.5, 0.866025, 0, -0.866025, 0.5, 0, 10, 0]},
                                    "shadow_enabled": True, "light_energy": 1.2}},
                    {"nom": "Camera", "type": "Camera3D",
                     "proprietes": {"transform": {"Transform3D": [1, 0, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 12, 12]},
                                    "fov": 60.0, "current": True}},
                    {"nom": "Sol", "type": "StaticBody3D", "groupes": ["decor"],
                     "enfants": [
                         {"nom": "Maille", "type": "MeshInstance3D", "proprietes": {"mesh": {"SubResource": "maille_sol"}}},
                         {"nom": "Collision", "type": "CollisionShape3D", "proprietes": {"shape": {"SubResource": "forme_sol"}}},
                     ]},
                ],
            },
        },
        {
            "spec": 1,
            "chemin": f"{DOSSIER}/piege_zone.tscn",
            "ressources_internes": [
                {"nom": "forme_zone", "type": "RectangleShape2D", "proprietes": {"size": {"Vector2": [48, 16]}}},
            ],
            "racine": {
                "nom": "PiegeZone", "type": "Area2D",
                "proprietes": {"collision_layer": 4, "collision_mask": 2, "monitorable": False},
                "groupes": ["pieges"],
                "enfants": [
                    {"nom": "Forme", "type": "CollisionShape2D", "proprietes": {"shape": {"SubResource": "forme_zone"}}},
                    {"nom": "Pics", "type": "Polygon2D",
                     "proprietes": {"color": {"Color": [0.8, 0.1, 0.1, 1]},
                                    "polygon": {"PackedVector2Array": [-24, 8, -16, -8, -8, 8, 0, -8, 8, 8, 16, -8, 24, 8]}}},
                    {"nom": "Rearmement", "type": "Timer", "proprietes": {"wait_time": 1.5, "one_shot": True}},
                ],
            },
            "connexions": [
                {"signal": "timeout", "source": "Rearmement", "cible": ".", "methode": "set_monitoring",
                 "flags": 3, "binds": [True]},
                {"signal": "body_entered", "source": ".", "cible": "Rearmement", "methode": "start",
                 "unbinds": 1},
            ],
        },
        {
            "spec": 1,
            "chemin": f"{DOSSIER}/salle_pieces.tscn",
            "racine": {
                "nom": "SallePieces", "type": "Node2D",
                "enfants": [
                    {"nom": "Hero", "instance": "res://scenes/hero.tscn",
                     "proprietes": {"position": {"Vector2": [64, 64]}, "speed": 240.0}},
                    {"nom": "Pieces", "type": "Node2D", "groupes": ["butin"],
                     "enfants": [
                         {"nom": "Piece1", "instance": "res://scenes/coin.tscn",
                          "proprietes": {"position": {"Vector2": [128, 64]}, "value": 5}},
                         {"nom": "Piece2", "instance": "res://scenes/coin.tscn",
                          "proprietes": {"position": {"Vector2": [192.5, 64]}}},
                     ]},
                    {"nom": "Chemin", "type": "Line2D",
                     "proprietes": {"points": {"PackedVector2Array": [64, 64, 128, 64, 192.5, 64]},
                                    "width": 2.0, "default_color": {"Color": [0.4, 0.8, 1, 0.5]}}},
                    {"nom": "Sortie", "type": "Marker2D", "proprietes": {"position": {"Vector2": [256, 64]}}},
                ],
            },
            "connexions": [
                {"signal": "collected", "source": "Pieces/Piece1", "cible": "Pieces/Piece2", "methode": "collect",
                 "unbinds": 1},
            ],
        },
        {
            "spec": 1,
            "chemin": f"{DOSSIER}/hud_complet.tscn",
            "racine": {
                "nom": "HudComplet", "type": "CanvasLayer", "script": "res://scripts/hud.gd",
                "proprietes": {"layer": 2, "metadata/version": 3,
                               "metadata/etiquettes": {"Array[String]": ["vie", "pieces", "vague"]},
                               "metadata/reglages": {"Dictionary": [["couleur", {"Color": [1, 1, 1, 1]}],
                                                                    ["case", {"Vector2i": [3, 4]}],
                                                                    ["cible", {"NodePath": "VieLabel"}],
                                                                    ["nom", {"StringName": "hud"}]]}},
                "enfants": [
                    {"nom": "VieLabel", "type": "Label",
                     "proprietes": {"offset_left": 8.0, "offset_top": 8.0, "text": "Vie : 0/0"}},
                    {"nom": "PiecesLabel", "type": "Label",
                     "proprietes": {"offset_left": 8.0, "offset_top": 32.0, "text": "Pièces : 0"}},
                    {"nom": "VagueLabel", "type": "Label",
                     "proprietes": {"offset_left": 8.0, "offset_top": 56.0, "text": "Vague 0"}},
                    {"nom": "Barre", "type": "ProgressBar",
                     "proprietes": {"offset_left": 8.0, "offset_top": 80.0, "offset_right": 160.0,
                                    "offset_bottom": 96.0, "max_value": 5.0, "value": 5.0, "show_percentage": False}},
                ],
            },
        },
    ]
