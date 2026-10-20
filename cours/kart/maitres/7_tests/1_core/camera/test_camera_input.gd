extends GdUnitTestSuite
## Règles de l'adaptateur d'entrées de la caméra : au démarrage, la souris est libre ; un clic la capture,
## Échap (ui_cancel) la rend ; ses mouvements ne comptent que capturée, et chaque lecture remet le cumul à
## zéro ; le stick droit se lit par les actions look_*, chacune sur un axe de la manette.

const LOOK: Array[String] = ["look_left", "look_right", "look_up", "look_down"]

var _input: CameraInput


func before_test() -> void:
	_input = auto_free(CameraInput.new())
	add_child(_input)


func after_test() -> void:
	for action: String in LOOK:
		Input.action_release(action)


func test_au_demarrage_la_souris_est_libre() -> void:
	assert_bool(_input.captured).is_false()


func test_un_clic_capture_la_souris_et_echap_la_rend() -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_input._input(click)
	assert_bool(_input.captured).is_true()
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	_input._input(escape)
	assert_bool(_input.captured).is_false()


func test_les_mouvements_de_souris_ne_comptent_que_capturee_et_se_vident_a_la_lecture() -> void:
	_input.add_mouse_motion(Vector2(5.0, 0.0))
	assert_vector(_input.take_mouse_motion()).is_equal(Vector2.ZERO)
	_input.captured = true
	_input.add_mouse_motion(Vector2(5.0, 1.0))
	_input.add_mouse_motion(Vector2(2.0, 1.0))
	assert_vector(_input.take_mouse_motion()).is_equal(Vector2(7.0, 2.0))
	assert_vector(_input.take_mouse_motion()).is_equal(Vector2.ZERO)


func test_chaque_action_du_stick_droit_est_sur_un_axe_de_la_manette() -> void:
	for action: String in LOOK:
		var axes: Array[int] = []
		for event: InputEvent in InputMap.action_get_events(action):
			var motion := event as InputEventJoypadMotion
			if motion != null:
				axes.append(motion.axis)
		assert_bool(axes.has(JOY_AXIS_RIGHT_X) or axes.has(JOY_AXIS_RIGHT_Y)).override_failure_message(action).is_true()


func test_le_stick_droit_a_fond_vers_le_haut_donne_moins_un() -> void:
	Input.action_press("look_up")
	assert_vector(_input.stick()).is_equal_approx(Vector2(0.0, -1.0), Vector2.ONE * 0.001)
