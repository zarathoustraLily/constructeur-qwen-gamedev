extends GdUnitTestSuite
## Règles du menu de pause : Start fige le jeu et ouvre le menu, le focus sur « Reprendre » ; une seconde fois, il
## le ferme et relance le jeu ; Échap fait de même, B et « Reprendre » referment ; « Commandes » ouvre le menu des
## contrôles, et B y revient à la pause, le focus sur « Commandes » ; pendant une attente de liaison, Start
## l'annule sans fermer la pause ; le menu tourne pendant la pause, le jeu non. Les entrées sont de vrais événements
## poussés dans l'interface ; aucune liaison n'est changée. Sans réglages des liaisons, le menu le dit.

const PAUSE := preload("res://4_ui/overlays/pause_menu/pause_menu.tscn")
const BINDINGS := preload("res://5_data/input/bindings.tres")

var _pause: PauseMenu


func before_test() -> void:
	_pause = auto_free(PAUSE.instantiate())
	_pause.bindings = BINDINGS
	add_child(_pause)


func after_test() -> void:
	get_tree().paused = false


func _push(event: InputEvent) -> void:
	get_viewport().push_input(event)


func _pad(pad_button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = pad_button
	event.pressed = true
	return event


func _escape() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	return event


func _button(button_name: String) -> Button:
	return _pause.get_node("Screen/Panel/VBoxContainer/" + button_name) as Button


func _remap() -> InputRemapMenu:
	return _pause.get_node("Screen/InputRemapMenu") as InputRemapMenu


func test_start_fige_le_jeu_et_ouvre_le_menu_une_seconde_fois_le_ferme() -> void:
	assert_bool(_pause.is_open()).is_false()
	_push(_pad(JOY_BUTTON_START))
	assert_bool(get_tree().paused).is_true()
	assert_bool(_pause.is_open()).is_true()
	assert_bool(_button("Resume").has_focus()).is_true()
	_push(_pad(JOY_BUTTON_START))
	assert_bool(get_tree().paused).is_false()
	assert_bool(_pause.is_open()).is_false()


func test_echap_ouvre_et_ferme_b_et_reprendre_referment() -> void:
	_push(_escape())
	assert_bool(_pause.is_open()).is_true()
	_push(_escape())
	assert_bool(_pause.is_open()).is_false()
	_push(_escape())
	_push(_pad(JOY_BUTTON_B))
	assert_bool(_pause.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()
	_push(_escape())
	_button("Resume").pressed.emit()
	assert_bool(_pause.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_commandes_ouvre_le_menu_des_controles_et_b_revient_a_la_pause() -> void:
	_push(_pad(JOY_BUTTON_START))
	_button("Controls").pressed.emit()
	assert_bool(_remap().visible).is_true()
	assert_bool((_pause.get_node("Screen/Panel") as Control).visible).is_false()
	assert_bool(_remap().row_of(&"move_forward").keyboard.has_focus()).is_true()
	_push(_pad(JOY_BUTTON_B))
	assert_bool(_remap().visible).is_false()
	assert_bool(_button("Controls").has_focus()).is_true()
	assert_bool(_pause.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()


func test_pendant_une_attente_start_l_annule_sans_fermer_la_pause() -> void:
	_push(_pad(JOY_BUTTON_START))
	_button("Controls").pressed.emit()
	_remap().row_of(&"dash").pad.pressed.emit()
	assert_bool(_remap().is_capturing()).is_true()
	_push(_pad(JOY_BUTTON_START))
	assert_bool(_remap().is_capturing()).is_false()
	assert_bool(_remap().visible).is_true()
	assert_bool(_pause.is_open()).is_true()


func test_le_menu_tourne_pendant_la_pause_le_jeu_non() -> void:
	var game: Node = auto_free(Node.new())
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game)
	_push(_pad(JOY_BUTTON_START))
	assert_bool(_pause.can_process()).is_true()
	assert_bool(game.can_process()).is_false()


func test_sans_reglages_des_liaisons_le_menu_le_dit() -> void:
	var bare: PauseMenu = auto_free(PAUSE.instantiate())
	assert_error(func() -> void: add_child(bare)).is_push_error(
			"PauseMenu : les réglages des liaisons (bindings) ne sont pas posés")
