"""Famille « erreur à l'exécution → correction » (B3) : scène lue, fautes, sortie lue, vraie paire."""

import pytest

from usine.cours.base import mutations
from usine.paires import execution

SCENE = """[gd_scene format=3]

[ext_resource type="Script" path="res://ui/affichage.gd" id="1_aff"]

[node name="Affichage" type="Control"]
script = ExtResource("1_aff")

[node name="Panel" type="PanelContainer" parent="."]

[node name="Rows" type="VBoxContainer" parent="Panel"]

[node name="Throttle" type="ProgressBar" parent="Panel/Rows"]

[node name="Buttons" type="Label" parent="Panel/Rows"]
"""

SCRIPT = """extends Control

@onready var _throttle: ProgressBar = $Panel/Rows/Throttle
@onready var _buttons: Label = $Panel/Rows/Buttons


func montrer(v: float) -> void:
	_throttle.value = v
"""

SORTIE = """Run Test Suite: res://7_tests/ui/test_affichage.gd
  res://7_tests/ui/test_affichage.gd > test_jauge STARTED
ERROR: Node not found: "Panel/Throttle" (relative to "/root/test_affichage/Affichage").
   at: get_node (scene/main/node.cpp:1975)
   GDScript backtrace (most recent call first):
       [0] @implicit_ready (res://ui/affichage.gd:3)
       [1] before_test (res://7_tests/ui/test_affichage.gd:11)
SCRIPT ERROR: Invalid assignment of property or key 'value' with value of type 'float' on a base object of type 'null instance'.
   at: Affichage.montrer (res://ui/affichage.gd:8)
   GDScript backtrace (most recent call first):
       [0] montrer (res://ui/affichage.gd:8)
"""


def _apres():
    return {"ui/affichage.gd": SCRIPT, "ui/affichage.tscn": SCENE}


def test_la_scene_donne_le_porteur_et_les_chemins():
    ns = execution.noeuds(SCENE)
    porteur = next(n for n in ns if n.script == "ui/affichage.gd")
    assert porteur.chemin == "" and porteur.nom == "Affichage"
    chemins = {execution.relatif(porteur, n) for n in ns} - {None}
    assert chemins == {"Panel", "Panel/Rows", "Panel/Rows/Throttle", "Panel/Rows/Buttons"}


def test_les_fautes_ne_menent_a_aucun_noeud():
    ms = execution.candidates(_apres(), "ui/affichage.gd")
    variantes = {(m.ligne, m.genre, m.detail.get("variante")) for m in ms}
    assert (3, "chemin_noeud", "segment") in variantes and (3, "chemin_noeud", "casse") in variantes
    assert (3, "chemin_noeud", "nom_par_defaut") in variantes
    # Label → RichTextLabel : hors de la lignée de Label (extension_api.json), l'affectation échoue.
    t = next(m for m in ms if m.genre == "type_noeud" and m.ligne == 4)
    assert t.apres == "@onready var _buttons: RichTextLabel = $Panel/Rows/Buttons"
    seg = next(m for m in ms if m.detail.get("variante") == "segment" and m.ligne == 3)
    assert seg.apres.endswith("$Panel/Throttle") and seg.detail["faux"] not in {"Panel", "Panel/Rows"}


def test_la_premiere_erreur_vient_de_la_pile_et_ses_suites_sont_des_consequences():
    e = execution.premiere_erreur(SORTIE)
    assert (e.fichier, e.ligne, e.fonction, e.moteur) == ("ui/affichage.gd", 3, "@implicit_ready", "scene/main/node.cpp")
    m = mutations.Mutation("chemin_noeud", "ui/affichage.gd", 3, "", "", {"faux": "Panel/Throttle"})
    assert execution.message_attendu(m, e)
    assert [(f, n) for f, n, _ in execution.consequences(SORTIE, m)] == [("ui/affichage.gd", 8)]


def test_le_bandeau_de_gdunit_part_et_rien_d_autre():
    bandeau = ("-----\nGdUnit4 Comandline Tool\n-----\nDisabled fail fast!\nSession hook 'Silence audio' installed.\n")
    assert execution.sans_bandeau(bandeau + SORTIE) == SORTIE.rstrip("\n")
    autre = "ERROR: quelque chose\n" + SORTIE
    assert execution.sans_bandeau(autre) == autre.rstrip("\n")


def test_la_recherche_n_a_pas_de_guillemet():
    m = mutations.Mutation("chemin_noeud", "ui/affichage.gd", 3, "", "",
                           {"scene": "ui/affichage.tscn", "variante": "casse", "faux": "Panel/Rows/throttle",
                            "nom": "Throttle", "type": "ProgressBar"})
    args, commande = execution.recherche(m)
    assert args == ["-ni", "name=.throttle.", "ui/affichage.tscn"] and '"' not in commande


@pytest.mark.godot
def test_godot_une_paire_d_execution_verifiee():
    from usine.cours.base import chemins, creation, sessions
    chemins.configurer(cours="kart")
    _, apres = creation.etats("kart", 4)
    rel = "4_ui/hud/input_display/input_display.gd"
    m = next(x for x in execution.candidates(apres, rel) if x.detail.get("variante") == "segment" and x.ligne == 6)
    p, raison = execution.paire(sessions.Projet("kart", 4, apres), m, execution.suites_pour(apres, rel), "UI")
    assert p is not None, raison
    systeme, demande, reponse = (x["content"] for x in p["messages"])
    assert systeme.startswith("# EN PERMANENCE") and p["jetons"] <= execution.PLAFOND
    assert 'Node not found: "Panel/Throttle"' in demande and "grep -n 'name=.Throttle.'" in demande
    assert "il manque `Rows`" in reponse and "ligne 6" in reponse
    if p["preuve"]["mode"] == "tests":  # la suite appelle show_commands : la ligne 13 plante ensuite
        assert "C'est la ligne 6 qu'il faut corriger, pas la ligne 13" in reponse
    else:
        assert "lancée sans fenêtre" in demande and "**Tester.** Je relance la scène" in reponse
    assert reponse.index(m.avant) > reponse.index("je remplace")  # règle 7.3
