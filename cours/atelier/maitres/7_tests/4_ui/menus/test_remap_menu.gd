extends GdUnitTestSuite
## Règles du menu des commandes : une ligne par action remappable, avec le nom de son bouton ; choisir une ligne la
## met en écoute ; le prochain bouton pressé devient le sien ; un bouton pris échange avec l'autre action ; B annule
## l'écoute, puis ferme le menu ; ouvert, la première ligne a le focus.

const MENU := preload("res://4_ui/menus/remap_menu.tscn")

var _rebound: Array = []


func after_test() -> void:
	InputMap.load_from_project_settings()


func _menu() -> RemapMenu:
	var menu: RemapMenu = auto_free(MENU.instantiate())
	add_child(menu)
	_rebound.clear()
	menu.rebound.connect(func(action: StringName, button: JoyButton) -> void: _rebound.append([action, button]))
	return menu


func _row_button(menu: RemapMenu, index: int) -> Button:
	return menu.get_node("Center/Rows").get_child(index).get_child(1) as Button


func _press(menu: RemapMenu, button: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	menu.get_viewport().push_input(event)


func _cancel(menu: RemapMenu) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	menu.get_viewport().push_input(event)


func test_une_ligne_par_action_avec_son_bouton() -> void:
	var menu: RemapMenu = _menu()
	assert_int(menu.get_node("Center/Rows").get_child_count()).is_equal(menu.settings.remappable_actions.size())
	assert_str(_row_button(menu, 0).text).is_equal("A")
	assert_str((menu.get_node("Center/Rows").get_child(0).get_child(0) as Label).text).is_equal("Sauter")


func test_choisir_une_ligne_la_met_en_ecoute() -> void:
	var menu: RemapMenu = _menu()
	_row_button(menu, 1).pressed.emit()
	assert_bool(menu.is_listening()).is_true()
	assert_str(String(menu.listening)).is_equal("move_attack")
	assert_str(_row_button(menu, 1).text).is_equal("Appuyez sur un bouton…")


func test_le_prochain_bouton_presse_devient_le_sien() -> void:
	var menu: RemapMenu = _menu()
	menu.start_listening(&"move_attack")
	_press(menu, JOY_BUTTON_Y)
	assert_array(ActionRemap.joypad_buttons(&"move_attack")).is_equal([JOY_BUTTON_Y])
	assert_bool(menu.is_listening()).is_false()
	assert_str(_row_button(menu, 1).text).is_equal("Y")
	assert_array(_rebound).is_equal([[&"move_attack", JOY_BUTTON_Y]])


func test_un_bouton_pris_echange_avec_l_autre_action() -> void:
	var menu: RemapMenu = _menu()
	menu.apply(&"move_attack", JOY_BUTTON_A)
	assert_array(ActionRemap.joypad_buttons(&"move_attack")).is_equal([JOY_BUTTON_A])
	assert_array(ActionRemap.joypad_buttons(&"move_jump")).is_equal([JOY_BUTTON_X])
	assert_str(_row_button(menu, 0).text).is_equal("X")


func test_b_annule_l_ecoute_puis_ferme_le_menu() -> void:
	var menu: RemapMenu = _menu()
	var closed: Array[bool] = []
	menu.closed.connect(func() -> void: closed.append(true))
	menu.start_listening(&"move_jump")
	_cancel(menu)
	assert_bool(menu.is_listening()).is_false()
	assert_array(closed).is_empty()
	_cancel(menu)
	assert_array(closed).has_size(1)


func test_ouvert_la_premiere_ligne_a_le_focus() -> void:
	var menu: RemapMenu = _menu()
	menu.open()
	assert_that(menu.get_viewport().gui_get_focus_owner()).is_same(_row_button(menu, 0))
