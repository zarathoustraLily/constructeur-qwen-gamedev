"""Tests moteur du juge (ignorés sans Godot)."""

import shutil

import pytest

from usine import config as cfg
from usine.juge import check_script, juger_projet, load_scene
from usine.juge.projet import preparer_copie

pytestmark = pytest.mark.godot
REFERENCE = cfg.RACINE / "godot" / "reference"


def test_projet_de_reference_ok():
    verdict = juger_projet(REFERENCE)
    assert verdict["ok"] is True, verdict
    assert verdict["etape"] == "run_tests"
    assert verdict["tests"]["total"] >= 30
    assert verdict["tests"]["echecs"] == []


@pytest.fixture()
def copie(tmp_path):
    return preparer_copie(REFERENCE, tmp_path / "projet")


def test_check_script_ok_avec_autoload(copie):
    # coin_pickup.gd utilise l'autoload GameState, que --check-only ne connaît pas.
    assert check_script(copie / "scripts" / "coin_pickup.gd", copie)["ok"] is True


def test_check_script_parse_error(copie):
    script = copie / "scripts" / "hud.gd"
    script.write_text(script.read_text(encoding="utf-8").replace("% number", "% numero"), encoding="utf-8")
    verdict = check_script(script, copie)
    assert verdict["ok"] is False
    assert verdict["erreurs"][0]["categorie"] == "parse_error"
    assert verdict["erreurs"][0]["fichier"] == "res://scripts/hud.gd"
    assert verdict["erreurs"][0]["ligne"] == 19


def test_load_scene_decrit_les_noeuds(copie):
    verdict = load_scene(copie / "scenes" / "main.tscn", copie)
    assert verdict["ok"] is True, verdict
    chemins = {n["chemin"] for n in verdict["scene"]["noeuds"]}
    assert {"Hero", "Hero/HealthComponent", "Hud/VagueLabel", "WaveSpawner"} <= chemins


def test_load_scene_script_manquant(copie):
    scene = copie / "scenes" / "coin.tscn"
    scene.write_text(scene.read_text(encoding="utf-8").replace("coin_pickup.gd", "absent.gd"), encoding="utf-8")
    verdict = load_scene(scene, copie)
    assert verdict["ok"] is False
    assert verdict["scene"]["scripts_manquants"] == ["res://scripts/absent.gd"]
    assert {e["categorie"] for e in verdict["erreurs"]} >= {"missing_resource"}


def test_load_scene_chemin_de_noeud_invalide(copie):
    scene = copie / "scenes" / "hud.tscn"
    scene.write_text(scene.read_text(encoding="utf-8").replace('name="VagueLabel"', 'name="WaveLabel"'), encoding="utf-8")
    verdict = load_scene(copie / "scenes" / "main.tscn", copie)
    categories = {e["categorie"] for e in verdict["erreurs"]}
    assert verdict["ok"] is False
    assert {"invalid_node_path", "null_instance"} <= categories


def test_juger_projet_ne_modifie_pas_la_source(tmp_path):
    source = tmp_path / "source"
    shutil.copytree(REFERENCE, source)
    avant = sorted(p.relative_to(source).as_posix() for p in source.rglob("*"))
    juger_projet(source, etapes=["import"])
    assert sorted(p.relative_to(source).as_posix() for p in source.rglob("*")) == avant
