class_name LockOn extends RefCounted
## Choisir la cible à verrouiller, et les angles qui la regardent. Une cible se déclare en entrant dans le groupe
## « lockable » ; le choix ne dépend que des positions : il se teste sans scène.

## Le groupe des nœuds qu'on peut verrouiller.
const GROUP: StringName = &"lockable"


## La cible à verrouiller parmi `candidates`, vue depuis `from` en regardant vers `forward` (x, z) : la plus proche
## qui est à moins de `max_distance` et devant (moins de 90° de l'avant) ; null s'il n'y en a aucune.
static func pick(from: Vector3, forward: Vector3, candidates: Array[Node3D], max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_distance: float = INF
	var ahead: Vector2 = Vector2(forward.x, forward.z).normalized()
	for candidate: Node3D in candidates:
		var offset: Vector3 = candidate.global_position - from
		var distance: float = offset.length()
		if distance > max_distance or distance >= best_distance:
			continue
		if ahead.dot(Vector2(offset.x, offset.z).normalized()) < 0.0:
			continue
		best = candidate
		best_distance = distance
	return best


## Les angles (x : lacet, y : inclinaison, en radians) d'une caméra en `from` qui regarde `to` : lacet de l'axe -Z,
## inclinaison positive vers le bas.
static func look_angles(from: Vector3, to: Vector3) -> Vector2:
	var offset: Vector3 = to - from
	var flat: float = Vector2(offset.x, offset.z).length()
	return Vector2(atan2(-offset.x, -offset.z), atan2(-offset.y, flat))
