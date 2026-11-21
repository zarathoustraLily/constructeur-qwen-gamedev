extends GdUnitTestSuite
## Les entrées du jeu (project.godot) : chaque action se fait au clavier ET à la manette, et les deux actions des menus
## (valider, revenir) ont un bouton de manette, que Godot ne leur donne pas de lui-même.

const ACTIONS: Array[StringName] = [&"ui_accept", &"ui_cancel", &"move_up", &"move_down", &"move_left",
		&"move_right", &"attack", &"dash", &"special", &"interact"]


func _a_un(action: StringName, script_type: String) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event.get_class() == script_type:
			return true
	return false


func test_chaque_action_existe() -> void:
	for action: StringName in ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message("action absente : %s" % action).is_true()


func test_chaque_action_a_une_touche() -> void:
	for action: StringName in ACTIONS:
		assert_bool(_a_un(action, "InputEventKey")).override_failure_message("sans touche : %s" % action).is_true()


func test_chaque_action_se_fait_a_la_manette() -> void:
	for action: StringName in ACTIONS:
		var manette: bool = _a_un(action, "InputEventJoypadButton") or _a_un(action, "InputEventJoypadMotion")
		assert_bool(manette).override_failure_message("sans manette : %s" % action).is_true()


func test_valider_est_le_bouton_a_et_revenir_le_bouton_b() -> void:
	var valider: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(&"ui_accept"):
		if event is InputEventJoypadButton:
			valider.append((event as InputEventJoypadButton).button_index)
	var revenir: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(&"ui_cancel"):
		if event is InputEventJoypadButton:
			revenir.append((event as InputEventJoypadButton).button_index)
	assert_array(valider).contains([JOY_BUTTON_A])
	assert_array(revenir).contains([JOY_BUTTON_B])
