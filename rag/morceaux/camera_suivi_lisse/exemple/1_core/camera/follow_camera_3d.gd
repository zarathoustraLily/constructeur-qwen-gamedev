class_name FollowCamera3D
extends Camera3D
## Caméra qui suit sa cible avec retard. Le lissage ne dépend pas de la cadence d'images : chaque pas rapproche la
## caméra d'une part 1 - exp(-smoothing × delta) du chemin qui reste. Présentation : elle bouge dans _process.
## Entrées : setup().

## Place de la caméra par rapport à la cible.
@export var offset: Vector3 = Vector3.ZERO
## Vitesse du rattrapage, par seconde : plus elle est grande, plus la caméra colle à la cible.
@export var smoothing: float = 0.0

var _target: Node3D


func setup(target: Node3D) -> void:
	_target = target
	global_position = target.global_position + offset


func _process(delta: float) -> void:
	if _target != null:
		follow(delta)


## Un pas de suivi, de durée `delta`.
func follow(delta: float) -> void:
	var place := _target.global_position + offset
	global_position = global_position.lerp(place, 1.0 - exp(-smoothing * delta))
