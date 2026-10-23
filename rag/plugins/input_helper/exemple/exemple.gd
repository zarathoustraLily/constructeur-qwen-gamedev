extends Node
## Exemple minimal d'Input Helper (v4.7.0, GDScript) : donner un bouton de manette à une action, le relire, et
## demander à l'autoload InputHelper de quel appareil vient un événement.


func _ready() -> void:
	InputMap.add_action(&"sauter")
	var espace := InputEventKey.new()
	espace.physical_keycode = KEY_SPACE
	InputMap.action_add_event(&"sauter", espace)
	var bouton_a := InputEventJoypadButton.new()
	bouton_a.button_index = JOY_BUTTON_A
	InputHelper.set_joypad_input_for_action("sauter", bouton_a)
	var bouton := InputHelper.get_joypad_input_for_action("sauter") as InputEventJoypadButton
	var clavier: String = InputHelper.get_device_from_event(espace)
	var manette: String = InputHelper.get_device_from_event(bouton_a)
	if bouton != null and bouton.button_index == JOY_BUTTON_A and clavier == InputHelper.DEVICE_KEYBOARD \
			and manette != InputHelper.DEVICE_KEYBOARD:
		print("EXEMPLE VERIFIE : « sauter » au bouton %d ; espace → %s, bouton A → %s" % [bouton.button_index, clavier, manette])
	else:
		push_error("bouton %s, clavier %s, manette %s" % [bouton, clavier, manette])
	get_tree().quit()
