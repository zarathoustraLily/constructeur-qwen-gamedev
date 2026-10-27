"""Familles « erreur de compilation » (B1) et « erreur de shader » (B2) : fautes, extrait décalé, vraie paire."""

import pytest

from usine.cours.base import debogage
from usine.paires import compilation

SCRIPT = """extends Node

@export var vitesse: float = 2.5
var _compte: int = 0
var _facteur: float = 1.5


func avancer(delta: float) -> float:
	_compte += 1
	return _bouger(delta)


func _bouger(delta: float) -> float:
	return vitesse * delta * _facteur
"""


def test_les_fautes_d_un_script_couvrent_les_genres_de_compilation():
    ms = compilation.candidates({"a.gd": SCRIPT}, ["a.gd"], "compilation")
    genres = {m.genre for m in ms}
    assert {"godot3_annotation", "non_type", "type", "parametre", "retour", "appel"} <= genres
    assert all(m.genre in compilation.GENRES["compilation"] for m in ms)
    assert not compilation.candidates({"a.gd": SCRIPT}, ["a.gd"], "shader")


def test_extrait_de_shader_decale_de_plusieurs_lignes():
    fichier = "\n".join(["shader_type spatial;", '#include "res://a.gdshaderinc"', '#include "res://b.gdshaderinc"',
                         "void fragment() {", "\tvec3 c = vec3(1.0);", "\tALBEDO = c;", "\tNORMALMAP = c;", "}"])
    sortie = ("--res://s.gdshader--\n    5 | void fragment() {\nE   7->  vec3 c = vec3(1.0);\n    8 |  ALBEDO = c;\n"
              "SHADER ERROR: Unknown identifier in expression: 'NORMALMAP'.\n   at: (null) (res://s.gdshader:7)")
    note = debogage.lecture_extrait_shader(sortie, "res://s.gdshader", 7, "\tNORMALMAP = c;", fichier)
    assert "qui est la ligne 5 du fichier" in note and "décalé de 2 lignes" in note and "2 `#include`" in note


@pytest.mark.godot
def test_godot_une_paire_de_compilation_verifiee(tmp_path):
    from usine.cours.base import chemins, creation, sessions
    chemins.configurer(cours="kart")
    _, apres = creation.etats("kart", 3)
    m = next(x for x in compilation.candidates(apres, compilation.fichiers_a_fauter(apres, "compilation"))
             if x.genre == "godot3_annotation")
    p, raison = compilation.paire(sessions.Projet("kart", 3, apres), m, "gameplay")
    assert p is not None, raison
    reponse = p["messages"][1]["content"]
    assert f"ligne {m.ligne}" in reponse and m.avant in reponse and p["jetons"] <= compilation.PLAFOND
    assert reponse.index(m.apres) > reponse.index("je remplace")  # règle 7.3
