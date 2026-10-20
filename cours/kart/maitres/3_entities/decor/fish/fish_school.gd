class_name FishSchool extends Node3D

## Bancs de poissons (ProceduralFish) dans l'eau peu profonde autour de ce nœud.
## Chaque banc erre autour de son point d'attache ; ses poissons le suivent en s'écartant les uns
## des autres, restent entre le fond et la surface, évitent les hauts-fonds et fuient le kart.

## Nombre total de poissons, répartis entre les bancs.
@export var fish_count : int = 16
## Nombre de bancs.
@export var school_count : int = 4
## Rayon (m) autour de ce nœud dans lequel les bancs s'installent
@export var spawn_radius : float = 40.0
## Distance (m) maximale d'errance d'un banc autour de son point d'attache
@export var wander_radius : float = 12.0
## Profondeur d'eau (m) dans laquelle les poissons nagent
@export var min_depth : float = 1.0
## Profondeur d'eau maximale (m) où les poissons nagent.
@export var max_depth : float = 4.5
## Mètres par unité du code d'origine (0.0013 ≈ poisson de 1 m), ±20 % par poisson
@export var fish_size : float = 0.0013
## Vitesse de croisière (m/s)
@export var fish_speed : float = 1.1
## Distance (m) à laquelle les poissons fuient le kart
@export var flee_distance : float = 5.0
## Hauteur de nage entre le fond (0) et la surface (1) : plus près de la surface, les couleurs restent vives
@export_range(0.0, 1.0) var swim_height : float = 0.62
## Matériau du corps des poissons.
@export var body_material : Material
## Matériau des nageoires.
@export var fin_material : Material
## Niveau moyen de la mer
@export var sea_level : float = 0.0
## Calques de collision du fond (Terrain, Circuit)
@export_flags_3d_physics var floor_mask : int = 8 | 16

var _schools : Array[Dictionary] = []
var _fish : Array[ProceduralFish] = []
var _fish_data : Array[Dictionary] = []
var _ocean : Ocean
var _player : Node
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_spawn.call_deferred()

func _spawn() -> void:
	# Les collisions du terrain doivent être enregistrées avant les lancers de rayons
	await get_tree().physics_frame
	_ocean = get_tree().get_first_node_in_group("ocean") as Ocean
	_player = get_tree().get_first_node_in_group("player")

	for s in school_count:
		var home : Variant = _find_water_point(global_position, spawn_radius)
		if home != null:
			_schools.append({"home": home, "target": home, "timer": 0.0})
	if _schools.is_empty():
		push_warning("FishSchool : aucune eau entre %.1f et %.1f m de profondeur dans un rayon de %.0f m" % [min_depth, max_depth, spawn_radius])
		return

	for i in fish_count:
		var school_index := i % _schools.size()
		var home : Vector3 = _schools[school_index].home
		var offset := Vector3(_rng.randf_range(-3.5, 3.5), 0.0, _rng.randf_range(-3.5, 3.5))
		var fish := ProceduralFish.new()
		fish.size = fish_size * _rng.randf_range(0.8, 1.2)
		fish.body_material = body_material
		fish.fin_material = fin_material
		add_child(fish)
		var start := home + offset
		start.y = lerpf(home.y, sea_level, 0.5)
		fish.place(start, _rng.randf() * TAU)
		_fish.append(fish)
		_fish_data.append({
			"school": school_index,
			"offset": offset,
			"floor": home.y,
			"water": sea_level,
			"blocked": false,
			"check_timer": _rng.randf() * 0.5,
			"speed_factor": _rng.randf_range(0.8, 1.2),
		})

func _process(delta: float) -> void:
	if _fish.is_empty():
		return

	# Chaque banc change de destination de temps en temps
	for school in _schools:
		school.timer -= delta
		if school.timer <= 0.0:
			var p : Variant = _find_water_point(school.home, wander_radius)
			if p != null:
				school.target = p
			school.timer = _rng.randf_range(5.0, 10.0)

	var has_kart := _player != null and _player.has_method("get_kart_position")
	var kart_position : Vector3 = _player.get_kart_position() if has_kart else Vector3.ZERO

	for i in _fish.size():
		var fish := _fish[i]
		var data := _fish_data[i]
		var head := fish.get_head_position()

		# Fond, surface et haut-fond devant le poisson : vérifiés quelques fois par seconde
		data.check_timer -= delta
		if data.check_timer <= 0.0:
			data.check_timer = _rng.randf_range(0.3, 0.5)
			var measured_floor := _floor_height(head.x, head.z)
			if not is_nan(measured_floor):
				data.floor = measured_floor
			var ahead := head + fish.get_forward() * 1.5
			var ahead_floor := _floor_height(ahead.x, ahead.z)
			data.blocked = not is_nan(ahead_floor) and sea_level - ahead_floor < min_depth * 0.6
			data.water = _ocean.get_wave_height(head, 2, 2) if _ocean else sea_level

		var school : Dictionary = _schools[data.school]
		var target : Vector3 = school.target + (data.offset as Vector3)
		var speed : float = fish_speed * (data.speed_factor as float)
		if data.blocked:
			# Haut-fond devant : retour vers l'eau plus profonde du banc
			target = school.home

		# Fuite devant le kart
		if has_kart:
			var away : Vector3 = head - kart_position
			away.y = 0.0
			if away.length() < flee_distance:
				target = head + away.normalized() * 6.0
				speed = fish_speed * 3.5

		# Séparation : les poissons ne se traversent pas
		for j in _fish.size():
			if j == i:
				continue
			var diff := head - _fish[j].get_head_position()
			diff.y = 0.0
			var dist := diff.length()
			if dist > 0.001 and dist < 1.4:
				target += diff / dist * (1.4 - dist) * 3.0

		# Profondeur : entre le fond et la surface (la houle fait varier la surface)
		var water_y : float = minf(data.water, sea_level + 0.5)
		var floor_y : float = data.floor
		target.y = clampf(lerpf(floor_y, water_y, swim_height), floor_y + 0.3, water_y - 0.4)
		fish.target_position = target
		fish.desired_speed = speed

## Point (sur le fond) dont la profondeur d'eau est dans [min_depth, max_depth], ou null
func _find_water_point(center: Vector3, radius: float) -> Variant:
	for attempt in 60:
		var angle := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * radius
		var x := center.x + cos(angle) * r
		var z := center.z + sin(angle) * r
		var floor_y := _floor_height(x, z)
		if is_nan(floor_y):
			continue
		var depth := sea_level - floor_y
		if depth >= min_depth and depth <= max_depth:
			return Vector3(x, floor_y, z)
	return null

func _floor_height(x: float, z: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, sea_level + 30.0, z), Vector3(x, sea_level - 60.0, z), floor_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return NAN if hit.is_empty() else (hit.position as Vector3).y
