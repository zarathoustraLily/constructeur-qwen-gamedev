extends Node
## BPC_Global.gd
## Autoload : état global du jeu.

# Niveau actuel
var niveau_actuel: int = 1
var profondeur: int = 0

# Stats de la run
var ennemis_tues: int = 0
var boss_tues: int = 0
var degats_infliges: int = 0
var degats_subis: int = 0

# Run terminée ?
var run_terminee: bool = false


func reinitialiser() -> void:
	niveau_actuel = 1
	profondeur = 0
	ennemis_tues = 0
	boss_tues = 0
	degats_infliges = 0
	degats_subis = 0
	run_terminee = false


func incrementer_profondeur() -> void:
	profondeur += 1


func enregister_degrats_infliges(montant: int) -> void:
	degats_infliges += montant


func enregister_degrats_subis(montant: int) -> void:
	degats_subis += montant


func enregister_mort_ennemi() -> void:
	ennemis_tues += 1


func enregister_mort_boss() -> void:
	boss_tues += 1
