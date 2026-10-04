"""Lecture légère de GDScript (déclarations de premier niveau)."""

from usine.projet.gdscript import fin_bloc, lire_script, reindenter, unite_indentation

SCRIPT = '''class_name Exemple
extends Node2D
## Documentation de la classe.

signal touche(degats: int, source: Node)
signal fini

enum Etat { A, B }
const VITESSE := 3

@export var vie: int = 3
@onready var cible: Node2D = $Cible
var _interne := 0


func calcul(a: int, b: float = 1.0) -> float:
	var x := a * b
	# commentaire en colonne 0 dans le corps
	return x


## Doc de la suivante.
func longue(
		premier: int,
		second: String = "a,b") -> void:
	pass


func courte() -> int: return 1
static func outil(v) -> void:
	pass
'''


def test_declarations():
    s = lire_script(SCRIPT)
    assert s.class_name == "Exemple" and s.extends == "Node2D"
    assert [x.texte() for x in s.signaux] == ["signal touche(degats: int, source: Node)", "signal fini"]
    assert [v.nom for v in s.variables] == ["vie", "cible", "_interne"]
    assert s.variable("vie").exportee and not s.variable("_interne").exportee
    assert s.enums == ["Etat"] and s.constantes == ["VITESSE"]
    assert [f.nom for f in s.fonctions] == ["calcul", "longue", "courte", "outil"]
    calcul = s.fonction("calcul")
    assert calcul.signature() == "func calcul(a: int, b: float = 1.0) -> float"
    assert calcul.nb_obligatoires == 1 and len(calcul.arguments) == 2
    assert s.lignes[calcul.ligne_fin - 1].strip() == "return x"
    longue = s.fonction("longue")
    assert [a.nom for a in longue.arguments] == ["premier", "second"] and longue.arguments[1].defaut == '"a,b"'
    assert s.lignes[longue.ligne_debut - 1].startswith("## Doc")
    assert s.fonction("courte").une_ligne and s.fonction("outil").statique
    assert s.fin_entete == 3


def test_fin_bloc_exclut_commentaires_finaux():
    lignes = ["func a():\n", "\tpass\n", "\n", "## doc de b\n", "func b():\n"]
    assert fin_bloc(lignes, 1) == 2


def test_reindenter():
    assert unite_indentation(["func a():\n", "    pass\n"]) == "    "
    assert unite_indentation(["func a():\n", "\tpass\n"]) == "\t"
    code = "if x:\n    y()\nz()"
    assert reindenter(code, "\t", 1) == ["\tif x:\n", "\t\ty()\n", "\tz()\n"]
