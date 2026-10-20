class_name BPC_DirectorRun
extends Node
## BPC_DirectorRun.gd
## Le directeur de run : génération de salles, encounters.

var fiche_heros: FicheHeros
var fiches_ennemis: Array = []
var fiches_salles: Array = []
var salle_actuelle: FicheSalle = null
var run_terminé: bool = false


func _ready() -> void:
	pass


## Démarrer un nouveau run.
func demarrer_run() -> void:
	run_terminé = false
	# Générer la première salle.
	var salle := _generer_salle()
	salle_actuelle = salle


## Passer à la salle suivante.
func salle_suivante() -> void:
	if run_terminé:
		return
	var salle := _generer_salle()
	salle_actuelle = salle


## Terminer le run.
func terminer_run() -> void:
	run_terminé = true


## Générer une salle aléatoire.
func _generer_salle() -> FicheSalle:
	if fiches_salles.is_empty():
		return null
	var index: int = randi() % fiches_salles.size()
	var fiche: FicheSalle = fiches_salles[index]
	# Ici, on instancierait la scène de salle.
	# Pour la preuve, on retourne juste la fiche.
	return fiche


## Calculer la difficulté d'un encounter.
func calculer_difficulte(profondeur: int, difficulte_base: int, ramp: float) -> int:
	return int(difficulte_base + float(profondeur) * ramp)


## Calculer le coût d'une porte secrète.
func cout_porte_secrete(profondeur: int) -> int:
	if not fiche_heros:
		return 10
	return int(fiche_heros.cout_porte_secrete_base + float(profondeur) * fiche_heros.cout_porte_secrete_ramp)
