"""Famille « écrire une fonction d'après son contrat » (D1) : contexte montré, palier, masque, vraie paire."""

import pytest

from usine.paires import creation
from usine.projet.gdscript import lire_script

SCRIPT = """class_name Compteur extends Node
## Compte des points.

## Points gagnés.
var points: int = 0
## Réglages.
@export var reglages: ReglagesCompteur

var _bonus: float = 1.5


## Ajoute `n` points, multipliés par le bonus.
func ajouter(n: int) -> void:
	points += roundi(n * _bonus)
	_signaler()


## Remet les points à zéro selon les réglages.
func remettre() -> void:
	points = reglages.depart
	_signaler()


func _signaler() -> void:
	pass
"""

REGLAGES = """class_name ReglagesCompteur extends Resource
## Points au départ.
@export var depart: int = 0
"""


def _f(nom):
	return lire_script(SCRIPT).fonction(nom)


def test_le_contexte_minimal_garde_ce_que_la_fonction_emploie():
	c = creation.contexte_minimal(SCRIPT, _f("ajouter"))
	assert c.startswith("class_name Compteur extends Node")
	assert "var points: int = 0" in c and "var _bonus: float = 1.5" in c and "## Points gagnés." in c
	assert "func _signaler() -> void:\n\t…" in c and creation.TROU in c
	assert "reglages" not in c and "func remettre" not in c


def test_le_plan_compte_des_qu_une_dependance_declaree_sert():
	apres = {"compteur.gd": SCRIPT, "reglages.gd": REGLAGES}
	lignes = SCRIPT.split("\n")
	assert creation.sans_convention(creation.texte_fonction(lignes, _f("ajouter")), apres, SCRIPT)
	assert not creation.sans_convention(creation.texte_fonction(lignes, _f("remettre")), apres, SCRIPT)
	ailleurs = creation.employes_ailleurs(SCRIPT, _f("remettre"), apres)
	assert "`res://reglages.gd` (ReglagesCompteur)" in ailleurs and "@export var depart: int = 0" in ailleurs


def test_le_script_a_trou_et_le_masque():
	trou = creation.script_a_trou(SCRIPT, "ajouter")
	assert creation.TROU in trou and "roundi" not in trou and "\t…" in trou
	masques = creation.masque(SCRIPT, _f("ajouter"))
	# Le paramètre garde son nom (un `_n` pourrait masquer une variable de classe) ; les avertissements du vidage
	# sont ignorés après l'en-tête.
	assert "func ajouter(n: int) -> void:" in masques[-1] and "roundi" not in masques[-1]
	assert '@warning_ignore_start("unused_parameter"' in masques[-1].split("func ")[0]


def test_seules_les_fonctions_documentees_sont_candidates():
	noms = {f.nom for f in creation.candidates({"compteur.gd": SCRIPT}, "compteur.gd")}
	assert noms == {"ajouter", "remettre"}


@pytest.mark.godot
def test_godot_une_paire_de_creation_verifiee():
	from usine.cours.base import chemins, creation as etats, sessions
	from usine.paires.execution import suites_pour
	chemins.configurer(cours="kart")
	_, apres = etats.etats("kart", 5)
	rel = "1_core/camera/camera_input.gd"
	f = lire_script(apres[rel]).fonction("set_captured")
	p, raison = creation.paire(sessions.Projet("kart", 5, apres), rel, f, suites_pour(apres, rel), "UI", {})
	assert p is not None, raison
	assert p["preuve"]["palier"] == 1 and p["messages"][0]["role"] == "user" and p["jetons"] <= 1024
	reponse = p["messages"][-1]["content"]
	assert "Input.mouse_mode" in reponse and "--check-only" in reponse and "GdUnitCmdTool" in reponse
