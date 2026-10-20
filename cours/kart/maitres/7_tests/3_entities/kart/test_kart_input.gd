extends GdUnitTestSuite
## Règles de l'adaptateur d'entrées du kart : chaque commande de conduite existe au clavier et à la manette ;
## les gâchettes donnent les gaz ; sous la zone morte rien ne bouge, au-delà la course est remise à l'échelle ;
## avant et arrière ensemble freinent ; le saut est signalé à l'image où on appuie, puis tenu, puis relâché.

const ACTIONS: Array[String] = ["move_forward", "move_backward", "move_left", "move_right", "move_jump",
	"move_brake"]

var _input: KartInput


func before_test() -> void:
	_input = auto_free(KartInput.new())
	add_child(_input)


func after_test() -> void:
	for action: String in ACTIONS:
		Input.action_release(action)


func _has_event(action: String, kind: String) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event.get_class() == kind:
			return true
	return false


func _has_axis(action: String, axis: JoyAxis) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion != null and motion.axis == axis:
			return true
	return false


func test_chaque_commande_existe_au_clavier_et_a_la_manette() -> void:
	for action: String in ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message(action + " absente").is_true()
		assert_bool(_has_event(action, "InputEventKey")).override_failure_message(action + " : pas de touche").is_true()
		assert_bool(_has_event(action, "InputEventJoypadMotion") or _has_event(action, "InputEventJoypadButton")) \
			.override_failure_message(action + " : rien sur la manette").is_true()


func test_les_gachettes_donnent_les_gaz() -> void:
	assert_bool(_has_axis("move_forward", JOY_AXIS_TRIGGER_RIGHT)).is_true()
	assert_bool(_has_axis("move_backward", JOY_AXIS_TRIGGER_LEFT)).is_true()


func test_une_gachette_a_moitie_donne_des_gaz_remis_a_l_echelle_de_la_zone_morte() -> void:
	var dead_zone := InputMap.action_get_deadzone("move_forward")
	assert_float(dead_zone).is_greater(0.0)
	Input.action_press("move_forward", 0.5)
	assert_float(_input.read().throttle).is_equal_approx(inverse_lerp(dead_zone, 1.0, 0.5), 0.001)


func test_sous_la_zone_morte_le_kart_ne_tourne_pas() -> void:
	Input.action_press("move_right", InputMap.action_get_deadzone("move_right") * 0.5)
	assert_float(_input.read().steering).is_equal(0.0)


func test_a_fond_a_gauche_le_braquage_vaut_moins_un() -> void:
	Input.action_press("move_left")
	assert_float(_input.read().steering).is_equal_approx(-1.0, 0.001)


func test_avant_et_arriere_ensemble_freinent() -> void:
	Input.action_press("move_forward")
	Input.action_press("move_backward")
	assert_bool(_input.read().brake).is_true()


func test_la_touche_de_frein_freine() -> void:
	assert_bool(_input.read().brake).is_false()
	Input.action_press("move_brake")
	assert_bool(_input.read().brake).is_true()


func test_le_saut_est_signale_a_l_image_ou_on_appuie_puis_tenu_puis_relache() -> void:
	Input.action_press("move_jump")
	var commands := _input.read()
	assert_bool(commands.jump).is_true()
	assert_bool(commands.jump_held).is_true()
	await get_tree().physics_frame
	await get_tree().process_frame
	commands = _input.read()
	assert_bool(commands.jump).is_false()
	assert_bool(commands.jump_held).is_true()
	Input.action_release("move_jump")
	assert_bool(_input.read().jump_released).is_true()


func test_les_noms_des_manettes_sont_ceux_des_manettes_branchees() -> void:
	var names := _input.joypad_names()
	assert_int(names.size()).is_equal(Input.get_connected_joypads().size())
	var rumble := Rumble.new()
	rumble.strong_magnitude = 1.0
	rumble.duration = 0.1
	_input.vibrate(rumble)
