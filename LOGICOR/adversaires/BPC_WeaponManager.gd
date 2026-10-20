class_name BPC_WeaponManager
extends RefCounted
## BPC_WeaponManager.gd
## Le sous-arbre OUTILLER (choix d'arme).

var outils: Array = []
var outil_actuel: String = ""


func _init(outils_val: Array = []) -> void:
	outils = outils_val


## Choisir l'outil à utiliser.
func choisir(distance: float, pv_cible: int, pv_max_cible: int) -> String:
	if outils.is_empty():
		return ""
	# 5 priorités :
	# 1. force_interrompre
	# 2. force_suivant
	# 3. enchaîne
	# 4. combo_actif
	# 5. options_arme
	for outil in outils:
		var nom: String = outil.get("nom", "")
		var when: String = outil.get("when", "toujours")
		var portee: float = outil.get("portee", 100.0)
		# Vérifier la condition.
		if _condition_verifiee(when, distance, pv_cible, pv_max_cible):
			# Vérifier la portée.
			if distance <= portee:
				outil_actuel = nom
				return nom
	# Retourner l'outil actuel par défaut.
	return outil_actuel


## Vérifier une condition.
func _condition_verifiee(when: String, distance: float, pv_cible: int, pv_max_cible: int) -> bool:
	match when:
		"toujours":
			return true
		"de_loin":
			return distance > 300.0
		"de_pret":
			return distance < 200.0
		"pv_bas":
			return pv_cible < int(float(pv_max_cible) * 0.3)
		"pv_haut":
			return pv_cible > int(float(pv_max_cible) * 0.7)
		_:
			return true
