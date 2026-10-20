class_name Kart extends CharacterBody3D
## Le kart : il roule, tourne, freine et saute selon ses commandes de conduite (DriveCommands), avec les
## réglages de `settings` (5_data/kart/kart_settings.tres). Il ne lit jamais Input : son adaptateur
## d'entrées (KartInput) lui donne les commandes à chaque image physique ; sans adaptateur, un test ou un
## pilote automatique les écrit dans `commands`. Au sol, le moteur pousse le long de l'axe du kart et la
## vitesse de côté est effacée : le kart ne glisse pas. En l'air, la gravité le ramène. Le modèle, les roues
## et le volant sont animés par la présentation (kart_view.gd), qui lit cet état sans le changer.
#@ 7+
## Sur l'eau, il roule comme au sol : son capteur de flottaison (WaterBuoyancySensor) lit la surface, et le
## kart est ramené à `water_ride_height` au-dessus d'elle.
#@ 10+
## Il dérape : un saut en braquant, gaz ouverts, lance le dérapage, qui monte de niveau avec le temps ; le
## relâcher au deuxième ou au troisième niveau donne un turbo. En l'air, un saut fait une figure, et
## l'atterrissage après une figure donne aussi un turbo. Il signale chaque changement (dérapage, turbo,
## figure) : sa présentation et ses effets l'écoutent.
#@ all

## Émis quand le kart quitte le sol par un saut.
signal jumped
#@ 10+
## Émis quand le niveau de dérapage change.
signal drift_stage_changed(stage: DriftStage)
## Émis quand un turbo commence (vrai), et quand il s'arrête (faux).
signal boost_changed(active: bool)
## Émis quand le kart fait une figure en l'air.
signal tricked

## Niveaux de dérapage : aucun, glissade, étincelles, étincelles chaudes.
enum DriftStage { NONE, SLIDING, SPARKS, HOT_SPARKS }
#@ all

## Réglages de conduite.
@export var settings: KartSettings
## Adaptateur d'entrées ; vide, le kart garde les commandes qu'on lui écrit.
@export var input: KartInput
#@ 7+
## Capteur de flottaison, sous le kart.
@export var water_sensor: WaterBuoyancySensor
#@ all

## Commandes de l'image en cours.
var commands: DriveCommands = DriveCommands.new()
## Braquage effectif, de -1 à 1, lissé vers le braquage demandé.
var steering: float = 0.0
#@ 7+
## Temps passé dans l'eau depuis l'arrivée ou le dernier saut (s).
var in_water_time: float = 0.0
#@ 10+
## Vrai pendant un dérapage.
var drifting: bool = false
## Sens du dérapage : -1 à gauche, 1 à droite.
var drift_direction: float = 0.0
## Durée du dérapage en cours, au sol (s).
var drift_time: float = 0.0
## Niveau du dérapage en cours.
var drift_stage: DriftStage = DriftStage.NONE
## Temps de turbo restant (s).
var boost_time: float = 0.0
## Temps restant avant de pouvoir faire une figure (s).
var trick_cooldown_left: float = 0.0
## Vrai entre une figure et l'atterrissage.
var has_tricked: bool = false
#@ all


func _ready() -> void:
	if settings == null:
		push_error("Kart : réglages de conduite (settings) absents")


#@ 2-6
## Vrai si le kart touche le sol.
func is_on_ground() -> bool:
	return is_on_floor()
#@ 7+
## Vrai si le kart touche le sol ou l'eau : sur l'eau, il roule comme au sol.
func is_on_ground() -> bool:
	return is_on_floor() or is_in_water()


## Vrai si le capteur de flottaison est dans l'eau.
func is_in_water() -> bool:
	return water_sensor != null and water_sensor.is_in_water()
#@ all


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
#@ 10+
	update_drift(delta)
	update_boost(delta)
#@ all
	apply_steering(delta)
#@ 7+
	apply_water(delta)
#@ all
#@ 10+
	if not is_on_ground() and commands.jump and trick_cooldown_left <= 0.0:
		has_tricked = true
		trick_cooldown_left = settings.trick_cooldown
		tricked.emit()
#@ all
	if is_on_ground():
		apply_engine(delta)
		if commands.jump:
			velocity.y += settings.jump_velocity
#@ 10+
			# Pas de figure juste après un saut depuis le sol (l'eau n'en empêche pas).
			if not is_in_water():
				trick_cooldown_left = settings.trick_cooldown
#@ 7+
			in_water_time = 0.0
#@ all
			jumped.emit()
	else:
		apply_air(delta)
	move_and_slide()
	_push_rigid_bodies()
#@ 10+


## Dérapage, pendant `delta` secondes. Il commence par un saut, en braquant, gaz ouverts, dans le sens du
## braquage ; il s'arrête quand on relâche le saut ou les gaz, avec un turbo s'il avait atteint les
## étincelles. Au sol, il passe en glissade, puis aux étincelles après `drift_sparks_time`, puis aux
## étincelles chaudes après `drift_hot_sparks_time`. L'atterrissage après une figure donne un turbo.
func update_drift(delta: float) -> void:
	if commands.jump and absf(commands.steering) > 0.0 and commands.throttle > 0.0:
		drifting = true
		drift_direction = signf(commands.steering)
		drift_time = 0.0
		_set_drift_stage(DriftStage.NONE)
	if drifting and (commands.jump_released or commands.throttle <= 0.0):
		drifting = false
		if drift_stage == DriftStage.SPARKS:
			set_boost(settings.drift_boost_short)
		elif drift_stage == DriftStage.HOT_SPARKS:
			set_boost(settings.drift_boost_long)
		_set_drift_stage(DriftStage.NONE)
	if has_tricked and is_on_ground():
		set_boost(settings.trick_boost)
		has_tricked = false
	if drifting and is_on_ground():
		if drift_stage == DriftStage.NONE:
			_set_drift_stage(DriftStage.SLIDING)
		if drift_time > settings.drift_sparks_time and drift_stage == DriftStage.SLIDING:
			_set_drift_stage(DriftStage.SPARKS)
		drift_time += delta
		if drift_time > settings.drift_hot_sparks_time and drift_stage == DriftStage.SPARKS:
			_set_drift_stage(DriftStage.HOT_SPARKS)


## Turbo et délai des figures, pendant `delta` secondes : le turbo s'use, et le délai des figures ne court
## qu'une fois le kart reposé.
func update_boost(delta: float) -> void:
	if boost_time > 0.0:
		boost_time -= delta
		if boost_time <= 0.0:
			boost_changed.emit(false)
	if trick_cooldown_left > 0.0 and not has_tricked:
		trick_cooldown_left -= delta


## Donne `seconds` secondes de turbo, sans raccourcir un turbo en cours plus long.
func set_boost(seconds: float) -> void:
	if boost_time <= 0.0:
		boost_changed.emit(true)
	boost_time = maxf(boost_time, seconds)


## Vrai pendant un turbo.
func is_boosting() -> bool:
	return boost_time > 0.0


func _set_drift_stage(stage: DriftStage) -> void:
	if drift_stage != stage:
		drift_stage = stage
		drift_stage_changed.emit(stage)
#@ all


## Direction, pendant `delta` secondes. Le braquage rejoint en douceur celui demandé. Au sol, le kart tourne
## comme une voiture : la vitesse de rotation vaut vitesse × tan(angle) / empattement, et à l'arrêt il ne
## tourne pas, sauf en freinant (rotation sur place). En l'air, il tourne à vitesse fixe.
#@ 10+
## En dérapage, l'angle penche vers le sens du dérapage, que le braquage ne fait que moduler, et s'élargit.
#@ all
func apply_steering(delta: float) -> void:
	var speed := forward_speed()
	steering = lerpf(steering, commands.steering, 1.0 - exp(-settings.steering_response * delta))
	var angular_velocity := deg_to_rad(settings.air_steering_velocity * steering)
	if is_on_ground():
		if commands.brake and absf(speed) < settings.handbrake_max_speed:
			angular_velocity = deg_to_rad(settings.handbrake_steering_velocity * steering)
		else:
			var steering_angle := 0.0
#@ 10+
			if drifting:
				var weight := settings.drift_direction_weight
				steering_angle = settings.drift_steering_multiplier * max_steering_angle(speed) \
					* (drift_direction * weight + (1.0 - weight) * steering)
			elif absf(speed) > settings.steering_min_speed:
#@ 2-9
			if absf(speed) > settings.steering_min_speed:
#@ all
				steering_angle = max_steering_angle(speed) * steering
			angular_velocity = speed * tan(deg_to_rad(steering_angle)) / settings.wheel_base
	rotate_y(-delta * angular_velocity)


## Moteur, au sol, pendant `delta` secondes : la résistance au roulement freine toujours un peu, la vitesse
## est ramenée sur l'axe du kart, puis le frein, ou les gaz jusqu'à la vitesse de pointe (en avant) ou
## jusqu'à la vitesse maximale en arrière.
#@ 10+
## Pendant un turbo, le kart accélère tout seul, plus fort, jusqu'à `boost_speed`.
#@ all
func apply_engine(delta: float) -> void:
	var forward := -global_basis.z
	var horizontal := get_horizontal_velocity()
	horizontal = horizontal.lerp(Vector3.ZERO, 1.0 - exp(-settings.rolling_decay * delta))
	var speed := horizontal.length()
	horizontal = forward * forward.dot(horizontal)
	if commands.brake:
		horizontal = horizontal.lerp(Vector3.ZERO, 1.0 - exp(-settings.braking_decay * delta))
#@ 10+
	elif is_boosting() and speed < settings.boost_speed:
		horizontal += forward * delta * settings.boost_acceleration
#@ all
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


#@ 7+
## Sur l'eau, pendant `delta` secondes. Pendant `water_settle_time`, un ressort rappelle le kart vers sa
## hauteur de flottaison (la surface plus `water_ride_height`) : raide quand il s'enfonce, doux quand il
## remonte ; il rebondit à l'arrivée. Après `water_stick_delay`, il est en plus collé à cette hauteur, de plus
## en plus fort, et sa vitesse verticale s'éteint.
func apply_water(delta: float) -> void:
	if not is_in_water():
		in_water_time = 0.0
		return
	in_water_time += delta
	var ride_height := water_sensor.get_water_height() + settings.water_ride_height
	var sticking := clampf(in_water_time / settings.water_settle_time, 0.0, 1.0)
	if in_water_time >= settings.water_stick_delay:
		global_position.y = lerpf(global_position.y, ride_height,
			1.0 - exp(-settings.water_stick_rate * sticking * delta))
		velocity.y = lerpf(velocity.y, 0.0, 1.0 - exp(-settings.water_vertical_damping * (1.0 - sticking) * delta))
	if in_water_time < settings.water_settle_time:
		var stiffness := settings.water_spring_down if velocity.y < 0.0 else settings.water_spring_up
		velocity.y += (ride_height - global_position.y) * stiffness * delta
#@ all


func _push_rigid_bodies() -> void:
	for index: int in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body := collision.get_collider() as RigidBody3D
		if body != null:
			body.apply_central_impulse(-collision.get_normal() * settings.push_impulse)
