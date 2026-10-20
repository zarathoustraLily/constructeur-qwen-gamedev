class_name BPC_PhaseManager
extends RefCounted
## BPC_PhaseManager.gd
## L'ARBRE DE DÉCISION principal.

enum Etat {
	ATTENTE,
	MARQUER,
	AVANCER,
	FRAPPER,
	REPLI,
	MORT,
}

var etat: int = Etat.ATTENTE
var stades: Array = []
var stade_actuel: int = 0
var pv_courant: int = 100
var pv_max: int = 100


func _init(stades_val: Array = []) -> void:
	stades = stades_val


## Lancer un tick de l'arbre de décision.
func tick(
	pv_courant_val: int,
	position_ennemi: Vector3,
	position_cible: Vector3,
	cible_valide: bool
) -> String:
	pv_courant = pv_courant_val
	# Vérifier les stades.
	_verifier_stades()
	# Arbre de décision.
	match etat:
		Etat.ATTENTE:
			if cible_valide:
				etat = Etat.MARQUER
				return "S_MARQUER"
			return "S_ATTENTE"
		Etat.MARQUER:
			var dist: float = (position_cible - position_ennemi).length()
			if dist > 600.0:
				etat = Etat.REPLI
				return "S_REPLI"
			etat = Etat.AVANCER
			return "S_AVANCER"
		Etat.AVANCER:
			var dist: float = (position_cible - position_ennemi).length()
			if dist <= 120.0:
				etat = Etat.FRAPPER
				return "S_FRAPPER"
			return "S_AVANCER"
		Etat.FRAPPER:
			etat = Etat.AVANCER
			return "S_FRAPPER"
		Etat.REPLI:
			etat = Etat.ATTENTE
			return "S_REPLI"
		Etat.MORT:
			return "S_MORT"
	return "S_INCONNU"


## Vérifier les stades (phases de boss).
func _verifier_stades() -> void:
	if stades.is_empty():
		return
	var fraction: float = float(pv_courant) / float(pv_max)
	for i in range(stades.size() - 1, -1, -1):
		var seuil: float = stades[i].get("seuil", 1.0)
		if fraction <= seuil:
			if i != stade_actuel:
				stade_actuel = i
			break
