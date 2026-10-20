class_name WheelSplashEffects extends Node3D

## Éclaboussures et traînées des roues : très fortes sur la mer, légères sur la route mouillée.
## Les enfants SeaDroplets / SeaSpray / RoadDroplets / SeaTrail / RoadTrail servent de modèles,
## dupliqués pour chaque roue au démarrage.

@export_group("Mer")
## Multiplicateur global des effets sur l'eau
@export_range(0.0, 2.0) var sea_strength : float = 1.0
## Ondulations autour de chaque roue (simulation WaterRipples, 32 px/m)
@export var sea_ripple_height : float = 0.15
## Rayon de ces ondulations (pixels de la simulation).
@export var sea_ripple_radius_px : float = 4.0
## Sillage dans la simulation de vagues (WaterWaves, 8 px/m)
@export var sea_wake_height : float = 0.03
## Rayon de ce sillage (pixels de la simulation).
@export var sea_wake_radius_px : float = 3.0
## Écume persistante laissée par les roues arrière (WaterFoam)
@export_range(0.0, 1.0) var sea_foam_amount : float = 0.5
## Rayon de cette écume (m).
@export var sea_foam_radius : float = 0.4

@export_group("Route")
## Multiplicateur des effets sur la route, lui-même multiplié par le mouillage de la pluie
@export_range(0.0, 2.0) var road_strength : float = 1.0
## Mouillage minimum de la route quand il ne pleut pas (0 = aucun effet sur route sèche)
@export_range(0.0, 1.0) var road_min_wetness : float = 0.0

@export_group("Vitesse")
## Vitesse (m/s) à partir de laquelle les effets apparaissent
@export var min_speed : float = 1.5
## Vitesse (m/s) à laquelle les effets atteignent leur maximum
@export var full_speed : float = 15.0

var _kart : Kart
var _ocean : Ocean
var _rain : RainController
var _fx : Array[Dictionary] = []
## Repère horizontal du kart pour l'image en cours (x = droite, z = arrière)
var _emit_basis : Basis

func _ready() -> void:
	_kart = get_parent() as Kart
	var templates : Array[Node] = [$SeaDroplets, $SeaSpray, $RoadDroplets, $SeaTrail, $RoadTrail]
	for t in templates:
		if t is GPUParticles3D:
			(t as GPUParticles3D).emitting = false
		(t as Node3D).visible = false
	# Scène ouverte seule, hors d'un kart : aucun effet à produire.
	if _kart == null:
		set_process(false)
		return

	for child in _kart.get_node("Visual/Kart").get_children():
		if child is Wheel:
			var wheel := child as Wheel
			var rear := not wheel.steering_enabled
			_fx.append({
				"wheel": wheel,
				"rear": rear,
				"sea_droplets": _make_emitter($SeaDroplets),
				"road_droplets": _make_emitter($RoadDroplets),
				"sea_spray": _make_emitter($SeaSpray) if rear else null,
				"sea_trail": _make_trail($SeaTrail) if rear else null,
				"road_trail": _make_trail($RoadTrail) if rear else null,
			})

func _make_emitter(template: GPUParticles3D) -> GPUParticles3D:
	var e := template.duplicate() as GPUParticles3D
	var pm := (template.process_material as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	e.process_material = pm
	e.set_meta("base_direction", pm.direction)
	e.set_meta("base_velocity", Vector2(pm.initial_velocity_min, pm.initial_velocity_max))
	e.top_level = true
	e.visible = true
	e.emitting = false
	add_child(e)
	return e

func _make_trail(template: WheelTrail) -> WheelTrail:
	var t := template.duplicate() as WheelTrail
	t.visible = true
	add_child(t)
	return t

func _process(_delta: float) -> void:
	if not _ocean:
		_ocean = get_tree().get_first_node_in_group("ocean") as Ocean
	if not _rain:
		_rain = get_tree().get_first_node_in_group("rain") as RainController

	var speed := _kart.get_horizontal_velocity().length()
	var moving := speed > min_speed
	var speed_factor := clampf(inverse_lerp(min_speed, full_speed, speed), 0.0, 1.0)
	var wetness := maxf(road_min_wetness, _rain.wetness if _rain else 0.0)
	var water_height := _kart.water_buoyancy_sensor.get_water_height()
	var kart_basis := _kart.global_basis
	var right := Vector3(kart_basis.x.x, 0.0, kart_basis.x.z).normalized()
	var forward := Vector3(-kart_basis.z.x, 0.0, -kart_basis.z.z).normalized()
	_emit_basis = Basis(right, Vector3.UP, -forward)

	var sea_f := (0.25 + 0.75 * speed_factor) * sea_strength
	var road_f := (0.2 + 0.8 * speed_factor) * road_strength * wetness
	var rear_in_water := false
	var rear_center := Vector3.ZERO
	var rear_count := 0

	for fx in _fx:
		var wheel : Wheel = fx.wheel
		var contact := wheel.get_wheel_position()
		var side_sign := 1.0 if (contact - _kart.global_position).dot(right) >= 0.0 else -1.0
		var in_water := _ocean != null and contact.y <= water_height + 0.15 \
			and _ocean.get_island_mask(contact) > 0.05
		var on_road := not in_water and wheel.is_grounded()
		var water_point := Vector3(contact.x, water_height, contact.z)

		# --- Mer : gerbe de gouttelettes autour de chaque roue + ondulations ---
		var sea_on := in_water and moving and sea_strength > 0.0
		_drive_emitter(fx.sea_droplets, sea_on, sea_f, water_point, side_sign, 0.5 + speed_factor)
		if fx.sea_spray:
			_drive_emitter(fx.sea_spray, sea_on, sea_f, water_point + Vector3.UP * 0.12, side_sign, 0.4 + speed_factor)
		if sea_on and _ocean:
			_ocean.add_ripple(water_point, sea_ripple_height * sea_f, sea_ripple_radius_px)
			if fx.rear:
				_ocean.add_foam(water_point, sea_foam_amount * minf(sea_f, 1.0), sea_foam_radius)

		# --- Route mouillée : petites gouttelettes ---
		var road_on := on_road and moving and road_f > 0.02
		var road_point := wheel.raycast.get_collision_point() if on_road else contact
		_drive_emitter(fx.road_droplets, road_on, road_f, road_point, side_sign, 0.5 + speed_factor)

		# --- Traînées (roues arrière) ---
		if fx.rear:
			var sea_trail : WheelTrail = fx.sea_trail
			var road_trail : WheelTrail = fx.road_trail
			if sea_on:
				sea_trail.add_point(water_point, right, Vector3.UP, minf(sea_f, 1.0))
				rear_in_water = true
				rear_center += water_point
				rear_count += 1
			else:
				sea_trail.stop()
			if road_on:
				var normal := wheel.raycast.get_collision_normal()
				var side := normal.cross(forward).normalized() * -1.0
				road_trail.add_point(road_point, side, normal, minf(road_f, 1.0))
			else:
				road_trail.stop()

	# Sillage en V dans la simulation de vagues, derrière le kart
	if rear_in_water and _ocean:
		_ocean.add_wave(rear_center / rear_count, sea_wake_height * sea_f, sea_wake_radius_px)

## direction du modèle : x = vers l'extérieur du kart, y = vers le haut, z = vers l'arrière
func _drive_emitter(e: GPUParticles3D, on: bool, amount: float, pos: Vector3, side_sign: float, velocity_scale: float) -> void:
	if on:
		e.global_transform = Transform3D(_emit_basis, pos)
		var pm := e.process_material as ParticleProcessMaterial
		var base_dir : Vector3 = e.get_meta("base_direction")
		var base_vel : Vector2 = e.get_meta("base_velocity")
		pm.direction = Vector3(base_dir.x * side_sign, base_dir.y, base_dir.z)
		pm.initial_velocity_min = base_vel.x * velocity_scale
		pm.initial_velocity_max = base_vel.y * velocity_scale
		e.amount_ratio = clampf(amount, 0.05, 1.0)
	if e.emitting != on:
		e.emitting = on
