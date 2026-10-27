"""Outil voir_scene : carte en texte, puis vrai rendu d'un petit projet 3D (caméra du bug réel, puis corrigée)."""

from pathlib import Path

import pytest

from usine.retour import vues

SCENE = """[gd_scene format=3]

[sub_resource type="BoxMesh" id="BoxMesh_sol"]
size = Vector3(16, 0.2, 16)

[sub_resource type="BoxMesh" id="BoxMesh_caisse"]

[node name="Monde" type="Node3D"]

[node name="Sol" type="MeshInstance3D" parent="."]
position = Vector3(0, -0.1, 0)
mesh = SubResource("BoxMesh_sol")

[node name="Caisse" type="MeshInstance3D" parent="."]
position = Vector3(2, 0.5, -2)
mesh = SubResource("BoxMesh_caisse")

[node name="Camera3D" type="Camera3D" parent="."]
{camera}
projection = 1
size = 10.0
"""
# Le bug réel du roguelike de laurent (2026-10-26) : 12 m au-dessus, sans rotation, donc visée vers -Z, à plat.
CAMERA_BUG = "position = Vector3(0, 12, 0)"
CAMERA_CORRIGEE = "position = Vector3(0, 17, 11)\nrotation = Vector3(-0.959931, 0, 0)"

DONNEES_BUG = {
    "image": 60, "scene": "res://main.tscn",
    "camera": {"chemin": "/root/Monde/Camera3D", "position": [0, 12, 0], "regarde_vers": [0, 0, -1],
               "haut": [0, 1, 0], "projection": "orthographique", "fov": 75, "size": 10, "near": 0.05, "far": 4000,
               "cull_mask": 1048575},
    "cameras": [{"chemin": "/root/Monde/Camera3D", "courante": True, "position": [0, 12, 0],
                 "regarde_vers": [0, 0, -1]}],
    "lumieres": [],
    "objets": [{"chemin": "/root/Monde/Sol", "nom": "Sol", "type": "MeshInstance3D", "centre": [0, -0.1, 0],
                "taille": [16, 0.2, 16], "dans_le_champ": False, "hors_champ": ["bas"], "distance": 12.1}],
    "caches": [], "bornes": {"centre": [0, 6, 0], "taille": [17, 13, 17]},
}


def test_direction_en_mots():
    assert vues._direction([0, 0, -1]) == "à l'horizontale"
    assert vues._direction([0, -1, 0]) == "droit vers le bas"
    assert vues._direction([0, -0.82, -0.57]) == "55° vers le bas"


def test_la_carte_dit_ou_regarde_la_camera_et_ce_qui_est_hors_champ():
    texte = vues.carte(DONNEES_BUG)
    assert "position (0, 12, 0), regarde vers (0, 0, -1) (à l'horizontale)" in texte
    assert "dans le champ de la caméra : 0" in texte
    assert "Monde/Sol [MeshInstance3D] centre (0, -0.1, 0) taille (16, 0.2, 16), à 12.1 m : HORS CHAMP : bas" in texte
    carte = vues.carte_texte(DONNEES_BUG)
    assert "C^" not in carte and "^" in carte and "C" in carte  # flèche de visée au-dessus de la caméra
    assert "C = caméra, à y = 12, visée à l'horizontale" in carte
    assert "a = Sol" in carte  # hors champ : minuscule


def test_carte_sans_plan_pour_les_paires_courtes():
    texte = vues.carte(DONNEES_BUG, plan=False)
    assert "regarde vers (0, 0, -1) (à l'horizontale)" in texte
    assert "Carte vue de dessus" not in texte and "repères" not in texte


def test_sans_camera_la_carte_le_dit():
    d = dict(DONNEES_BUG, camera={}, objets=[])
    assert "AUCUNE caméra 3D courante" in vues.carte(d)


def _projet(tmp_path: Path, camera: str) -> Path:
    projet = tmp_path / "projet"
    projet.mkdir()
    (projet / "project.godot").write_text(
        'config_version=5\n\n[application]\n\nrun/main_scene="res://main.tscn"\nconfig/features=PackedStringArray("4.7")\n',
        encoding="utf-8")
    (projet / "main.tscn").write_text(SCENE.format(camera=camera), encoding="utf-8")
    return projet


@pytest.mark.godot
def test_godot_camera_du_bug_reel_rien_dans_le_champ(tmp_path):
    r = vues.voir(_projet(tmp_path, CAMERA_BUG), image=10, vues=["jeu", "dessus"], sortie=tmp_path / "sorties")
    assert r["ok"], r.get("erreur")
    objets = r["donnees"]["objets"]
    assert {o["nom"] for o in objets} == {"Sol", "Caisse"}
    assert not any(o["dans_le_champ"] for o in objets)
    assert all("bas" in o["hors_champ"] for o in objets)
    assert "(à l'horizontale)" in r["carte"] and "dans le champ de la caméra : 0" in r["carte"]
    assert Path(r["image"]).is_file()


@pytest.mark.godot
def test_godot_camera_inclinee_tout_dans_le_champ(tmp_path):
    r = vues.voir(_projet(tmp_path, CAMERA_CORRIGEE), image=10, vues=["jeu", "cote"], sortie=tmp_path / "sorties")
    assert r["ok"], r.get("erreur")
    assert all(o["dans_le_champ"] for o in r["donnees"]["objets"])
    assert "(55° vers le bas)" in r["carte"] and "dans le champ de la caméra : 2" in r["carte"]
