class_name FishSchoolView extends Node3D
## Bancs de poissons (ProceduralFishView) dans l'eau peu profonde autour de ce nœud. Chaque banc erre autour de
## son point d'attache ; ses poissons le suivent en s'écartant les uns des autres, restent entre le fond et la
## surface, évitent les hauts-fonds et fuient ce qu'on leur donne à fuir (`threat`, le kart). Ils ne changent
## rien au jeu : c'est un décor vivant, une présentation. Le hasard vient de `random_seed` : les mêmes bancs, au
## même endroit, à chaque partie.


## Un banc : son point d'attache sur le fond, et la destination du moment.
class School:
	var home: Vector3
	var target: Vector3
	## Temps avant de changer de destination (s).
	var timer: float = 0.0


## Ce qu'un poisson sait de son eau.
class FishState:
	## Indice de son banc.
	var school: int = 0
	## Sa place dans le banc, autour de la destination.
	var offset: Vector3
	## Hauteur du fond sous lui, et de la surface au-dessus.
	var floor_height: float = 0.0
	var water_height: float = 0.0
	## Vrai si un haut-fond est devant lui.
	var blocked: bool = false
	## Temps avant de mesurer à nouveau le fond et la surface (s).
	var check_timer: float = 0.0
	## Son allure, autour de la vitesse de croisière.
	var speed_factor: float = 1.0


## Nombre total de poissons, répartis entre les bancs.
@export var fish_count: int = 16
## Nombre de bancs.
@export var school_count: int = 4
## Rayon (m) autour de ce nœud dans lequel les bancs s'installent.
@export var spawn_radius: float = 40.0
## Distance (m) maximale d'errance d'un banc autour de son point d'attache.
@export var wander_radius: float = 12.0
## Profondeur d'eau (m) la plus faible où les poissons nagent.
@export var min_depth: float = 1.0
## Profondeur d'eau (m) la plus grande où les poissons nagent.
@export var max_depth: float = 4.5
## Mètres par unité du code d'origine (0,0013 : un poisson d'environ 1 m), à ± 20 % par poisson.
@export var fish_size: float = 0.0013
## Vitesse de croisière (m/s).
@export var fish_speed: float = 1.1
## Distance (m) à laquelle les poissons fuient la menace.
@export var flee_distance: float = 5.0
## Hauteur de nage entre le fond (0) et la surface (1) : près de la surface, les couleurs restent vives.
@export_range(0.0, 1.0) var swim_height: float = 0.62
## Matériau du corps des poissons.
@export var body_material: Material
## Matériau des nageoires.
@export var fin_material: Material
## Niveau moyen de la mer.
@export var sea_level: float = 0.0
## Couches de collision du fond (Terrain, Circuit).
@export_flags_3d_physics var floor_mask: int = 8 | 16
## Ce que les poissons fuient (le kart, donné par la scène) ; vide, ils ne fuient rien.
@export var threat: Node3D
## Graine du hasard des bancs.
@export var random_seed: int = 0

var _schools: Array[School] = []
var _fish: Array[ProceduralFishView] = []
var _states: Array[FishState] = []
var _water: WaterSurface
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = random_seed
	_spawn.call_deferred()


## Nombre de poissons dans l'eau.
func fish_in_water() -> int:
	return _fish.size()


## Les poissons des bancs.
func get_fish() -> Array[ProceduralFishView]:
	return _fish


func _spawn() -> void:
	# Les collisions du terrain doivent être enregistrées avant les rayons.
	await get_tree().physics_frame
	_water = get_tree().get_first_node_in_group("ocean") as WaterSurface
	for _school: int in school_count:
		var home: Variant = _find_water_point(global_position, spawn_radius)
		if home != null:
			var school := School.new()
			school.home = home
			school.target = home
			_schools.append(school)
	if _schools.is_empty():
		push_warning("Poissons : aucune eau entre %.1f et %.1f m de profondeur dans un rayon de %.0f m"
			% [min_depth, max_depth, spawn_radius])
		return
	for index: int in fish_count:
		var state := FishState.new()
		state.school = index % _schools.size()
		var home := _schools[state.school].home
		state.offset = Vector3(_rng.randf_range(-3.5, 3.5), 0.0, _rng.randf_range(-3.5, 3.5))
		state.floor_height = home.y
		state.water_height = sea_level
		state.check_timer = _rng.randf() * 0.5
		state.speed_factor = _rng.randf_range(0.8, 1.2)
		var fish := ProceduralFishView.new()
		fish.size = fish_size * _rng.randf_range(0.8, 1.2)
		fish.body_material = body_material
		fish.fin_material = fin_material
		fish.swim_phase = _rng.randf() * TAU
		fish.flap_phase = _rng.randf() * TAU
		fish.frame_parity = _rng.randi() % 2
		add_child(fish)
		var start := home + state.offset
		start.y = lerpf(home.y, sea_level, 0.5)
		fish.place(start, _rng.randf() * TAU)
		_fish.append(fish)
		_states.append(state)


func _process(delta: float) -> void:
	if _fish.is_empty():
		return
	# Chaque banc change de destination de temps en temps.
	for school: School in _schools:
		school.timer -= delta
		if school.timer <= 0.0:
			var point: Variant = _find_water_point(school.home, wander_radius)
			if point != null:
				school.target = point
			school.timer = _rng.randf_range(5.0, 10.0)
	for index: int in _fish.size():
		_steer(index, delta)


## Donne au poisson `index` sa destination et sa vitesse pour cette image.
func _steer(index: int, delta: float) -> void:
	var fish := _fish[index]
	var state := _states[index]
	var head := fish.get_head_position()
	# Fond, surface et haut-fond devant le poisson : mesurés quelques fois par seconde.
	state.check_timer -= delta
	if state.check_timer <= 0.0:
		state.check_timer = _rng.randf_range(0.3, 0.5)
		var measured_floor := _floor_height(head.x, head.z)
		if not is_nan(measured_floor):
			state.floor_height = measured_floor
		var ahead := head + fish.get_forward() * 1.5
		var ahead_floor := _floor_height(ahead.x, ahead.z)
		state.blocked = not is_nan(ahead_floor) and sea_level - ahead_floor < min_depth * 0.6
		state.water_height = _water.get_wave_height(head, 2, 2) if _water != null else sea_level
	var school := _schools[state.school]
	var target := school.target + state.offset
	var speed := fish_speed * state.speed_factor
	if state.blocked:
		# Haut-fond devant : retour vers l'eau plus profonde du banc.
		target = school.home
	if threat != null:
		var away := head - threat.global_position
		away.y = 0.0
		if away.length() < flee_distance:
			target = head + away.normalized() * 6.0
			speed = fish_speed * 3.5
	# Séparation : les poissons ne se traversent pas.
	for other: int in _fish.size():
		if other == index:
			continue
		var diff := head - _fish[other].get_head_position()
		diff.y = 0.0
		var distance := diff.length()
		if distance > 0.001 and distance < 1.4:
			target += diff / distance * (1.4 - distance) * 3.0
	# Profondeur : entre le fond et la surface (la houle fait varier la surface).
	var water_y := minf(state.water_height, sea_level + 0.5)
	target.y = clampf(lerpf(state.floor_height, water_y, swim_height), state.floor_height + 0.3, water_y - 0.4)
	fish.target_position = target
	fish.desired_speed = speed


## Un point du fond, à moins de `radius` de `center`, où l'eau a entre `min_depth` et `max_depth` de
## profondeur ; null après 60 essais.
func _find_water_point(center: Vector3, radius: float) -> Variant:
	for _attempt: int in 60:
		var angle := _rng.randf() * TAU
		var distance := sqrt(_rng.randf()) * radius
		var x := center.x + cos(angle) * distance
		var z := center.z + sin(angle) * distance
		var floor_y := _floor_height(x, z)
		if is_nan(floor_y):
			continue
		var depth := sea_level - floor_y
		if depth >= min_depth and depth <= max_depth:
			return Vector3(x, floor_y, z)
	return null


func _floor_height(x: float, z: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, sea_level + 30.0, z), Vector3(x, sea_level - 60.0, z),
		floor_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return NAN if hit.is_empty() else (hit["position"] as Vector3).y
