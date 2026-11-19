"""Filtre des symboles (décision 24) : sur une API et une table de renommages minuscules, puis sur les vraies si elles
sont là."""

import json
from pathlib import Path

import pytest

from usine.paires import symboles
from usine.paires.symboles import Filtre

API = {
    "global_constants": [], "utility_functions": [{"name": "randf_range"}, {"name": "deg_to_rad"}],
    "global_enums": [{"name": "Key", "values": [{"name": "KEY_A"}]}],
    "builtin_classes": [{"name": "Vector3", "methods": [{"name": "length"}], "members": [{"name": "y"}],
                         "constants": [{"name": "UP"}], "enums": []}],
    "classes": [
        {"name": "Object", "inherits": None, "methods": [{"name": "connect"}]},
        {"name": "Node", "inherits": "Object", "methods": [{"name": "add_child"}]},
        {"name": "Node3D", "inherits": "Node", "properties": [{"name": "position"}]},
        {"name": "CharacterBody3D", "inherits": "Node3D", "methods": [{"name": "move_and_slide"}]},
        {"name": "Input", "inherits": "Object", "methods": [{"name": "is_action_pressed"}]},
    ],
    "singletons": [],
}
TABLE = """
const char *RenamesMap3To4::gdscript_function_renames[][2] = {
	{ "rand_range", "randf_range" },
	{ "deg2rad", "deg_to_rad" },
	{ "add_child", "add_child" },
	{ nullptr, nullptr },
};
const char *RenamesMap3To4::shaders_renames[][2] = {
	{ "hint_color", "source_color" },
	{ nullptr, nullptr },
};
const char *RenamesMap3To4::class_renames[][2] = {
	{ "KinematicBody", "CharacterBody3D" },
	{ "Spatial", "Node3D" },
	{ nullptr, nullptr },
};
"""
VIDES = ("enum_renames", "gdscript_properties_renames", "gdscript_signals_renames", "builtin_types_renames")


@pytest.fixture
def filtre(tmp_path: Path) -> Filtre:
    api = tmp_path / "api.json"
    api.write_text(json.dumps(API), encoding="utf-8")
    source = tmp_path / "godot"
    (source / "editor/project_upgrade").mkdir(parents=True)
    vides = "".join(f"const char *RenamesMap3To4::{t}[][2] = {{\n\t{{ nullptr, nullptr }},\n}};\n" for t in VIDES)
    (source / "editor/project_upgrade/renames_map_3_to_4.cpp").write_text(TABLE + vides, encoding="utf-8")
    (source / "modules/gdscript/doc_classes").mkdir(parents=True)
    (source / "modules/gdscript/doc_classes/@GDScript.xml").write_text(
        '<class name="@GDScript"><methods><method name="preload"/></methods></class>', encoding="utf-8")
    symboles._charger.cache_clear()
    return Filtre.charger(api, source)


def _paire(reponse: str, appels: list | None = None) -> dict:
    return {"messages": [{"role": "user", "content": "x"},
                         {"role": "assistant", "content": reponse, "tool_calls": appels}]}


def test_les_noms_de_godot_3_du_code_ecrit_sont_refuses(filtre: Filtre) -> None:
    assert filtre.verifier(_paire("```gdscript\nvar a: float = rand_range(0.0, 1.0)\n```")) == [
        "nom de Godot 3 : rand_range → randf_range"]
    assert filtre.verifier(_paire("```gdscript\nextends KinematicBody\n```")) == [
        "nom de Godot 3 : KinematicBody → CharacterBody3D"]
    assert filtre.verifier(_paire("```gdshader\nuniform vec4 c : hint_color;\n```")) == [
        "nom de Godot 3 (shader) : hint_color → source_color"]
    appel = {"function": {"name": "edit", "arguments": {"path": "a.gd", "oldString": "x",
                                                        "newString": "var r: float = deg2rad(90.0)"}}}
    assert filtre.verifier(_paire("", [appel])) == ["nom de Godot 3 : deg2rad → deg_to_rad"]


def test_un_membre_absent_de_la_classe_et_de_ses_parents_est_refuse(filtre: Filtre) -> None:
    assert filtre.verifier(_paire("```gdscript\nif Input.is_action_held(&\"saut\"):\n\tpass\n```")) == [
        "absent de l'API 4.7.2 : Input.is_action_held"]
    assert filtre.verifier(_paire("```gdscript\nvar v: Vector3 = Vector3.FORWARD_UP\n```")) == [
        "absent de l'API 4.7.2 : Vector3.FORWARD_UP"]
    # Hérité, intégré, énumération globale, constructeur : présents.
    bon = ("```gdscript\nvar b: CharacterBody3D = CharacterBody3D.new()\nb.connect(&\"x\", f)\n"
           "var k: Key = Key.KEY_A\nvar u: float = Vector3.UP.y\n```")
    assert filtre.verifier(_paire(bon)) == []


def test_le_texte_a_remplacer_la_prose_les_noeuds_et_les_noms_du_projet_passent(filtre: Filtre) -> None:
    remplace = ("Ligne 3, je remplace :\n```gdscript\nvar a: float = rand_range(0.0, 1.0)\n```\npar :\n"
                "```gdscript\nvar a: float = randf_range(0.0, 1.0)\n```")
    assert filtre.verifier(_paire(remplace)) == []
    assert filtre.verifier(_paire("`rand_range` est le nom de Godot 3 ; utilise `randf_range`.")) == []
    assert filtre.verifier(_paire("```gdscript\n@onready var c: Node3D = $Arm/Spatial\n```")) == []
    assert filtre.verifier(_paire("```gdscript\nfunc rand_range(a: float) -> float:\n\treturn a\n```")) == []
    assert filtre.verifier(_paire("```gdscript\nprint(\"rand_range\")  # rand_range\n```")) == []
    sortie = "```\n$ godot --headless --check-only -s a.gd\nSCRIPT ERROR: rand_range not found\n```"
    assert filtre.verifier(_paire(sortie)) == []


def test_un_nom_de_godot_3_qui_existe_encore_n_est_pas_retenu(filtre: Filtre) -> None:
    assert "add_child" not in filtre.godot3
    assert "rand_range" in filtre.godot3


def test_les_vraies_tables_de_la_machine() -> None:
    try:
        symboles._charger.cache_clear()
        vrai = Filtre.charger()
    except (RuntimeError, FileNotFoundError, OSError):
        pytest.skip("extension_api 4.7.2 ou source de Godot 4.7.2 absents")
    assert vrai.godot3["KinematicBody"] == "CharacterBody3D"
    assert "instantiate" not in vrai.godot3
    assert vrai.verifier(_paire("```gdscript\nvar s: Node = scene.instance()\nvar r: float = stepify(x, 0.5)\n```")) \
        == ["nom de Godot 3 : stepify → snapped"]
