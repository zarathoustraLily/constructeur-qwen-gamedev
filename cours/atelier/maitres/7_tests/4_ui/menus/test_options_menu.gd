extends GdUnitTestSuite
## Règles des options : les curseurs montrent les volumes actuels sans les annoncer ; un curseur déplacé
## annonce son bus et sa valeur, et son libellé suit ; les curseurs avancent du pas des réglages ; Retour ou
## ui_cancel ferme le menu ; ouvert, le premier curseur a le focus.

const MENU := preload("res://4_ui/menus/options_menu.tscn")

var _received: Array = []


func _menu() -> OptionsMenu:
	var menu: OptionsMenu = auto_free(MENU.instantiate())
	add_child(menu)
	_received.clear()
	menu.volume_changed.connect(func(bus: StringName, linear: float) -> void: _received.append([bus, linear]))
	return menu


func _slider(menu: OptionsMenu, row: String) -> HSlider:
	return menu.get_node("Center/Rows/%s/Slider" % row) as HSlider


func _label(menu: OptionsMenu, row: String) -> Label:
	return menu.get_node("Center/Rows/%s/Value" % row) as Label


func test_les_volumes_actuels_se_montrent_sans_etre_annonces() -> void:
	var menu: OptionsMenu = _menu()
	menu.show_volumes(0.4, 0.8)
	assert_float(_slider(menu, "Music").value).is_equal_approx(0.4, 0.0001)
	assert_float(_slider(menu, "Sfx").value).is_equal_approx(0.8, 0.0001)
	assert_str(_label(menu, "Music").text).is_equal("40 %")
	assert_str(_label(menu, "Sfx").text).is_equal("80 %")
	assert_array(_received).is_empty()


func test_un_curseur_deplace_annonce_son_bus_et_son_libelle_suit() -> void:
	var menu: OptionsMenu = _menu()
	_slider(menu, "Sfx").value = 0.3
	assert_array(_received).is_equal([[AudioManager.SFX, 0.3]])
	assert_str(_label(menu, "Sfx").text).is_equal("30 %")


func test_les_curseurs_avancent_du_pas_des_reglages() -> void:
	var menu: OptionsMenu = _menu()
	assert_float(_slider(menu, "Music").step).is_equal(menu.settings.volume_step)
	assert_float(_slider(menu, "Music").max_value).is_equal(1.0)


func test_retour_ferme_le_menu() -> void:
	var menu: OptionsMenu = _menu()
	var closed: Array[bool] = []
	menu.closed.connect(func() -> void: closed.append(true))
	(menu.get_node("Center/Rows/Back") as Button).pressed.emit()
	assert_array(closed).has_size(1)


func test_ui_cancel_ferme_le_menu() -> void:
	var menu: OptionsMenu = _menu()
	var closed: Array[bool] = []
	menu.closed.connect(func() -> void: closed.append(true))
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	menu.get_viewport().push_input(event)
	assert_array(closed).has_size(1)


func test_ouvert_le_premier_curseur_a_le_focus() -> void:
	var menu: OptionsMenu = _menu()
	menu.open()
	assert_that(menu.get_viewport().gui_get_focus_owner()).is_same(_slider(menu, "Music"))
