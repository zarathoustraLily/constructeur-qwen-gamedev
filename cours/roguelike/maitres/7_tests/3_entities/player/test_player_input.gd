extends GdUnitTestSuite
## Règles de l'adaptateur d'entrées du joueur : chaque commande existe au clavier ou à la souris, et à la
## manette ; sous la zone morte rien ne bouge, au-delà la course est remise à l'échelle ; le coup et l'esquive
## sont signalés à l'image où on appuie ; la visée suit le dernier appareil touché : à la souris, du personnage
## vers le pointeur ; à la manette, le stick droit, rien au repos ; un stick à peine touché ne change pas
## d'appareil.

const MOVES: Array[String] = ["move_forward", "move_back", "move_left", "move_right"]
const AIMS: Array[String] = ["aim_left", "aim_right", "aim_up", "aim_down"]
const BUTTONS: Array[String] = ["attack", "dash"]

var _input: PlayerInput
var _body: Node3D


func before_test() -> void:
	var camera: Camera3D = auto_free(Camera3D.new())
	add_child(camera)
	camera.position = Vector3(0.0, 10.0, 10.0)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	_body = auto_free(Node3D.new())
	add_child(_body)
	_input = auto_free(PlayerInput.new())
	_input.body = _body
	add_child(_input)


func after_test() -> void:
	for action: String in MOVES + AIMS + BUTTONS:
		Input.action_release(action)


func _has_event(action: String, kinds: Array[String]) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event.get_class() in kinds:
			return true
	return false


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await get_tree().process_frame


func _pad_button() -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_X
	event.pressed = true
	return event


func _pad_motion(value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_RIGHT_X
	event.axis_value = value
	return event


func test_chaque_commande_existe_au_clavier_ou_a_la_souris_et_a_la_manette() -> void:
	for action: String in MOVES + BUTTONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(action + " absente").is_true()
		assert_bool(_has_event(action, ["InputEventKey", "InputEventMouseButton"])) \
			.override_failure_message(action + " : ni touche ni bouton de souris").is_true()
		assert_bool(_has_event(action, ["InputEventJoypadMotion", "InputEventJoypadButton"])) \
			.override_failure_message(action + " : rien sur la manette").is_true()
	for action: String in AIMS:
		assert_bool(_has_event(action, ["InputEventJoypadMotion"])) \
			.override_failure_message(action + " : pas de stick").is_true()


func test_le_clic_gauche_frappe_et_espace_esquive() -> void:
	var click := false
	for event: InputEvent in InputMap.action_get_events("attack"):
		var mouse := event as InputEventMouseButton
		click = click or mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT
	assert_bool(click).is_true()
	var space := false
	for event: InputEvent in InputMap.action_get_events("dash"):
		var key := event as InputEventKey
		space = space or key != null and key.physical_keycode == KEY_SPACE
	assert_bool(space).is_true()


func test_un_stick_a_moitie_donne_une_marche_remise_a_l_echelle_de_la_zone_morte() -> void:
	var dead_zone := InputMap.action_get_deadzone("move_right")
	assert_float(dead_zone).is_greater(0.0)
	Input.action_press("move_right", 0.5)
	assert_float(_input.read().move.x).is_equal_approx(inverse_lerp(dead_zone, 1.0, 0.5), 0.001)


func test_sous_la_zone_morte_le_joueur_ne_marche_pas() -> void:
	Input.action_press("move_left", InputMap.action_get_deadzone("move_left") * 0.5)
	assert_vector(_input.read().move).is_equal(Vector2.ZERO)


func test_en_avant_c_est_vers_le_haut_de_l_ecran() -> void:
	Input.action_press("move_forward")
	assert_vector(_input.read().move).is_equal_approx(Vector2(0.0, -1.0), Vector2.ONE * 0.001)


func test_le_coup_est_signale_a_l_image_ou_on_appuie() -> void:
	Input.action_press("attack")
	assert_bool(_input.read().attack).is_true()
	await get_tree().physics_frame
	await get_tree().process_frame
	assert_bool(_input.read().attack).is_false()


func test_l_esquive_est_signalee_a_l_image_ou_on_appuie() -> void:
	assert_bool(_input.read().dash).is_false()
	Input.action_press("dash")
	assert_bool(_input.read().dash).is_true()


func test_a_la_souris_on_vise_du_personnage_vers_le_pointeur() -> void:
	var on_screen := get_viewport().get_camera_3d().unproject_position(_body.global_position)
	assert_vector(_input.aim_from_mouse(on_screen)).is_equal_approx(Vector2.ZERO, Vector2.ONE * 0.01)
	assert_vector(_input.aim_from_mouse(on_screen + Vector2(100.0, 0.0))) \
		.is_equal_approx(Vector2(100.0, 0.0), Vector2.ONE * 0.01)


func test_un_bouton_de_manette_fait_viser_au_stick_et_stick_au_repos_rien() -> void:
	await _send(_pad_button())
	var commands := _input.read()
	assert_bool(commands.from_pad).is_true()
	assert_vector(commands.aim).is_equal(Vector2.ZERO)
	Input.action_press("aim_right")
	assert_vector(_input.read().aim).is_equal_approx(Vector2(1.0, 0.0), Vector2.ONE * 0.001)


func test_la_souris_reprend_la_visee() -> void:
	await _send(_pad_button())
	assert_bool(_input.read().from_pad).is_true()
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(10.0, 10.0)
	await _send(motion)
	assert_bool(_input.read().from_pad).is_false()


func test_un_stick_a_peine_touche_ne_change_pas_d_appareil() -> void:
	await _send(_pad_motion(PlayerInput.PAD_MOTION_THRESHOLD * 0.5))
	assert_bool(_input.read().from_pad).is_false()
	await _send(_pad_motion(1.0))
	assert_bool(_input.read().from_pad).is_true()
	await _send(_pad_motion(0.0))


func test_les_noms_des_manettes_sont_ceux_des_manettes_branchees() -> void:
	assert_int(_input.joypad_names().size()).is_equal(Input.get_connected_joypads().size())
	var rumble := Rumble.new()
	rumble.strong_magnitude = 1.0
	rumble.duration = 0.1
	_input.vibrate(rumble)
