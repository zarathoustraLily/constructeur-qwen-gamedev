extends GdUnitTestSuite
## Règles des actions et des réglages du projet : chaque action du combat marche à la manette et au clavier ou à la
## souris ; les touches sont prises par leur position ; ui_accept et ui_cancel ont un bouton de manette ; les couches
## de collision portent leur nom ; la physique tourne à 60 pas par seconde.


func test_chaque_action_du_combat_marche_a_la_manette_et_au_clavier() -> void:
	for action: StringName in Actions.gameplay():
		assert_bool(InputMap.has_action(action)).override_failure_message("action absente : %s" % action).is_true()
		assert_bool(Actions.has_gamepad(action)).override_failure_message("sans manette : %s" % action).is_true()
		assert_bool(Actions.has_keyboard_or_mouse(action)).override_failure_message("sans clavier : %s" % action).is_true()


func test_les_touches_sont_prises_par_leur_position() -> void:
	for action: StringName in Actions.gameplay():
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				assert_int((event as InputEventKey).physical_keycode).is_not_equal(KEY_NONE)
				assert_int((event as InputEventKey).keycode).is_equal(KEY_NONE)


func test_les_menus_ont_un_bouton_de_manette() -> void:
	assert_bool(Actions.has_gamepad(&"ui_accept")).is_true()
	assert_bool(Actions.has_gamepad(&"ui_cancel")).is_true()


func test_la_camera_a_le_stick_droit() -> void:
	for action: StringName in [Actions.CAMERA_LEFT, Actions.CAMERA_RIGHT, Actions.CAMERA_UP, Actions.CAMERA_DOWN]:
		assert_bool(Actions.has_gamepad(action)).is_true()


func test_les_couches_portent_leur_nom() -> void:
	var names: Array[String] = []
	for layer: int in range(1, 6):
		names.append(String(ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % layer, "")))
	assert_array(names).is_equal(["monde", "heros", "boss", "projectiles", "coups_du_boss"])


func test_la_physique_tourne_a_60_pas_par_seconde() -> void:
	assert_int(int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))).is_equal(60)


func test_sans_manette_ni_clavier_une_action_inconnue_ne_compte_pas() -> void:
	InputMap.add_action(&"test_vide")
	assert_bool(Actions.has_gamepad(&"test_vide")).is_false()
	assert_bool(Actions.has_keyboard_or_mouse(&"test_vide")).is_false()
	InputMap.erase_action(&"test_vide")
