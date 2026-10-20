extends GdUnitTestSuite
## Règles des gerbes et traînées des roues : sur l'eau, en roulant, chaque roue projette des gouttelettes et les
## roues arrière laissent une traînée ; arrêté, rien ; sur une route sèche, rien ; mouillée, des gouttelettes et
## une traînée derrière les roues arrière.

const KART := preload("res://3_entities/kart/kart.tscn")
const SurfaceTemoin := preload("res://7_tests/1_core/water/surface_temoin.gd")

var _kart: Kart
var _effects: WheelSplashEffects


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame
		await get_tree().process_frame


func _spawn_kart(height: float) -> void:
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, height, 0.0)
	add_child(_kart)
	_effects = _kart.get_node("WheelEffects") as WheelSplashEffects


func _ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))


## Les émetteurs créés pour les roues d'après le modèle `template` : mêmes nombre et durée de vie de particules.
func _emitters(template: String) -> Array[GPUParticles3D]:
	var model := _effects.get_node(template) as GPUParticles3D
	var found: Array[GPUParticles3D] = []
	for child: Node in _effects.get_children():
		var emitter := child as GPUParticles3D
		if emitter != null and emitter != model and emitter.amount == model.amount \
				and emitter.lifetime == model.lifetime:
			found.append(emitter)
	return found


## Les traînées créées pour les roues arrière d'après le modèle `template`.
func _trails(template: String) -> Array[WheelTrail]:
	var model := _effects.get_node(template) as WheelTrail
	var found: Array[WheelTrail] = []
	for child: Node in _effects.get_children():
		var trail := child as WheelTrail
		if trail != null and trail != model and trail.lifetime == model.lifetime:
			found.append(trail)
	return found


func test_sur_l_eau_en_roulant_les_roues_eclaboussent() -> void:
	add_child(auto_free(SurfaceTemoin.new()))
	_spawn_kart(0.5)
	await _frames(180)
	_kart.commands.throttle = 1.0
	await _frames(90)
	var droplets := _emitters("SeaDroplets")
	assert_int(droplets.size()).is_equal(4)
	for emitter: GPUParticles3D in droplets:
		assert_bool(emitter.emitting).is_true()
	var trails := _trails("SeaTrail")
	assert_int(trails.size()).is_equal(2)
	for trail: WheelTrail in trails:
		assert_int(trail.point_count()).is_greater(1)


func test_arrete_sur_l_eau_rien() -> void:
	add_child(auto_free(SurfaceTemoin.new()))
	_spawn_kart(0.5)
	await _frames(180)
	for emitter: GPUParticles3D in _emitters("SeaDroplets"):
		assert_bool(emitter.emitting).is_false()


func test_sur_une_route_seche_rien() -> void:
	_ground()
	_spawn_kart(0.6)
	_kart.commands.throttle = 1.0
	await _frames(90)
	for emitter: GPUParticles3D in _emitters("RoadDroplets"):
		assert_bool(emitter.emitting).is_false()


func test_sur_une_route_mouillee_des_gouttelettes_et_des_trainees() -> void:
	_ground()
	_spawn_kart(0.6)
	_effects.road_wetness = 1.0
	_kart.commands.throttle = 1.0
	await _frames(90)
	var droplets := _emitters("RoadDroplets")
	assert_int(droplets.size()).is_equal(4)
	for emitter: GPUParticles3D in droplets:
		assert_bool(emitter.emitting).is_true()
	var trails := _trails("RoadTrail")
	assert_int(trails.size()).is_equal(2)
	for trail: WheelTrail in trails:
		assert_int(trail.point_count()).is_greater(1)
