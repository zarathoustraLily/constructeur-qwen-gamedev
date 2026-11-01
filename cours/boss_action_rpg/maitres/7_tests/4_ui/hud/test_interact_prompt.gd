extends GdUnitTestSuite
## Règles de l'invite : cachée sans texte ; elle nomme la touche du clavier au départ ; une manette touchée lui fait nommer
## son bouton, le clavier le lui rend ; un stick qui dérive ne compte pas.


func _prompt() -> InteractPrompt:
	var prompt: InteractPrompt = auto_free(InteractPrompt.new())
	add_child(prompt)
	return prompt


func _button() -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.pressed = true
	return event


func _stick(value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	return event


func test_elle_est_cachee_sans_texte() -> void:
	var prompt: InteractPrompt = _prompt()
	prompt.show_prompt("Souffler")
	prompt.show_prompt("")
	assert_bool(prompt.visible).is_false()


func test_elle_nomme_la_touche_du_clavier_au_depart() -> void:
	var prompt: InteractPrompt = _prompt()
	prompt.show_prompt("Souffler")
	assert_bool(prompt.visible).is_true()
	assert_str(prompt.text).is_equal("[F]  Souffler")


func test_une_manette_touchee_lui_fait_nommer_son_bouton_et_le_clavier_le_lui_rend() -> void:
	var prompt: InteractPrompt = _prompt()
	prompt.show_prompt("Souffler")
	prompt._input(_button())
	assert_str(prompt.text).is_equal("[Y]  Souffler")
	prompt._input(InputEventKey.new())
	assert_str(prompt.text).is_equal("[F]  Souffler")


func test_un_stick_qui_derive_ne_compte_pas() -> void:
	var prompt: InteractPrompt = _prompt()
	prompt._input(_stick(0.2))
	assert_bool(prompt.gamepad).is_false()
	prompt._input(_stick(0.9))
	assert_bool(prompt.gamepad).is_true()
