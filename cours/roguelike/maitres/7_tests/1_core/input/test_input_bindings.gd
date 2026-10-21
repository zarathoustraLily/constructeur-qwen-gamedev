extends GdUnitTestSuite
## Règles des liaisons : chaque entrée a son appareil ; une liaison ne naît que d'un appui (une touche par sa place,
## un bouton) ou d'un axe poussé au-delà du seuil, avec son sens, et vaut pour toutes les manettes ; lier remplace
## les entrées du même appareil et garde celles de l'autre ; la sauvegarde rend les liaisons, seulement celles des
## actions demandées ; une sauvegarde absente, ou d'une autre version, ne change rien ; revenir aux liaisons du
## projet efface la sauvegarde ; chaque code de sauvegarde redonne son entrée.

const SAVE_PATH := "user://test_input_bindings.cfg"
const ACTIONS: Array[StringName] = [&"dash", &"attack"]


func after_test() -> void:
	InputBindings.reset(SAVE_PATH)


func _key(physical: Key, is_down: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical
	event.pressed = is_down
	return event


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


func _keyboard_codes(action: StringName) -> PackedStringArray:
	var codes := PackedStringArray()
	for event: InputEvent in InputBindings.events_for(action, InputBindings.Device.KEYBOARD):
		codes.append(InputBindings.code_of(event))
	return codes


func test_chaque_entree_a_son_appareil() -> void:
	assert_int(InputBindings.device_of(_key(KEY_K))).is_equal(InputBindings.Device.KEYBOARD)
	assert_int(InputBindings.device_of(InputEventMouseButton.new())).is_equal(InputBindings.Device.KEYBOARD)
	assert_int(InputBindings.device_of(InputEventJoypadButton.new())).is_equal(InputBindings.Device.PAD)
	assert_int(InputBindings.device_of(_axis(JOY_AXIS_LEFT_X, 1.0))).is_equal(InputBindings.Device.PAD)
	assert_int(InputBindings.device_of(InputEventMouseMotion.new())).is_equal(InputBindings.Device.NONE)


func test_une_liaison_nait_d_un_appui_et_vaut_pour_toutes_les_manettes() -> void:
	var press := _key(KEY_K)
	press.shift_pressed = true
	var binding := InputBindings.binding_from(press, InputBindings.Device.KEYBOARD) as InputEventKey
	assert_int(binding.physical_keycode).is_equal(KEY_K)
	assert_bool(binding.shift_pressed).is_false()
	assert_int(binding.device).is_equal(InputBindings.ALL_DEVICES)
	assert_object(InputBindings.binding_from(_key(KEY_K, false), InputBindings.Device.KEYBOARD)).is_null()
	var echo := _key(KEY_K)
	echo.echo = true
	assert_object(InputBindings.binding_from(echo, InputBindings.Device.KEYBOARD)).is_null()
	assert_object(InputBindings.binding_from(_key(KEY_K), InputBindings.Device.PAD)).is_null()
	var pad_button := InputEventJoypadButton.new()
	pad_button.button_index = JOY_BUTTON_Y
	pad_button.pressed = true
	pad_button.device = 1
	var pad_binding := InputBindings.binding_from(pad_button, InputBindings.Device.PAD) as InputEventJoypadButton
	assert_int(pad_binding.button_index).is_equal(JOY_BUTTON_Y)
	assert_int(pad_binding.device).is_equal(InputBindings.ALL_DEVICES)


func test_un_axe_se_lie_au_dela_du_seuil_avec_son_sens() -> void:
	assert_object(InputBindings.binding_from(_axis(JOY_AXIS_RIGHT_Y, -0.3), InputBindings.Device.PAD)).is_null()
	var binding := InputBindings.binding_from(_axis(JOY_AXIS_RIGHT_Y, -0.8), InputBindings.Device.PAD) as InputEventJoypadMotion
	assert_int(binding.axis).is_equal(JOY_AXIS_RIGHT_Y)
	assert_float(binding.axis_value).is_equal(-1.0)


func test_lier_remplace_le_meme_appareil_et_garde_l_autre() -> void:
	var pad_before := InputBindings.events_for(&"dash", InputBindings.Device.PAD).size()
	InputBindings.bind(&"dash", InputBindings.binding_from(_key(KEY_K), InputBindings.Device.KEYBOARD))
	assert_array(_keyboard_codes(&"dash")).is_equal(PackedStringArray(["physical %d" % KEY_K]))
	assert_int(InputBindings.events_for(&"dash", InputBindings.Device.PAD).size()).is_equal(pad_before)
	assert_int(pad_before).is_equal(2)


func test_la_sauvegarde_rend_les_liaisons_des_actions_demandees() -> void:
	InputBindings.bind(&"dash", InputBindings.binding_from(_key(KEY_K), InputBindings.Device.KEYBOARD))
	InputBindings.bind(&"move_left", InputBindings.binding_from(_key(KEY_J), InputBindings.Device.KEYBOARD))
	assert_int(InputBindings.save_to(SAVE_PATH, ACTIONS)).is_equal(OK)
	InputMap.load_from_project_settings()
	assert_bool(InputBindings.load_from(SAVE_PATH, ACTIONS)).is_true()
	assert_array(_keyboard_codes(&"dash")).is_equal(PackedStringArray(["physical %d" % KEY_K]))
	assert_int(InputBindings.events_for(&"dash", InputBindings.Device.PAD).size()).is_equal(2)
	assert_array(_keyboard_codes(&"move_left")).is_equal(PackedStringArray(["physical %d" % KEY_A]))


func test_une_sauvegarde_absente_ou_d_une_autre_version_ne_change_rien() -> void:
	assert_bool(InputBindings.load_from(SAVE_PATH, ACTIONS)).is_false()
	var file := ConfigFile.new()
	file.set_value("meta", "version", InputBindings.VERSION + 1)
	file.set_value("bindings", "dash", PackedStringArray(["physical %d" % KEY_K]))
	assert_int(file.save(SAVE_PATH)).is_equal(OK)
	assert_bool(InputBindings.load_from(SAVE_PATH, ACTIONS)).is_false()
	assert_array(_keyboard_codes(&"dash")).is_equal(PackedStringArray(["physical %d" % KEY_SPACE]))


func test_revenir_aux_liaisons_du_projet_efface_la_sauvegarde() -> void:
	InputBindings.bind(&"dash", InputBindings.binding_from(_key(KEY_K), InputBindings.Device.KEYBOARD))
	InputBindings.save_to(SAVE_PATH, ACTIONS)
	InputBindings.reset(SAVE_PATH)
	assert_bool(FileAccess.file_exists(SAVE_PATH)).is_false()
	assert_array(_keyboard_codes(&"dash")).is_equal(PackedStringArray(["physical %d" % KEY_SPACE]))


func test_chaque_code_de_sauvegarde_redonne_son_entree() -> void:
	for code: String in ["physical 75", "key 32", "mouse 1", "button 0", "axis 3 -", "axis 5 +"]:
		assert_str(InputBindings.code_of(InputBindings.event_from_code(code))).is_equal(code)
	assert_object(InputBindings.event_from_code("inconnu 3")).is_null()
	assert_object(InputBindings.event_from_code("axis 3")).is_null()
