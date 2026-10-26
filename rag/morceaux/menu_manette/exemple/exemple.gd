extends Node
## Exemple : menu de fin de partie à la manette. Avant l'ouverture, la croix ne fait rien : aucun bouton n'a le focus.
## Après open(), le focus est sur « Rejouer » ; croix bas deux fois : « Quitter » ; une troisième fois : il y reste ;
## A valide « Quitter ». Entrée, déclarée avec A dans ui_accept, valide aussi.

const MENU: PackedScene = preload("res://4_ui/overlays/game_over/game_over_menu.tscn")

var _quitter := 0


func _ready() -> void:
	var menu := MENU.instantiate() as GameOverMenu
	add_child(menu)
	menu.quit_requested.connect(func() -> void: _quitter += 1)
	await get_tree().process_frame
	await _appui_manette(JOY_BUTTON_DPAD_DOWN)
	var avant := _focus()
	menu.open()
	await get_tree().process_frame
	var ouvert := _focus()
	await _appui_manette(JOY_BUTTON_DPAD_DOWN)
	await _appui_manette(JOY_BUTTON_DPAD_DOWN)
	var deux_fois := _focus()
	await _appui_manette(JOY_BUTTON_DPAD_DOWN)
	var trois_fois := _focus()
	await _appui_manette(JOY_BUTTON_A)
	var par_a := _quitter
	await _appui_clavier(KEY_ENTER)
	var ok := avant == "aucun" and ouvert == "Retry" and deux_fois == "Quit" and trois_fois == "Quit"
	if ok and par_a == 1 and _quitter == 2:
		print("EXEMPLE VERIFIE : avant open(), focus %s ; après, %s ; croix bas ×2 : %s ; ×3 : %s ; A : quit_requested ; Entrée : encore"
				% [avant, ouvert, deux_fois, trois_fois])
	else:
		push_error("avant %s, ouvert %s, ×2 %s, ×3 %s, par A %d, total %d" % [avant, ouvert, deux_fois, trois_fois, par_a, _quitter])
	get_tree().quit()


func _focus() -> String:
	var c := get_viewport().gui_get_focus_owner()
	return String(c.name) if c != null else "aucun"


## Appuie puis relâche un bouton de la première manette, comme une vraie (Input.parse_input_event).
func _appui_manette(bouton: JoyButton) -> void:
	for appuye: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = bouton
		e.pressed = appuye
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await get_tree().process_frame


func _appui_clavier(touche: Key) -> void:
	for appuye: bool in [true, false]:
		var e := InputEventKey.new()
		e.keycode = touche
		e.pressed = appuye
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await get_tree().process_frame
