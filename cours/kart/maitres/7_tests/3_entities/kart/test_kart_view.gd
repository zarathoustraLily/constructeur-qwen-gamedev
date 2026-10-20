extends GdUnitTestSuite
## Règles de la présentation du kart : les roues reçoivent la vitesse du kart ; seules les roues directrices
## braquent, dans le sens inverse du braquage ; au repos sur un sol plat, le modèle reste droit. Kart posé sur
## le sol, chaque roue se sait au sol ; en l'air, aucune, et elles pendent à la longueur de repos.

const KART := preload("res://3_entities/kart/kart.tscn")

var _kart: Kart
var _view: Node3D


func before_test() -> void:
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 50.0, 0.0)
	add_child(_kart)
	_kart.set_physics_process(false)
	_view = _kart.get_node("Visual")


func _wheels() -> Array[WheelView]:
	var wheels: Array[WheelView] = []
	wheels.assign(_view.get("wheels"))
	return wheels


func test_le_kart_a_quatre_roues_dont_deux_directrices() -> void:
	var wheels := _wheels()
	assert_int(wheels.size()).is_equal(4)
	assert_int(wheels.filter(func(wheel: WheelView) -> bool: return wheel.steering_enabled).size()).is_equal(2)


func test_les_roues_recoivent_la_vitesse_du_kart() -> void:
	_kart.velocity = -_kart.global_basis.z * 10.0
	_view._process(1.0 / 60.0)
	for wheel: WheelView in _wheels():
		assert_float(wheel.speed).is_equal_approx(10.0, 0.01)


func test_seules_les_roues_directrices_braquent_a_l_inverse_du_braquage() -> void:
	_kart.steering = 1.0
	_view._process(1.0 / 60.0)
	for wheel: WheelView in _wheels():
		var visual := wheel.get_node("WheelVisual") as Node3D
		if wheel.steering_enabled:
			assert_float(visual.rotation.y).is_less(0.0)
		else:
			assert_float(visual.rotation.y).is_equal(0.0)


func test_en_l_air_sans_vitesse_verticale_le_modele_reste_droit() -> void:
	_kart.velocity = Vector3.ZERO
	for _frame: int in 30:
		_view._process(1.0 / 60.0)
	assert_float(_view.global_basis.y.dot(Vector3.UP)).is_equal_approx(1.0, 0.001)


## Un sol plat sur la couche Terrain ; le kart y est posé et laissé tomber.
func _land_on_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	_kart.global_position = Vector3(0.0, 0.6, 0.0)
	_kart.set_physics_process(true)
	for _frame: int in 30:
		await get_tree().physics_frame


func test_kart_pose_chaque_roue_se_sait_au_sol() -> void:
	await _land_on_ground()
	assert_bool(_kart.is_on_floor()).is_true()
	for wheel: WheelView in _wheels():
		assert_bool(wheel.is_grounded()).override_failure_message(str(wheel.name)).is_true()


func test_en_l_air_aucune_roue_n_est_au_sol_et_elles_pendent() -> void:
	for _frame: int in 3:
		await get_tree().physics_frame
	for wheel: WheelView in _wheels():
		assert_bool(wheel.is_grounded()).is_false()
		wheel._process(1.0)
		assert_float(wheel.compression).is_equal_approx(-wheel.spring_rest_length, 0.01)
