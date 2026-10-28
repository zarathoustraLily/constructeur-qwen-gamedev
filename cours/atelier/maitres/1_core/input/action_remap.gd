class_name ActionRemap extends RefCounted
## Les boutons de manette des actions du jeu, et leur remappage : lire les boutons d'une action, lui en donner un
## autre, repérer un bouton déjà pris, et tout écrire dans un dictionnaire ou l'en relire (pour la sauvegarde). Les
## touches du clavier et les axes d'une action ne bougent jamais.

## Le nom court de chaque bouton, tel qu'une manette Xbox l'imprime.
const LABELS: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_BACK: "Vue", JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "Haut", JOY_BUTTON_DPAD_DOWN: "Bas", JOY_BUTTON_DPAD_LEFT: "Gauche", JOY_BUTTON_DPAD_RIGHT: "Droite",
}


## Les boutons de manette de l'action `action`, dans l'ordre d'InputMap.
static func joypad_buttons(action: StringName) -> Array[JoyButton]:
	var buttons: Array[JoyButton] = []
	for event: InputEvent in InputMap.action_get_events(action):
		var joy: InputEventJoypadButton = event as InputEventJoypadButton
		if joy != null:
			buttons.append(joy.button_index)
	return buttons


## Donne le bouton `button` à l'action `action`, à la place de ses autres boutons de manette (toutes manettes :
## appareil -1).
static func rebind(action: StringName, button: JoyButton) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			InputMap.action_erase_event(action, event)
	var joy: InputEventJoypadButton = InputEventJoypadButton.new()
	joy.button_index = button
	joy.device = -1
	InputMap.action_add_event(action, joy)


## Les actions de `actions`, sauf `except`, qui emploient déjà le bouton `button`.
static func conflicts(button: JoyButton, actions: Array[StringName], except: StringName) -> Array[StringName]:
	var found: Array[StringName] = []
	for action: StringName in actions:
		if action != except and button in joypad_buttons(action):
			found.append(action)
	return found


## Le libellé du bouton `button` : « A », « LB »… ; « Bouton N » pour un bouton sans nom connu.
static func label(button: JoyButton) -> String:
	return LABELS.get(button, "Bouton %d" % button)


## Le premier bouton de manette de chaque action de `actions`, pour une sauvegarde : {"move_jump": 0, …} ; une
## action sans bouton n'y figure pas.
static func to_config(actions: Array[StringName]) -> Dictionary[String, int]:
	var config: Dictionary[String, int] = {}
	for action: StringName in actions:
		var buttons: Array[JoyButton] = joypad_buttons(action)
		if not buttons.is_empty():
			config[String(action)] = buttons[0]
	return config


## Applique une sauvegarde faite par to_config : chaque action connue d'InputMap reprend son bouton ; les noms
## inconnus sont ignorés.
static func from_config(config: Dictionary[String, int]) -> void:
	for action_name: String in config:
		if InputMap.has_action(action_name):
			rebind(StringName(action_name), config[action_name] as JoyButton)
