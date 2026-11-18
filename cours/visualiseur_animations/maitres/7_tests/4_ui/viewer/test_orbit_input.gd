extends GdUnitTestSuite
## Glisser avec un bouton tourne la caméra, sans bouton rien ; la molette rapproche et éloigne ; le stick droit tourne
## à sa vitesse ; la vue du jeu se bascule ; chaque mouvement est signalé.


func _input_node() -> OrbitInput:
	var orbit: OrbitInput = auto_free(OrbitInput.new())
	orbit.set_process(false)
	add_child(orbit)
	orbit.rig.distance = 4.0
	return orbit


func after_test() -> void:
	Input.action_release("orbit_right")


func test_glisser_avec_un_bouton_tourne_sans_bouton_rien() -> void:
	var orbit: OrbitInput = _input_node()
	var drag: InputEventMouseMotion = InputEventMouseMotion.new()
	drag.relative = Vector2(-50, 10)
	assert_bool(orbit.handle(drag)).is_false()
	drag.button_mask = MOUSE_BUTTON_MASK_RIGHT
	assert_bool(orbit.handle(drag)).is_true()
	assert_float(orbit.rig.yaw_deg).is_equal_approx(20.0, 0.0001)
	assert_float(orbit.rig.pitch_deg).is_equal_approx(19.0, 0.0001)


func test_la_molette_rapproche_et_eloigne() -> void:
	var orbit: OrbitInput = _input_node()
	var wheel: InputEventMouseButton = InputEventMouseButton.new()
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	assert_bool(orbit.handle(wheel)).is_true()
	assert_float(orbit.rig.distance).is_equal_approx(3.6, 0.0001)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	orbit.handle(wheel)
	assert_float(orbit.rig.distance).is_equal_approx(4.0, 0.0001)


func test_le_stick_droit_tourne_a_sa_vitesse() -> void:
	var orbit: OrbitInput = _input_node()
	assert_bool(orbit.step(0.5)).is_false()
	Input.action_press("orbit_right", 1.0)
	assert_bool(orbit.step(0.5)).is_true()
	assert_float(orbit.rig.yaw_deg).is_equal_approx(360.0 - OrbitInput.STICK_DEGREES_PER_S * 0.5, 0.0001)


func test_la_vue_du_jeu_se_bascule_et_chaque_mouvement_est_signale() -> void:
	var orbit: OrbitInput = _input_node()
	var moves: Array[int] = [0]
	orbit.rig_changed.connect(func() -> void: moves[0] += 1)
	orbit.toggle_game_view()
	assert_bool(orbit.rig.game_view).is_true()
	orbit.toggle_game_view()
	assert_bool(orbit.rig.game_view).is_false()
	assert_int(moves[0]).is_equal(2)
