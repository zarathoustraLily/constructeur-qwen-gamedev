import subprocess
import sys

import pytest

from usine import config as cfg
from usine.vocab.construire import charger, chemin_base
from usine.vocab.requete import Vocabulaire, ouvrir

API_MINI = {
    "header": {"version_major": 4, "version_minor": 7, "version_patch": 2},
    "classes": [
        {"name": "Object", "inherits": None, "api_type": "core", "is_instantiable": True,
         "signals": [{"name": "script_changed"}],
         "methods": [{"name": "connect", "arguments": [
             {"name": "signal", "type": "StringName"}, {"name": "callable", "type": "Callable"},
             {"name": "flags", "type": "int", "default_value": "0"}]},
             {"name": "call", "is_vararg": True, "arguments": [{"name": "method", "type": "StringName"}]}]},
        {"name": "Node", "inherits": "Object", "api_type": "core",
         "signals": [{"name": "ready"}],
         "properties": [{"name": "name", "type": "StringName", "setter": "set_name", "getter": "get_name"}],
         "enums": [{"name": "ProcessMode", "values": [{"name": "PROCESS_MODE_INHERIT", "value": 0}]}],
         "constants": [{"name": "NOTIFICATION_READY", "value": 13}]},
        {"name": "Area2D", "inherits": "Node", "api_type": "core",
         "signals": [{"name": "body_entered", "arguments": [{"name": "body", "type": "Node2D"}]}]},
    ],
    "builtin_classes": [{"name": "Vector2", "members": [{"name": "x", "type": "float"}],
                         "methods": [{"name": "length", "return_type": "float"}]}],
    "global_enums": [{"name": "Side", "values": [{"name": "SIDE_LEFT", "value": 0}]}],
    "utility_functions": [{"name": "sin", "return_type": "float", "arguments": [{"name": "angle_rad", "type": "float"}]}],
    "singletons": [{"name": "Engine", "type": "Engine"}],
}


@pytest.fixture()
def vocab(tmp_path):
    return Vocabulaire(charger(API_MINI, tmp_path / "v.sqlite"))


def test_heritage(vocab):
    assert vocab.heritage("Area2D") == ["Area2D", "Node", "Object"]
    assert vocab.heritage("Inconnue") == []


def test_existe_suit_l_heritage(vocab):
    assert vocab.existe("Area2D", "body_entered", "signal")
    assert vocab.existe("Area2D", "ready", "signal")
    assert vocab.existe("Area2D", "name", "propriete")
    assert vocab.existe("Area2D", "connect", "methode")
    assert vocab.existe("Area2D", "PROCESS_MODE_INHERIT", "valeur_enum")
    assert vocab.existe("Area2D", "NOTIFICATION_READY", "constante")
    assert vocab.existe("Area2D", "ProcessMode")
    assert not vocab.existe("Node", "body_entered", "signal")
    assert not vocab.existe("Area2D", "body_entered", "methode")
    assert vocab.definie_dans("Area2D", "ready") == "Node"


def test_genre_inconnu(vocab):
    with pytest.raises(ValueError):
        vocab.existe("Node", "ready", "evenement")


def test_arite(vocab):
    assert vocab.arite("Area2D", "connect") == (2, 3)
    assert vocab.arite("Node", "call") == (1, None)
    assert vocab.arite("Node", "absente") is None


def test_types_integres_et_portee_globale(vocab):
    assert vocab.existe("Vector2", "x", "propriete")
    assert vocab.existe("Vector2", "length", "methode")
    assert vocab.existe("@GlobalScope", "sin", "methode")
    assert vocab.existe("@GlobalScope", "SIDE_LEFT", "valeur_enum")
    assert vocab.existe("@GlobalScope", "Engine", "propriete")


def test_decrire_marque_l_origine(vocab):
    desc = vocab.decrire("Area2D")
    signaux = {(s["origine"], s["nom"]) for s in desc["signaux"]}
    assert ("Area2D", "body_entered") in signaux and ("Node", "ready") in signaux
    assert desc["signaux"][0]["arguments"] == [{"nom": "body", "type": "Node2D"}]


@pytest.mark.godot
def test_vocabulaire_reel_godot():
    v = ouvrir()
    assert v.version() == cfg.version_godot()
    assert v.heritage("CharacterBody2D")[:3] == ["CharacterBody2D", "PhysicsBody2D", "CollisionObject2D"]
    assert v.existe("CharacterBody2D", "input_event", "signal")
    assert v.existe("CharacterBody2D", "global_position", "propriete")
    assert v.existe("CharacterBody2D", "move_and_slide", "methode")
    assert v.existe("Area2D", "body_entered", "signal")
    assert not v.existe("CharacterBody2D", "body_entered", "signal")
    assert v.existe("CharacterBody2D", "MOTION_MODE_FLOATING", "valeur_enum")
    assert chemin_base().is_file()


@pytest.mark.godot
def test_cli_lookup():
    sortie = subprocess.run([sys.executable, "-m", "usine.vocab", "lookup", "CharacterBody2D"],
                            capture_output=True, text=True, encoding="utf-8", cwd=cfg.RACINE, check=True).stdout
    assert "Héritage : CharacterBody2D → PhysicsBody2D" in sortie
    assert "[CollisionObject2D] input_event(" in sortie
    assert "[Node2D] global_position: Vector2" in sortie
