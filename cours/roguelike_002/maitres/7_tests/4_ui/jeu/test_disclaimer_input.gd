extends GdUnitTestSuite
## Les entrées de l'avertissement : Entrée, le bouton A et le bouton B demandent à passer l'écran ; une autre touche
## ne demande rien.

var _demandes: int = 0


func _entrees() -> DisclaimerInput:
	_demandes = 0
	var entrees: DisclaimerInput = auto_free(DisclaimerInput.new())
	add_child(entrees)
	entrees.skip_requested.connect(func() -> void: _demandes += 1)
	return entrees


func _touche(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _bouton(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	return event


func test_entree_demande_a_passer() -> void:
	_entrees()
	get_viewport().push_input(_touche(KEY_ENTER))
	assert_int(_demandes).is_equal(1)


func test_le_bouton_a_demande_a_passer() -> void:
	_entrees()
	get_viewport().push_input(_bouton(JOY_BUTTON_A))
	assert_int(_demandes).is_equal(1)


func test_le_bouton_b_demande_a_passer() -> void:
	_entrees()
	get_viewport().push_input(_bouton(JOY_BUTTON_B))
	assert_int(_demandes).is_equal(1)


func test_une_autre_touche_ne_demande_rien() -> void:
	_entrees()
	get_viewport().push_input(_touche(KEY_J))
	assert_int(_demandes).is_equal(0)
