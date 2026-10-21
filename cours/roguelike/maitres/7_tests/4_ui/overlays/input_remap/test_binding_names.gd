extends GdUnitTestSuite
## Règles des noms montrés : quelques touches en français, les autres avec le nom de Godot (sans fenêtre, le nom
## de leur place sur un QWERTY) ; les boutons de souris ; les boutons et les axes d'une manette Xbox, avec le sens
## du stick ; plusieurs liaisons séparées par des virgules, et « aucune » quand il n'y en a pas.


func test_les_touches() -> void:
	assert_str(BindingNames.of(InputBindings.event_from_code("physical %d" % KEY_SPACE))).is_equal("Espace")
	assert_str(BindingNames.of(InputBindings.event_from_code("key %d" % KEY_ESCAPE))).is_equal("Échap")
	# Sans fenêtre (les tests de la vérification), aucune disposition de clavier : le nom de la place sur un QWERTY.
	# Lancé depuis l'éditeur sur un AZERTY, la même touche s'appelle Z.
	var expected := "W"
	if DisplayServer.keyboard_get_layout_count() > 0:
		expected = OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(KEY_W))
	assert_str(BindingNames.of(InputBindings.event_from_code("physical %d" % KEY_W))).is_equal(expected)


func test_les_boutons_de_souris() -> void:
	assert_str(BindingNames.of(InputBindings.event_from_code("mouse 1"))).is_equal("Clic gauche")
	assert_str(BindingNames.of(InputBindings.event_from_code("mouse 9"))).is_equal("Bouton de souris 9")


func test_les_boutons_et_les_axes_de_la_manette() -> void:
	assert_str(BindingNames.of(InputBindings.event_from_code("button %d" % JOY_BUTTON_X))).is_equal("X")
	assert_str(BindingNames.of(InputBindings.event_from_code("axis %d -" % JOY_AXIS_LEFT_Y))).is_equal("Stick gauche en haut")
	assert_str(BindingNames.of(InputBindings.event_from_code("axis %d +" % JOY_AXIS_TRIGGER_RIGHT))).is_equal("RT")


func test_plusieurs_liaisons_et_aucune() -> void:
	var events: Array[InputEvent] = [InputBindings.event_from_code("button 0"), InputBindings.event_from_code("axis 4 +")]
	assert_str(BindingNames.of_all(events)).is_equal("A, LT")
	assert_str(BindingNames.of_all([])).is_equal("aucune")
