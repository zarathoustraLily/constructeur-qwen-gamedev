class_name BPC_AggroSense
extends RefCounted
## BPC_AggroSense.gd
## Le sous-arbre MARQUER (ciblage).

var mark: Node = null
var distance_max: float = 600.0
var distance_min: float = 0.0


func _init(distance_max_val: float = 600.0, distance_min_val: float = 0.0) -> void:
	distance_max = distance_max_val
	distance_min = distance_min_val


## Marquer une cible.
func marquer(cible: Node) -> void:
	mark = cible


## Retirer la marque.
func retirer_marque() -> void:
	mark = null


## La cible est-elle en portée ?
func en_portee(position_cible: Vector3, position_ennemi: Vector3) -> bool:
	if not mark:
		return false
	var dist: float = (position_cible - position_ennemi).length()
	return dist <= distance_max and dist >= distance_min


## La cible est-elle morte ?
func cible_morte() -> bool:
	if not mark:
		return true
	if mark.has_method("est_mort"):
		return mark.est_mort()
	return not is_instance_valid(mark)
