extends GdUnitTestSuite
## Règles du kart sur l'eau, sur une surface plate à hauteur 0 : tombé dans l'eau, il rebondit sans couler
## puis flotte à sa hauteur de flottaison ; il y roule comme au sol et peut en sauter ; sans surface d'eau,
## un sol à hauteur 0 reste un sol.

const KART := preload("res://3_entities/kart/kart.tscn")
const SurfaceTemoin := preload("res://7_tests/1_core/water/surface_temoin.gd")

var _kart: Kart


## Une surface d'eau plate à hauteur 0, puis un kart sans pilote lâché à `height` au-dessus.
func _drop_on_water(height: float) -> void:
	add_child(auto_free(SurfaceTemoin.new()))
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, height, 0.0)
	add_child(_kart)


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func test_tombe_dans_l_eau_le_kart_rebondit_sans_couler_puis_flotte() -> void:
	_drop_on_water(2.0)
	var lowest := _kart.global_position.y
	for _frame: int in 240:
		await get_tree().physics_frame
		lowest = minf(lowest, _kart.global_position.y)
	assert_float(lowest).override_failure_message("le kart a coulé : %.2f m" % lowest).is_greater(-1.5)
	assert_bool(_kart.is_in_water()).is_true()
	assert_bool(_kart.is_on_ground()).is_true()
	assert_float(_kart.global_position.y).is_equal_approx(_kart.settings.water_ride_height, 0.05)


func test_sur_l_eau_le_kart_roule_comme_au_sol() -> void:
	_drop_on_water(0.5)
	await _frames(180)
	_kart.commands.throttle = 1.0
	await _frames(180)
	assert_float(_kart.forward_speed()).is_greater(5.0)
	assert_float(_kart.global_position.y).is_equal_approx(_kart.settings.water_ride_height, 0.05)


func test_le_kart_saute_hors_de_l_eau() -> void:
	_drop_on_water(0.5)
	await _frames(180)
	var jumps: Array[int] = [0]
	_kart.jumped.connect(func() -> void: jumps[0] += 1)
	_kart.commands.jump = true
	await _frames(1)
	_kart.commands.jump = false
	await _frames(12)
	assert_int(jumps[0]).is_equal(1)
	assert_bool(_kart.is_in_water()).is_false()
	assert_float(_kart.global_position.y).is_greater(_kart.settings.water_ride_height + 0.2)


func test_sans_surface_d_eau_un_sol_a_hauteur_zero_reste_un_sol() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(_kart)
	await _frames(60)
	assert_bool(_kart.is_on_floor()).is_true()
	assert_bool(_kart.is_in_water()).is_false()
