from pathlib import Path

import pytest

from usine.juge.verdict import (CATEGORIES, categoriser, comparable, dedoublonner, extraire_erreurs_journal,
                                lire_junit, nouveau_verdict)

DONNEES = Path(__file__).parent / "donnees"


@pytest.mark.parametrize("message, attendu", [
    ('Parse Error: Identifier "numero" not declared in the current scope.', "parse_error"),
    ("Compile Error: Failed to compile depended scripts.", "parse_error"),
    ("Invalid access to property or key 'global_position' on a base object of type 'Nil'.", "null_instance"),
    ("Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'null instance'.", "null_instance"),
    ("Cannot call method 'get_name' on a null value.", "null_instance"),
    ('Node not found: "WaveLabel" (relative to "/root/Main/Hud").', "invalid_node_path"),
    ("In Object of type 'Node': Attempt to connect nonexistent signal 'mort' to callable 'x'.", "signal_missing"),
    ("Trying to assign value of type 'CanvasLayer' to a variable of type 'hud.gd'.", "type_error"),
    ("Attempt to open script 'res://x.gd' resulted in error 'File not found'.", "missing_resource"),
    ("quelque chose d'imprévu", "autre"),
])
def test_categoriser(message, attendu):
    assert categoriser(message) == attendu
    assert attendu in CATEGORIES


def test_journal_reel_parse_error():
    erreurs = extraire_erreurs_journal((DONNEES / "journal_parse_error.txt").read_text(encoding="utf-8"))
    assert erreurs[0] == {"fichier": "res://scripts/hud.gd", "ligne": 19, "categorie": "parse_error",
                          "message": 'Parse Error: Identifier "numero" not declared in the current scope.'}
    assert {"fichier": "res://scripts/main.gd", "ligne": 6, "categorie": "type_error"}.items() <= erreurs[3].items()


def test_journal_position_en_ligne_et_bruit_ignore():
    sortie = (
        "ERROR: The remote port number must be between 1 and 65535 (inclusive).\n"
        "   at: connect_to_host (core/io/stream_peer_tcp.cpp:69)\n"
        "\x1b[31mERROR: res://scenes/coin.tscn:9 - Parse Error: [ext_resource] referenced non-existent resource at: res://x.gd.\x1b[0m\n"
        "   at: _printerr (scene/resources/resource_format_text.cpp:41)\n"
    )
    erreurs = extraire_erreurs_journal(sortie)
    assert len(erreurs) == 1
    assert erreurs[0]["fichier"] == "res://scenes/coin.tscn"
    assert erreurs[0]["ligne"] == 9
    assert erreurs[0]["categorie"] == "missing_resource"


def test_journal_ignore_les_positions_des_addons():
    sortie = (
        "SCRIPT ERROR: Parse Error: oups\n"
        "          at: GDScript::reload (res://addons/gdUnit4/src/x.gd:3)\n"
        "              [0] f (res://scripts/hero.gd:12)\n"
    )
    assert extraire_erreurs_journal(sortie)[0]["fichier"] == "res://scripts/hero.gd"


def test_lire_junit():
    tests, erreurs = lire_junit(DONNEES / "results.xml")
    assert tests == {"total": 4, "passes": 1, "echecs": ["test_hud:test_null", "test_hud:test_rate"], "ignores": 1}
    par_categorie = {e["categorie"]: e for e in erreurs}
    assert par_categorie["test_failure"]["fichier"] == "res://tests/test_hud.gd"
    assert par_categorie["test_failure"]["ligne"] == 11
    assert par_categorie["null_instance"]["fichier"] == "res://scripts/hud.gd"
    assert par_categorie["null_instance"]["ligne"] == 19


def test_format_verdict_et_comparaison():
    v = nouveau_verdict("run_tests")
    assert set(v) == {"ok", "etape", "duree_s", "erreurs", "tests"}
    w = dict(v, duree_s=9.0)
    assert comparable(v) == comparable(w)
    e = {"fichier": None, "ligne": None, "categorie": "autre", "message": "m"}
    assert dedoublonner([e, dict(e)]) == [e]
