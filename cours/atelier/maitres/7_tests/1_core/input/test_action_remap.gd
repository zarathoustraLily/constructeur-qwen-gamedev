extends GdUnitTestSuite
## Règles du remappage : on lit les boutons de manette d'une action ; un nouveau bouton remplace les anciens sans
## toucher au clavier ; un bouton déjà pris est repéré ; chaque bouton a son libellé ; une sauvegarde se relit à
## l'identique et ignore les actions inconnues.

const ACTIONS: Array[StringName] = [&"move_jump", &"move_attack", &"move_dash"]


func after_test() -> void:
	InputMap.load_from_project_settings()


func test_les_boutons_d_une_action_se_lisent() -> void:
	assert_array(ActionRemap.joypad_buttons(&"move_jump")).is_equal([JOY_BUTTON_A])
	assert_array(ActionRemap.joypad_buttons(&"move_dash")).is_equal([JOY_BUTTON_RIGHT_SHOULDER])


func test_un_nouveau_bouton_remplace_l_ancien_sans_toucher_au_clavier() -> void:
	var keys: int = InputMap.action_get_events(&"move_jump").filter(func(e: InputEvent) -> bool: return e is InputEventKey).size()
	ActionRemap.rebind(&"move_jump", JOY_BUTTON_Y)
	assert_array(ActionRemap.joypad_buttons(&"move_jump")).is_equal([JOY_BUTTON_Y])
	var keys_after: int = InputMap.action_get_events(&"move_jump").filter(func(e: InputEvent) -> bool: return e is InputEventKey).size()
	assert_int(keys_after).is_equal(keys)


func test_le_nouveau_bouton_declenche_l_action() -> void:
	ActionRemap.rebind(&"move_attack", JOY_BUTTON_Y)
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.pressed = true
	assert_bool(event.is_action(&"move_attack")).is_true()


func test_un_bouton_deja_pris_est_repere() -> void:
	assert_array(ActionRemap.conflicts(JOY_BUTTON_A, ACTIONS, &"move_dash")).is_equal([&"move_jump"])
	assert_array(ActionRemap.conflicts(JOY_BUTTON_A, ACTIONS, &"move_jump")).is_empty()
	assert_array(ActionRemap.conflicts(JOY_BUTTON_Y, ACTIONS, &"move_jump")).is_empty()


func test_chaque_bouton_a_son_libelle() -> void:
	assert_str(ActionRemap.label(JOY_BUTTON_A)).is_equal("A")
	assert_str(ActionRemap.label(JOY_BUTTON_RIGHT_SHOULDER)).is_equal("RB")
	assert_str(ActionRemap.label(JOY_BUTTON_PADDLE1)).is_equal("Bouton %d" % JOY_BUTTON_PADDLE1)


func test_une_sauvegarde_se_relit_a_l_identique() -> void:
	ActionRemap.rebind(&"move_jump", JOY_BUTTON_B)
	var config: Dictionary[String, int] = ActionRemap.to_config(ACTIONS)
	assert_dict(config).is_equal({"move_jump": JOY_BUTTON_B, "move_attack": JOY_BUTTON_X, "move_dash": JOY_BUTTON_RIGHT_SHOULDER})
	InputMap.load_from_project_settings()
	ActionRemap.from_config(config)
	assert_array(ActionRemap.joypad_buttons(&"move_jump")).is_equal([JOY_BUTTON_B])


func test_une_sauvegarde_ignore_les_actions_inconnues() -> void:
	var config: Dictionary[String, int] = {"action_inconnue": JOY_BUTTON_X, "move_dash": JOY_BUTTON_Y}
	ActionRemap.from_config(config)
	assert_bool(InputMap.has_action(&"action_inconnue")).is_false()
	assert_array(ActionRemap.joypad_buttons(&"move_dash")).is_equal([JOY_BUTTON_Y])
