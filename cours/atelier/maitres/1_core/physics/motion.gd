class_name Motion extends RefCounted
## Les calculs du déplacement d'un personnage, sans nœud : la vitesse horizontale qui rejoint celle voulue, la
## gravité, la vitesse d'un saut d'une hauteur donnée, et les deux tolérances qui rendent un saut agréable (sauter
## juste après avoir quitté un bord, et un appui un peu trop tôt gardé jusqu'à l'atterrissage).


## La vitesse horizontale (x, z) après `delta` secondes : elle rejoint `wish` (la direction voulue, longueur 0 à 1,
## fois la vitesse maximale) au rythme de l'accélération au sol ou en l'air ; sans direction voulue, au sol, elle
## freine ; en l'air, sans direction, elle garde son élan.
static func horizontal(velocity: Vector3, wish: Vector2, on_floor: bool, settings: MoveSettings, delta: float) -> Vector3:
	var current: Vector2 = Vector2(velocity.x, velocity.z)
	var target: Vector2 = wish.limit_length(1.0) * settings.max_speed
	var rate: float = settings.ground_acceleration if on_floor else settings.air_acceleration
	if wish.is_zero_approx():
		if not on_floor:
			return velocity
		rate = settings.friction
	var moved: Vector2 = current.move_toward(target, rate * delta)
	return Vector3(moved.x, velocity.y, moved.y)


## La vitesse verticale après `delta` secondes de gravité, sans dépasser la vitesse de chute maximale.
static func fall(vertical: float, settings: MoveSettings, delta: float) -> float:
	return maxf(vertical - settings.gravity * delta, -settings.max_fall_speed)


## La vitesse verticale de départ d'un saut qui monte de `settings.jump_height` sous `settings.gravity` :
## racine de 2 g h.
static func jump_speed(settings: MoveSettings) -> float:
	return sqrt(2.0 * settings.gravity * settings.jump_height)


## Vrai si un saut est permis : au sol, ou en l'air depuis moins de `coyote_time` secondes.
static func can_jump(on_floor: bool, time_since_floor: float, settings: MoveSettings) -> bool:
	return on_floor or time_since_floor <= settings.coyote_time


## Vrai si un appui sur saut fait il y a `time_since_press` secondes compte encore.
static func jump_buffered(time_since_press: float, settings: MoveSettings) -> bool:
	return time_since_press >= 0.0 and time_since_press <= settings.jump_buffer_time
