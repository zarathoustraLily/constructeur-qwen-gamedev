"""Spec de scène ↔ .tscn : aller-retour, identifiants dérivés, validation par le vocabulaire."""

import copy
from pathlib import Path

import pytest

from usine.scene.exemples import specs_generees
from usine.scene.spec import (ErreurSpec, h5, id_externe, normaliser_tscn, scene_read, scene_write, uid_derive,
                              valider_spec)

RACINE = Path(__file__).resolve().parent.parent
REFERENCE = RACINE / "godot" / "reference"
SCENES = sorted((REFERENCE / "scenes").glob("*.tscn")) + [Path(__file__).parent / "donnees" / "sonde_godot472.tscn"]


@pytest.fixture(scope="module")
def verif():
    from usine.projet.index import Projet, Verificateur
    from usine.vocab import ouvrir
    return Verificateur(ouvrir(), Projet(REFERENCE))


def _res(scene: Path) -> str:
    return "res://scenes/" + scene.name


@pytest.mark.godot
@pytest.mark.parametrize("scene", SCENES, ids=lambda p: p.name)
def test_aller_retour_avec_vocabulaire(scene, verif):
    texte = scene.read_text(encoding="utf-8")
    spec = scene_read(texte, _res(scene))
    ecrit = scene_write(spec, verif)
    assert normaliser_tscn(ecrit) == normaliser_tscn(texte)
    assert scene_write(scene_read(ecrit, _res(scene)), verif) == ecrit
    if scene.parent.name == "scenes":
        assert valider_spec(spec, verif) == []


@pytest.mark.godot
def test_identifiants_derives():
    spec = scene_read((REFERENCE / "scenes" / "coin.tscn").read_text(encoding="utf-8"), "res://scenes/coin.tscn")
    ecrit = scene_write(spec)
    assert f'id="{id_externe(1, "res://scripts/coin_pickup.gd")}"' in ecrit
    assert 'id="CircleShape2D_' in ecrit and "CircleShape2D_coin" not in ecrit
    assert scene_write(copy.deepcopy(spec)) == ecrit  # déterministe
    assert len(h5("x")) == 5 and h5("x") == h5("x") != h5("y")


@pytest.mark.godot
def test_uid_derive_du_chemin():
    spec = {"chemin": "res://a.tscn", "racine": {"nom": "A", "type": "Node"}}
    assert f'uid="{uid_derive("res://a.tscn")}"' in scene_write(spec)
    assert uid_derive("res://a.tscn") != uid_derive("res://b.tscn")
    assert all(c in "abcdefghijklmnopqrstuvwxy012345678" for c in uid_derive("res://a.tscn")[len("uid://"):])
    spec["uid"] = None
    assert "uid=" not in scene_write(spec)


@pytest.mark.godot
def test_ressources_externes_deduites():
    spec = {"chemin": "res://x.tscn", "uid": None,
            "racine": {"nom": "X", "type": "Node2D", "script": "res://scripts/main.gd",
                       "enfants": [{"nom": "H", "instance": "res://scenes/hero.tscn"}]}}
    ecrit = scene_write(spec)
    assert '[ext_resource type="Script" path="res://scripts/main.gd"' in ecrit
    assert '[ext_resource type="PackedScene" path="res://scenes/hero.tscn"' in ecrit
    with pytest.raises(ErreurSpec):
        scene_write({"racine": {"nom": "X", "type": "Node", "proprietes": {"m": {"ExtResource": "res://a.tres"}}}})


@pytest.mark.godot
def test_ressources_internes_ordonnees():
    spec = {"chemin": "res://m.tscn", "uid": None,
            "ressources_internes": [
                {"nom": "maille", "type": "BoxMesh", "proprietes": {"material": {"SubResource": "mat"}}},
                {"nom": "mat", "type": "StandardMaterial3D", "proprietes": {}}],
            "racine": {"nom": "M", "type": "MeshInstance3D", "proprietes": {"mesh": {"SubResource": "maille"}}}}
    ecrit = scene_write(spec)
    assert ecrit.index("StandardMaterial3D") < ecrit.index("BoxMesh")


@pytest.mark.godot
def test_specs_generees_valides_et_point_fixe(verif):
    for spec in specs_generees():
        assert valider_spec(spec, verif) == [], spec["chemin"]
        ecrit = scene_write(spec, verif)
        # Octets identiques dès la première relecture : les id dérivent de l'usage, pas des noms de la spec.
        assert scene_write(scene_read(ecrit, spec["chemin"]), verif) == ecrit


@pytest.mark.godot
def test_flottants_natifs_coerces(verif):
    spec = {"chemin": "res://t.tscn", "uid": None, "racine": {"nom": "T", "type": "Timer", "proprietes": {"wait_time": 2}}}
    assert "wait_time = 2.0\n" in scene_write(spec, verif)


@pytest.mark.godot
def test_script_range_apres_les_natives(verif):
    spec = {"chemin": "res://h.tscn", "uid": None,
            "racine": {"nom": "H", "type": "Node", "script": "res://scripts/health_component.gd",
                       "proprietes": {"max_health": 4, "process_mode": 1}}}
    ecrit = scene_write(spec, verif)
    assert ecrit.index("process_mode") < ecrit.index("script =") < ecrit.index("max_health")


@pytest.mark.godot
@pytest.mark.parametrize("mutation, fragment", [
    (lambda s: s["racine"].update(type="Node2DX"), "type de nœud inconnu"),
    (lambda s: s["racine"]["proprietes"].update(vitesse=3), "propriété inconnue 'vitesse'"),
    (lambda s: s["racine"]["proprietes"].update(collision_layer="un"), "entier attendu"),
    (lambda s: s["racine"]["proprietes"].update(position={"Vector2": [1]}), "composantes"),
    (lambda s: s["connexions"].append({"signal": "explose", "source": ".", "cible": ".", "methode": "hide"}), "signal inconnu"),
    (lambda s: s["connexions"].append({"signal": "body_entered", "source": ".", "cible": ".", "methode": "nope"}), "méthode inconnue"),
    (lambda s: s["connexions"].append({"signal": "body_entered", "source": ".", "cible": ".", "methode": "hide"}), "arité"),
    (lambda s: s["connexions"].append({"signal": "ready", "source": "Fantome", "cible": ".", "methode": "hide"}), "source inconnue"),
    (lambda s: s["racine"]["enfants"].append({"nom": "Forme", "type": "Node"}), "deux enfants"),
    (lambda s: s["racine"]["enfants"][0]["proprietes"].update(shape={"SubResource": "absente"}), "ressource interne inconnue"),
    (lambda s: s["racine"].update(script="res://scripts/hud.gd"), "incompatible"),
])
def test_validation_refuse_le_vocabulaire_invente(verif, mutation, fragment):
    spec = {"chemin": "res://z.tscn",
            "ressources_internes": [{"nom": "f", "type": "CircleShape2D", "proprietes": {"radius": 4.0}}],
            "racine": {"nom": "Z", "type": "Area2D", "proprietes": {"monitorable": False},
                       "enfants": [{"nom": "Forme", "type": "CollisionShape2D", "proprietes": {"shape": {"SubResource": "f"}}}]},
            "connexions": []}
    assert valider_spec(spec, verif) == []
    mutation(spec)
    erreurs = valider_spec(spec, verif)
    assert any(fragment in e["message"] for e in erreurs), erreurs


@pytest.mark.godot
def test_preuve_godot_aller_retour():
    from usine.scene.preuve import preuve
    lignes = []
    assert preuve(REFERENCE, afficher=lignes.append) == 0, "\n".join(lignes)
    assert lignes[-1].startswith("10/10 scènes conformes")
