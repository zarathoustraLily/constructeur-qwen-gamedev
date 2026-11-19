"""Paires négatives « symbole absent » (décision 24) : les faux noms, sur la vraie API 4.7.2 de la machine."""

import random

import pytest

from usine.paires import negatives


@pytest.fixture(autouse=True)
def _api():
    try:
        from usine.cours.base import api, chemins
        chemins.configurer(cours="kart")
        api._api()
        from usine.paires.symboles import Filtre
        Filtre.charger()
    except Exception as e:   # noqa: BLE001 — API, source de Godot ou cours absents de cette machine
        pytest.skip(f"API 4.7.2 ou source de Godot absente : {e}")


def test_un_nom_de_godot_3_ne_vaut_que_pour_sa_classe_et_sa_sorte_de_membre():
    assert ("rect_size", "godot3", None) in negatives.faux_noms("Control", "size", set())
    assert all(s != "godot3" for _, s, _ in negatives.faux_noms("Array", "size", set()))
    assert ("translation", "godot3", None) in negatives.faux_noms("Node3D", "position", set())
    assert all(s != "godot3" for _, s, _ in negatives.faux_noms("Node2D", "position", set()))
    assert ("empty", "godot3", None) in negatives.faux_noms("Array", "is_empty", set())
    assert ("instance", "godot3", None) in negatives.faux_noms("PackedScene", "instantiate", set())


def test_une_classe_voisine_donne_un_membre_de_meme_sorte_qui_partage_le_nom():
    voisins = [(f, ou) for f, s, ou in negatives.faux_noms("CharacterBody3D", "velocity", set()) if s == "voisin"]
    assert ("linear_velocity", "RigidBody3D") in voisins
    assert all(s != "voisin" or f != "get_global_rect" for f, s, _ in negatives.faux_noms("Node3D", "global_basis", set()))


def test_un_faux_nom_n_existe_ni_dans_la_classe_ni_dans_le_fichier():
    from usine.cours.base import api
    for classe, membre in (("Input", "is_action_pressed"), ("Vector3", "normalized"), ("Array", "append")):
        for faux, _, _ in negatives.faux_noms(classe, membre, set()):
            assert api.membre(classe, faux) is None
    assert all(f != "push" for f, _, _ in negatives.faux_noms("Array", "append", {"push"}))


def test_les_lignes_retenues_sont_celles_que_godot_refuse_a_l_analyse():
    texte = ("extends Node3D\n\n@onready var _visual: Node3D = $V\nvar offset: Vector3 = Vector3.ZERO\n\n"
             "func _ready() -> void:\n\t_visual.position = Vector3.UP\n\tvar d: float = offset.length()\n"
             "\tadd_child(Node.new())\n")
    lignes = {m.ligne: m for m in negatives.candidates("a.gd", texte, random.Random(1))}
    assert 7 not in lignes or lignes[7].detail["forme"] == "statique"   # `_visual` : classe d'objet, rien à l'analyse
    assert lignes[8].detail["classe"] == "Vector3" and lignes[8].detail["juste"] == "length"
    assert lignes[9].detail["forme"] in ("hérité", "statique")
    for m in lignes.values():
        assert m.avant != m.apres and m.detail["faux"] in m.apres
