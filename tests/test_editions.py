"""Langage d'édition : chaque opération, les refus, le tout-ou-rien, le respect de l'existant."""

import json
import os
import shutil
from pathlib import Path

import pytest

from usine.juge.projet import IGNORES_COPIE
from usine.projet.__main__ import EXEMPLES, demo, empreinte_dossier
from usine.projet import editions
from usine.projet.editions import apply_edits

REFERENCE = Path(__file__).resolve().parent.parent / "godot" / "reference"
pytestmark = pytest.mark.godot  # le vocabulaire est construit depuis Godot


@pytest.fixture
def projet(tmp_path):
    copie = tmp_path / "projet"
    shutil.copytree(REFERENCE, copie, ignore=IGNORES_COPIE)
    return copie


def appliquer(projet, *edits):
    return apply_edits(projet, list(edits), etapes=())


def lire(projet, rel):
    with open(projet / rel, encoding="utf-8", newline="") as f:
        return f.read()


def test_add_node_et_set_property(projet):
    v = appliquer(projet,
                  {"op": "add_node", "parent": "main:Coins", "nom": "Coin4", "instance": "res://scenes/coin.tscn",
                   "proprietes": {"position": {"Vector2": [10, 20]}, "value": 3}},
                  {"op": "set_property", "noeud": "hud:VieLabel", "propriete": "visible", "valeur": False})
    assert v["applique"], v
    main = lire(projet, "scenes/main.tscn")
    bloc = '[node name="Coin4" parent="Coins" instance=ExtResource("6_coin")]\nposition = Vector2(10, 20)\nvalue = 3\n'
    assert bloc in main
    # Inséré après le dernier descendant de Coins, avant Hud.
    assert main.index("Coin3") < main.index("Coin4") < main.index('name="Hud"')
    assert 'text = "Vie : 0/0"\nvisible = false\n' in lire(projet, "scenes/hud.tscn")


def test_respect_de_l_existant(projet):
    avant = lire(projet, "scenes/hud.tscn").splitlines(True)
    assert appliquer(projet, {"op": "set_property", "noeud": "hud:PiecesLabel", "propriete": "offset_top", "valeur": 40})["applique"]
    apres = lire(projet, "scenes/hud.tscn").splitlines(True)
    differences = [(a, b) for a, b in zip(avant, apres) if a != b]
    assert len(avant) == len(apres) and differences == [("offset_top = 32.0\n", "offset_top = 40.0\n")]


def test_del_node_retire_connexions_et_ressources(projet):
    v = appliquer(projet, {"op": "del_node", "noeud": "main:WaveSpawner"})
    assert v["applique"], v
    main = lire(projet, "scenes/main.tscn")
    assert "WaveSpawner" not in main and "wave_spawner.gd" not in main and "ghost.tscn" not in main
    assert "[connection" not in main and main.endswith('instance=ExtResource("5_hud")]\n')
    assert "load_steps=5" in main


def test_attach_script_et_fonctions(projet):
    v = appliquer(projet,
                  {"op": "add_node", "parent": "main", "nom": "Bonus", "type": "Timer"},
                  {"op": "attach_script", "noeud": "main:Bonus", "script": "res://scripts/bonus.gd",
                   "contenu": "extends Timer\n\n\nfunc a() -> void:\n\tpass\n"},
                  {"op": "add_signal", "script": "res://scripts/bonus.gd", "signal": "fini", "arguments": ["n: int"]},
                  {"op": "add_function", "script": "res://scripts/bonus.gd", "code": "func b(x: int) -> int:\n  if x > 0:\n    return x\n  return 0"},
                  {"op": "replace_function", "script": "res://scripts/bonus.gd", "fonction": "a", "corps": "start()"},
                  {"op": "connect", "source": "main:Bonus", "signal": "timeout", "cible": "main:Bonus", "methode": "a"})
    assert v["applique"], v
    assert lire(projet, "scripts/bonus.gd") == (
        "extends Timer\n\nsignal fini(n: int)\n\n\nfunc a() -> void:\n\tstart()\n\n\n"
        "func b(x: int) -> int:\n\tif x > 0:\n\t\treturn x\n\treturn 0\n")
    main = lire(projet, "scenes/main.tscn")
    assert '[connection signal="timeout" from="Bonus" to="Bonus" method="a"]\n' in main


def test_replace_function_garde_la_doc(projet):
    assert appliquer(projet, {"op": "replace_function", "script": "res://scripts/hero.gd", "fonction": "try_dash",
                              "corps": "return false"})["applique"]
    hero = lire(projet, "scripts/hero.gd")
    assert "## Lance un dash dans la direction donnée (ou celle du regard si nulle).\nfunc try_dash(direction: Vector2) -> bool:\n\treturn false\n\n\n## Fait avancer" in hero


def test_set_resource_value_interne_et_tres(projet):
    (projet / "donnees").mkdir()
    (projet / "donnees" / "zone.tres").write_text('[gd_resource type="CircleShape2D" format=3]\n\n[resource]\nradius = 4.0\n', encoding="utf-8")
    v = appliquer(projet,
                  {"op": "set_resource_value", "ressource": "res://donnees/zone.tres", "propriete": "radius", "valeur": 9},
                  {"op": "set_resource_value", "ressource": "ghost:CollisionShape2D#shape", "propriete": "radius", "valeur": 12.5})
    assert v["applique"], v
    assert lire(projet, "donnees/zone.tres").endswith("[resource]\nradius = 9.0\n")
    assert "radius = 12.5\n" in lire(projet, "scenes/ghost.tscn")


def test_ressource_interne_en_ligne(projet):
    v = appliquer(projet, {"op": "set_property", "noeud": "hero:CollisionShape2D", "propriete": "shape",
                           "valeur": {"SubResource": {"type": "RectangleShape2D", "proprietes": {"size": {"Vector2": [4, 6]}}}}})
    assert v["applique"], v
    hero = lire(projet, "scenes/hero.tscn")
    assert "CircleShape2D" not in hero and '[sub_resource type="RectangleShape2D"' in hero
    assert "size = Vector2(4, 6)" in hero and "load_steps=4" in hero


def test_fins_de_ligne_crlf_conservees(projet):
    hud = projet / "scripts" / "hud.gd"
    hud.write_bytes(hud.read_bytes().replace(b"\n", b"\r\n"))
    assert appliquer(projet, {"op": "add_function", "script": "res://scripts/hud.gd",
                              "code": "func vide() -> void:\n\tpass"})["applique"]
    octets = hud.read_bytes()
    assert b"\r\n\r\n\r\nfunc vide() -> void:\r\n\tpass\r\n" in octets and b"\n" not in octets.replace(b"\r\n", b"")


@pytest.mark.parametrize("edit, fragment", [
    ({"op": "set_property", "noeud": "main:Coins/Coin9", "propriete": "visible", "valeur": False}, "id inconnu"),
    ({"op": "set_property", "noeud": "fantome", "propriete": "visible", "valeur": False}, "scène 'fantome' inconnue"),
    ({"op": "set_property", "noeud": "hud:VieLabel", "propriete": "couleur", "valeur": 1}, "propriété inconnue"),
    ({"op": "set_property", "noeud": "hud:VieLabel", "propriete": "text", "valeur": 3}, "chaîne attendue"),
    ({"op": "add_node", "parent": "main", "nom": "X", "type": "Sprite9D"}, "type de nœud inconnu"),
    ({"op": "add_node", "parent": "main", "nom": "Hero", "type": "Node"}, "déjà un enfant"),
    ({"op": "add_node", "parent": "main", "nom": "A/B", "type": "Node"}, "nom de nœud invalide"),
    ({"op": "del_node", "noeud": "main"}, "racine"),
    ({"op": "connect", "source": "main:WaveSpawner", "signal": "wave_lost", "cible": "main", "methode": "_on_wave_cleared"}, "signal inconnu"),
    ({"op": "connect", "source": "main:WaveSpawner", "signal": "wave_started", "cible": "main", "methode": "_absente"}, "méthode inconnue"),
    ({"op": "connect", "source": "main:WaveSpawner", "signal": "wave_started", "cible": "main", "methode": "_on_wave_cleared"}, "arité"),
    ({"op": "connect", "source": "main:WaveSpawner", "signal": "wave_cleared", "cible": "main", "methode": "_on_wave_cleared"}, "existe déjà"),
    ({"op": "connect", "source": "main:WaveSpawner", "signal": "wave_cleared", "cible": "hud", "methode": "hide"}, "même scène"),
    ({"op": "disconnect", "source": "main:WaveSpawner", "signal": "wave_cleared", "cible": "main:Hud", "methode": "hide"}, "connexion introuvable"),
    ({"op": "attach_script", "noeud": "main:Coins", "script": "res://scripts/hud.gd"}, "incompatible"),
    ({"op": "attach_script", "noeud": "main:Coins", "script": "res://scripts/absent.gd"}, "script introuvable"),
    ({"op": "add_signal", "script": "res://scripts/hero.gd", "signal": "dashed"}, "existe déjà"),
    ({"op": "add_signal", "script": "res://scripts/hero.gd", "signal": "ready"}, "existe déjà"),
    ({"op": "add_signal", "script": "res://scripts/hero.gd", "signal": "x", "arguments": [{"nom": "a", "type": "Vecteur2"}]}, "type inconnu"),
    ({"op": "add_function", "script": "res://scripts/hero.gd", "code": "func can_dash() -> bool:\n\treturn true"}, "existe déjà"),
    ({"op": "add_function", "script": "res://scripts/hero.gd", "code": "var x = 1"}, "func nom"),
    ({"op": "replace_function", "script": "res://scripts/hero.gd", "fonction": "voler", "corps": "pass"}, "fonction inconnue"),
    ({"op": "set_resource_value", "ressource": "coin:CollisionShape2D#shape", "propriete": "rayon", "valeur": 2}, "propriété inconnue"),
    ({"op": "set_resource_value", "ressource": "coin:CollisionShape2D#position", "propriete": "x", "valeur": 2}, "ne désigne pas une ressource"),
    ({"op": "renommer", "noeud": "main"}, "opération inconnue"),
])
def test_edit_faux_refuse_projet_intact(projet, edit, fragment):
    avant = empreinte_dossier(projet)
    v = appliquer(projet, {"op": "set_property", "noeud": "hud:VieLabel", "propriete": "visible", "valeur": False}, edit)
    assert not v["applique"] and v["etape"] == "validation"
    assert v["erreurs"][0]["edit"] == 1 and fragment in v["erreurs"][0]["message"], v["erreurs"]
    assert empreinte_dossier(projet) == avant


def test_remplacement_atomique_restaure_en_cas_d_echec(projet, monkeypatch):
    a, b = "res://scenes/hud.tscn", "res://scenes/coin.tscn"
    originaux = {a: lire(projet, "scenes/hud.tscn"), b: lire(projet, "scenes/coin.tscn")}
    vrai_replace = os.replace
    appels = []

    def replace_fragile(src, dst):
        appels.append(dst)
        if len(appels) == 2:
            raise OSError("disque plein (simulé)")
        return vrai_replace(src, dst)

    monkeypatch.setattr(editions.os, "replace", replace_fragile)
    with pytest.raises(OSError):
        editions._remplacer_atomiquement(projet, {a: "A", b: "B"}, originaux)
    monkeypatch.setattr(editions.os, "replace", vrai_replace)
    assert lire(projet, "scenes/hud.tscn") == originaux[a] and lire(projet, "scenes/coin.tscn") == originaux[b]
    assert not list(projet.rglob("*.usine_*"))


def test_conflit_si_le_fichier_a_change(projet):
    with pytest.raises(RuntimeError, match="a changé"):
        editions._remplacer_atomiquement(projet, {"res://scenes/hud.tscn": "X"}, {"res://scenes/hud.tscn": "autre"})


def test_demo_complete_avec_juge(capsys):
    assert demo(REFERENCE) == 0, capsys.readouterr().out
    sortie = capsys.readouterr().out
    assert sortie.count("=> CONFORME") == 3 and '"passes": 37' in sortie


def test_exemples_json_valides():
    for f in EXEMPLES.glob("*.json"):
        donnees = json.loads(f.read_text(encoding="utf-8"))
        assert donnees["edits"] and donnees["description"]
    ops = {e["op"] for e in json.loads((EXEMPLES / "demo_reference.json").read_text(encoding="utf-8"))["edits"]}
    assert ops == set(editions.OPERATIONS)
