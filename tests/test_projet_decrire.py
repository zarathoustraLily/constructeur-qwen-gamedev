"""describe_project : vue stable et table des ids."""

from pathlib import Path

from usine.projet.decrire import alias_scenes, describe_project

REFERENCE = Path(__file__).resolve().parent.parent / "godot" / "reference"


def test_vue_stable_et_complete():
    a = describe_project(REFERENCE)
    b = describe_project(REFERENCE)
    assert a["texte"] == b["texte"]
    texte = a["texte"]
    assert "autoloads : GameState = res://scripts/game_state.gd" in texte
    assert "main:Coins/Coin1  instance res://scenes/coin.tscn (Area2D)" in texte
    assert "connexion main:WaveSpawner.wave_started → main:Hud._on_wave_started" in texte
    assert "func take_damage(amount: int) -> bool" in texte
    assert "signal wave_started(number: int, enemy_count: int)" in texte
    assert "shape=CircleShape2D(radius=6.0)" in texte
    assert "res://tests/test_hero.gd (7 tests)" in texte
    assert a["ids"]["main:Coins/Coin1"] == {"scene": "res://scenes/main.tscn", "chemin": "Coins/Coin1"}
    assert a["ids"]["coin"] == {"scene": "res://scenes/coin.tscn", "chemin": "."}
    assert len(a["ids"]) == 20


def test_alias_en_cas_de_doublon():
    assert alias_scenes(["res://a/hud.tscn", "res://b/hud.tscn", "res://main.tscn"]) == {
        "res://a/hud.tscn": "a/hud", "res://b/hud.tscn": "b/hud", "res://main.tscn": "main"}
