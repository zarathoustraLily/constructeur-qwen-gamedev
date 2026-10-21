extends GdUnitTestSuite
## Règles du menu des contrôles : une ligne par action, avec ses liaisons nommées, et le focus sur la première ;
## choisir le bouton clavier d'une ligne puis appuyer sur une touche lie cette touche, garde la manette, sauvegarde
## et rend le focus au bouton ; à la manette (la croix, puis A), un bouton ; un stick poussé, qui ne déplace pas le
## focus en revenant au repos ; la pause annule l'attente sans rien lier ; une entrée déjà liée ailleurs est
## signalée ; « Par défaut » remet les liaisons du jeu ; hors de l'attente, B ferme le menu, pendant, il se lie.
## Les entrées sont de vrais événements poussés dans l'interface.

const MENU := preload("res://4_ui/overlays/input_remap/input_remap_menu.tscn")
const SETTINGS := preload("res://5_data/input/bindings.tres")
const SAVE_PATH := "user://test_input_remap.cfg"

var _menu: InputRemapMenu


func before_test() -> void:
	var settings := SETTINGS.duplicate() as BindingSettings
	settings.save_path = SAVE_PATH
	_menu = auto_free(MENU.instantiate())
	add_child(_menu)
	_menu.setup(settings)
	_menu.open()


func after_test() -> void:
	InputBindings.reset(SAVE_PATH)


# Les conteneurs placent les lignes à l'image suivante : la croix cherche ses voisins d'après leur place.
func _laid_out() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _push(event: InputEvent) -> void:
	get_viewport().push_input(event)


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


func _escape() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event


func _pad(pad_button: JoyButton, is_down: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = pad_button
	event.pressed = is_down
	return event


func _tap(pad_button: JoyButton) -> void:
	_push(_pad(pad_button))
	_push(_pad(pad_button, false))


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


# Un mouvement du stick gauche passé par Input, comme une vraie manette : l'interface ne suit un stick que quand
# Input voit son action s'enfoncer à cette image (is_action_just_pressed).
func _stick(value: float) -> void:
	Input.parse_input_event(_axis(JOY_AXIS_LEFT_Y, value))
	Input.flush_buffered_events()


func _status() -> String:
	return (_menu.get_node("VBoxContainer/Status") as Label).text


func test_une_ligne_par_action_avec_ses_liaisons_nommees_et_le_focus() -> void:
	assert_int(_menu.get_node("VBoxContainer/Rows").get_child_count()).is_equal(SETTINGS.titles.size())
	var dash := _menu.row_of(&"dash")
	assert_str(dash.keyboard.text).is_equal("Espace")
	assert_str(dash.pad.text).is_equal("A, LT")
	assert_bool(_menu.row_of(&"move_forward").keyboard.has_focus()).is_true()


func test_au_clavier_une_touche_se_lie_garde_la_manette_et_se_sauvegarde() -> void:
	var dash := _menu.row_of(&"dash")
	dash.keyboard.pressed.emit()
	assert_bool(_menu.is_capturing()).is_true()
	assert_str(dash.keyboard.text).is_equal("…")
	_push(_key(KEY_K))
	assert_bool(_menu.is_capturing()).is_false()
	assert_str(dash.keyboard.text).is_equal("K")
	assert_str(dash.pad.text).is_equal("A, LT")
	assert_bool(dash.keyboard.has_focus()).is_true()
	InputMap.load_from_project_settings()
	assert_bool(InputBindings.load_from(SAVE_PATH, _menu.settings.actions())).is_true()
	assert_str(BindingNames.of_all(InputBindings.events_for(&"dash", InputBindings.Device.KEYBOARD))).is_equal("K")


func test_a_la_manette_la_croix_puis_a_puis_un_bouton() -> void:
	await _laid_out()
	var first := _menu.row_of(&"move_forward")
	_tap(JOY_BUTTON_DPAD_RIGHT)
	assert_bool(first.pad.has_focus()).is_true()
	_tap(JOY_BUTTON_A)
	assert_bool(_menu.is_capturing()).is_true()
	_push(_pad(JOY_BUTTON_Y))
	assert_str(first.pad.text).is_equal("Y")
	assert_str(first.keyboard.text).is_equal("W")
	assert_bool(first.pad.has_focus()).is_true()


func test_un_stick_lie_ne_deplace_pas_le_focus_en_revenant_au_repos() -> void:
	await _laid_out()
	var attack := _menu.row_of(&"attack")
	attack.pad.pressed.emit()
	_stick(0.4)
	assert_bool(_menu.is_capturing()).is_true()
	_stick(0.9)
	assert_str(attack.pad.text).is_equal("Stick gauche en bas")
	# À la même image, ui_down vient de s'enfoncer : sans le menu, ce mouvement descendrait d'une ligne.
	_stick(0.7)
	assert_bool(attack.pad.has_focus()).is_true()
	# Revenu au repos puis poussé de nouveau, le stick déplace le focus : vers la ligne du dessous.
	_stick(0.1)
	await get_tree().process_frame
	_stick(0.9)
	assert_bool(_menu.row_of(&"dash").pad.has_focus()).is_true()
	_stick(0.0)


func test_la_pause_annule_l_attente_sans_rien_lier() -> void:
	var dash := _menu.row_of(&"dash")
	dash.keyboard.pressed.emit()
	_push(_escape())
	assert_bool(_menu.is_capturing()).is_false()
	assert_str(dash.keyboard.text).is_equal("Espace")
	assert_str(_status()).contains("Annulé")
	dash.pad.pressed.emit()
	_push(_pad(JOY_BUTTON_START))
	assert_bool(_menu.is_capturing()).is_false()
	assert_str(dash.pad.text).is_equal("A, LT")
	assert_bool(FileAccess.file_exists(SAVE_PATH)).is_false()
	assert_bool(_menu.visible).is_true()


func test_une_entree_deja_liee_ailleurs_est_signalee() -> void:
	_menu.row_of(&"dash").keyboard.pressed.emit()
	_push(_key(KEY_W))
	assert_str(_status()).contains("aussi lié à : Haut")


func test_par_defaut_remet_les_liaisons_du_jeu() -> void:
	var dash := _menu.row_of(&"dash")
	dash.keyboard.pressed.emit()
	_push(_key(KEY_K))
	(_menu.get_node("VBoxContainer/Buttons/Reset") as Button).pressed.emit()
	assert_str(dash.keyboard.text).is_equal("Espace")
	assert_bool(FileAccess.file_exists(SAVE_PATH)).is_false()


func test_hors_de_l_attente_b_ferme_le_menu_pendant_il_se_lie() -> void:
	var closings: Array[bool] = []
	_menu.closed.connect(func() -> void: closings.append(true))
	var dash := _menu.row_of(&"dash")
	dash.pad.pressed.emit()
	_push(_pad(JOY_BUTTON_B))
	assert_str(dash.pad.text).is_equal("B")
	assert_bool(_menu.visible).is_true()
	_push(_pad(JOY_BUTTON_B))
	assert_bool(_menu.visible).is_false()
	assert_array(closings).is_equal([true])
