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


# --- Revue de la PR des jeux sources ------------------------------------------------------------

def test_lot_voit_l_erreur_d_un_autoload(copie):
    # Le _ready d'un autoload s'affiche avant le premier élément du lot : il doit tout faire revoir.
    etat = copie / "scripts" / "game_state.gd"
    etat.write_text(etat.read_text(encoding="utf-8")
                    + '\n\nfunc _ready() -> void:\n\tvar n := get_node("Inexistant")\n\tprint(n.name)\n',
                    encoding="utf-8", newline="\n")
    verdict = juger_projet(copie, etapes=["check_script", "load_scene"])
    assert verdict["ok"] is False and verdict["etape"] == "load_scene", verdict


def test_check_script_second_avis_garde_une_erreur_du_script(copie):
    # Le script touche un autoload (second avis) ET son initialiseur statique échoue.
    script = copie / "scripts" / "config_a.gd"
    script.write_text('class_name ConfigA\nextends RefCounted\n\nstatic var table := {}\n'
                      'static var vitesse: float = table["vitesse"]\n\n\nfunc gagner() -> void:\n'
                      '\tGameState.add_coins(1)\n', encoding="utf-8", newline="\n")
    verdict = check_script(script, copie)
    assert verdict["ok"] is False, verdict
    assert any(e["fichier"] == "res://scripts/config_a.gd" for e in verdict["erreurs"])


def test_load_scene_ignore_une_classe_cassee_que_la_scene_n_atteint_pas(copie):
    (copie / "scripts" / "inventaire.gd").write_text(
        "class_name Inventaire\nextends RefCounted\n\n\nfunc ajouter(o) -> void:\n\tobjets.append(o)\n",
        encoding="utf-8", newline="\n")
    assert load_scene(copie / "scenes" / "coin.tscn", copie)["ok"] is True


def test_load_scene_resout_l_uid_avant_le_chemin(copie):
    # Script déplacé avec son .uid, chemin texte de la scène périmé : Godot charge par l'UID.
    assert load_scene(copie / "scenes" / "hero.tscn", copie)["ok"] is True  # import : écrit hero.gd.uid
    uid = (copie / "scripts" / "hero.gd.uid").read_text(encoding="utf-8").strip()
    scene = copie / "scenes" / "hero.tscn"
    scene.write_text(scene.read_text(encoding="utf-8").replace(
        'path="res://scripts/hero.gd"', f'uid="{uid}" path="res://scripts/ancien_hero.gd"'),
        encoding="utf-8", newline="\n")
    verdict = load_scene(scene, copie)
    assert verdict["ok"] is True, verdict
