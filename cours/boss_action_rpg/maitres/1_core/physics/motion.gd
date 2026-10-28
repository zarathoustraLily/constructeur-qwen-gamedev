class_name Motion extends RefCounted
## Les calculs du déplacement, sans nœud : la direction voulue tournée selon la caméra, la vitesse qui la rejoint, le
## corps qui pivote vers sa marche. Des fonctions pures se testent sans scène et ne cachent aucun état.


## La direction au sol (x, z) que vise le stick `stick` (x : droite, y : arrière, longueur 0 à 1) quand la caméra
## regarde avec le lacet `camera_yaw` : pousser le stick vers le haut avance là où la caméra regarde.
static func camera_relative(stick: Vector2, camera_yaw: float) -> Vector3:
	var flat: Vector3 = Vector3(stick.x, 0.0, stick.y).limit_length(1.0)
	return flat.rotated(Vector3.UP, camera_yaw)


## La vitesse horizontale après `delta` secondes : elle rejoint `target` (x, z) au rythme de `acceleration`, ou de
## `deceleration` quand la cible est l'arrêt ; la vitesse verticale n'est pas touchée.
static func approach(velocity: Vector3, target: Vector3, acceleration: float, deceleration: float, delta: float) -> Vector3:
	var current: Vector2 = Vector2(velocity.x, velocity.z)
	var goal: Vector2 = Vector2(target.x, target.z)
	var rate: float = deceleration if goal.is_zero_approx() else acceleration
	var moved: Vector2 = current.move_toward(goal, rate * delta)
	return Vector3(moved.x, velocity.y, moved.y)


## Le lacet du corps après `delta` secondes : il tourne vers `direction` (x, z) par le plus court chemin, au plus de
## `turn_speed` radians par seconde ; sans direction, il ne bouge pas. L'avant d'un nœud de Godot est son -Z : le
## lacet qui le fait regarder vers (x, z) est atan2(-x, -z).
static func face(yaw: float, direction: Vector3, turn_speed: float, delta: float) -> float:
	if Vector2(direction.x, direction.z).is_zero_approx():
		return yaw
	var target: float = atan2(-direction.x, -direction.z)
	var gap: float = angle_difference(yaw, target)
	return yaw + clampf(gap, -turn_speed * delta, turn_speed * delta)
