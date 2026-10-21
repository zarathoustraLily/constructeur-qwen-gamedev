class_name BindingNames extends RefCounted
## Les noms montrés des liaisons. Une touche liée par sa place prend le nom qu'elle porte sur le clavier du joueur
## (sur un AZERTY, la touche à la place du W s'appelle Z) ; sans disposition de clavier connue (un jeu lancé sans
## fenêtre), le nom de sa place sur un QWERTY. Les manettes portent les noms d'une manette Xbox (numérotation SDL
## des boutons de Godot 4).

## Noms en français de quelques touches ; les autres gardent le nom que Godot leur donne.
const KEYS: Dictionary[int, String] = {
	KEY_SPACE: "Espace",
	KEY_ENTER: "Entrée",
	KEY_KP_ENTER: "Entrée du pavé",
	KEY_ESCAPE: "Échap",
	KEY_TAB: "Tab",
	KEY_BACKSPACE: "Retour arrière",
	KEY_SHIFT: "Maj",
	KEY_CTRL: "Ctrl",
	KEY_ALT: "Alt",
	KEY_UP: "Flèche haut",
	KEY_DOWN: "Flèche bas",
	KEY_LEFT: "Flèche gauche",
	KEY_RIGHT: "Flèche droite",
}
## Boutons de la souris.
const MOUSE_BUTTONS: Dictionary[int, String] = {
	MOUSE_BUTTON_LEFT: "Clic gauche",
	MOUSE_BUTTON_RIGHT: "Clic droit",
	MOUSE_BUTTON_MIDDLE: "Clic molette",
	MOUSE_BUTTON_WHEEL_UP: "Molette haut",
	MOUSE_BUTTON_WHEEL_DOWN: "Molette bas",
}
## Boutons de la manette.
const PAD_BUTTONS: Dictionary[int, String] = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View",
	JOY_BUTTON_GUIDE: "Xbox",
	JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Croix haut",
	JOY_BUTTON_DPAD_DOWN: "Croix bas",
	JOY_BUTTON_DPAD_LEFT: "Croix gauche",
	JOY_BUTTON_DPAD_RIGHT: "Croix droite",
}
## Axes de la manette, par la fin de leur code de sauvegarde (InputBindings.code_of) : l'axe, puis son sens.
const AXES: Dictionary[String, String] = {
	"0 -": "Stick gauche à gauche",
	"0 +": "Stick gauche à droite",
	"1 -": "Stick gauche en haut",
	"1 +": "Stick gauche en bas",
	"2 -": "Stick droit à gauche",
	"2 +": "Stick droit à droite",
	"3 -": "Stick droit en haut",
	"3 +": "Stick droit en bas",
	"4 +": "LT",
	"5 +": "RT",
}


## Le nom montré de `event`.
static func of(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		return _key_name(key)
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return MOUSE_BUTTONS.get(mouse.button_index, "Bouton de souris %d" % mouse.button_index)
	var button := event as InputEventJoypadButton
	if button != null:
		return PAD_BUTTONS.get(button.button_index, "Bouton %d" % button.button_index)
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return _axis_name(motion)
	return event.as_text()


## Les noms montrés de `events`, séparés par des virgules ; « aucune » s'il n'y en a pas.
static func of_all(events: Array[InputEvent]) -> String:
	var names := PackedStringArray()
	for event: InputEvent in events:
		names.append(of(event))
	return ", ".join(names) if not names.is_empty() else "aucune"


static func _key_name(key: InputEventKey) -> String:
	var code := key.keycode
	if key.physical_keycode != KEY_NONE:
		code = key.physical_keycode
		# Sans disposition de clavier (sans fenêtre), Godot ne sait pas traduire une place en touche.
		if DisplayServer.keyboard_get_layout_count() > 0:
			code = DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode)
	return KEYS.get(code, OS.get_keycode_string(code))


static func _axis_name(motion: InputEventJoypadMotion) -> String:
	var axis := InputBindings.code_of(motion).trim_prefix("axis ")
	return AXES.get(axis, "Axe " + axis)
