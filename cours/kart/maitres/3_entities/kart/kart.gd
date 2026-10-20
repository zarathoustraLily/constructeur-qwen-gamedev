class_name Kart extends CharacterBody3D
## Le kart : il roule, tourne, freine et saute selon ses commandes de conduite (DriveCommands), avec les
## réglages de `settings` (5_data/kart/kart_settings.tres). Il ne lit jamais Input : son adaptateur
## d'entrées (KartInput) lui donne les commandes à chaque image physique ; sans adaptateur, un test ou un
## pilote automatique les écrit dans `commands`. Au sol, le moteur pousse le long de l'axe du kart et la
## vitesse de côté est effacée : le kart ne glisse pas. En l'air, la gravité le ramène. Le modèle, les roues
## et le volant sont animés par la présentation (kart_view.gd), qui lit cet état sans le changer.

## Émis quand le kart quitte le sol par un saut.
signal jumped

## Réglages de conduite.
@export var settings: KartSettings
## Adaptateur d'entrées ; vide, le kart garde les commandes qu'on lui écrit.
@export var input: KartInput

## Commandes de l'image en cours.
var commands: DriveCommands = DriveCommands.new()
## Braquage effectif, de -1 à 1, lissé vers le braquage demandé.
var steering: float = 0.0


func _ready() -> void:
	if settings == null:
		push_error("Kart : réglages de conduite (settings) absents")


## Vrai si le kart touche le sol.
func is_on_ground() -> bool:
	return is_on_floor()


## Vitesse sans sa composante verticale.
func get_horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


## Vitesse le long de l'axe du kart : positive en marche avant, négative en marche arrière.
func forward_speed() -> float:
	var horizontal := get_horizontal_velocity()
	return horizontal.length() * signf(horizontal.dot(-global_basis.z))


## Angle de braquage maximal (en degrés) à la vitesse `speed` : large à l'arrêt, serré à la vitesse de pointe.
func max_steering_angle(speed: float) -> float:
	return lerpf(settings.max_steering_angle_slow, settings.max_steering_angle_fast,
		clampf(speed / settings.top_speed, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	if input != null:
		commands = input.read()
	apply_steering(delta)
	if is_on_ground():
		apply_engine(delta)
		if commands.jump:
			velocity.y += settings.jump_velocity
			jumped.emit()
	else:
		apply_air(delta)
	move_and_slide()
	_push_rigid_bodies()


## Direction, pendant `delta` secondes. Le braquage rejoint en douceur celui demandé. Au sol, le kart tourne
## comme une voiture : la vitesse de rotation vaut vitesse × tan(angle) / empattement, et à l'arrêt il ne
## tourne pas, sauf en freinant (rotation sur place). En l'air, il tourne à vitesse fixe.
func apply_steering(delta: float) -> void:
	var speed := forward_speed()
	steering = lerpf(steering, commands.steering, 1.0 - exp(-settings.steering_response * delta))
	var angular_velocity := deg_to_rad(settings.air_steering_velocity * steering)
	if is_on_ground():
		if commands.brake and absf(speed) < settings.handbrake_max_speed:
			angular_velocity = deg_to_rad(settings.handbrake_steering_velocity * steering)
		else:
			var steering_angle := 0.0
			if absf(speed) > settings.steering_min_speed:
				steering_angle = max_steering_angle(speed) * steering
			angular_velocity = speed * tan(deg_to_rad(steering_angle)) / settings.wheel_base
	rotate_y(-delta * angular_velocity)


## Moteur, au sol, pendant `delta` secondes : la résistance au roulement freine toujours un peu, la vitesse
## est ramenée sur l'axe du kart, puis le frein, ou les gaz jusqu'à la vitesse de pointe (en avant) ou
## jusqu'à la vitesse maximale en arrière.
func apply_engine(delta: float) -> void:
	var forward := -global_basis.z
	var horizontal := get_horizontal_velocity()
	horizontal = horizontal.lerp(Vector3.ZERO, 1.0 - exp(-settings.rolling_decay * delta))
	var speed := horizontal.length()
	horizontal = forward * forward.dot(horizontal)
	if commands.brake:
		horizontal = horizontal.lerp(Vector3.ZERO, 1.0 - exp(-settings.braking_decay * delta))
	elif commands.throttle > 0.0 and speed < settings.top_speed:
		horizontal += commands.throttle * forward * delta * settings.acceleration
	elif commands.throttle < 0.0 and speed < settings.top_reverse_speed:
		horizontal += commands.throttle * forward * delta * settings.acceleration
	velocity = horizontal + Vector3.UP * velocity.y


## En l'air, pendant `delta` secondes : la vitesse reste sur l'axe du kart, et la gravité la tire vers le bas.
func apply_air(delta: float) -> void:
	var forward := -global_basis.z
	var horizontal := forward * forward.dot(get_horizontal_velocity())
	velocity = horizontal + Vector3.UP * velocity.y + Vector3.DOWN * settings.gravity * delta


func _push_rigid_bodies() -> void:
	for index: int in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body := collision.get_collider() as RigidBody3D
		if body != null:
			body.apply_central_impulse(-collision.get_normal() * settings.push_impulse)
