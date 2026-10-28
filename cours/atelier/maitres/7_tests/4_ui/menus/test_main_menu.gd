extends GdUnitTestSuite
## Règles du menu principal : ouvert, le premier bouton a le focus ; le focus boucle du dernier bouton au
## premier ; chaque bouton annonce sa demande ; un premier bouton désactivé laisse le focus au suivant.

const MENU := preload("res://4_ui/menus/main_menu.tscn")


func _menu() -> MainMenu:
	var menu: MainMenu = auto_free(MENU.instantiate())
	add_child(menu)
	return menu


func test_ouvert_le_premier_bouton_a_le_focus() -> void:
	var menu: MainMenu = _menu()
	menu.hide()
	menu.open()
	assert_bool(menu.visible).is_true()
	assert_that(menu.get_viewport().gui_get_focus_owner()).is_same(menu.buttons()[0])


func test_le_focus_boucle_du_dernier_au_premier() -> void:
	var menu: MainMenu = _menu()
	var buttons: Array[Control] = menu.buttons()
	var last: Control = buttons[buttons.size() - 1]
	assert_that(last.get_node(last.focus_neighbor_bottom)).is_same(buttons[0])
	assert_that(buttons[0].get_node(buttons[0].focus_neighbor_top)).is_same(last)


func test_chaque_bouton_annonce_sa_demande() -> void:
	var menu: MainMenu = _menu()
	var received: Array[String] = []
	menu.start_requested.connect(func() -> void: received.append("jouer"))
	menu.options_requested.connect(func() -> void: received.append("options"))
#@ 2+
	menu.controls_requested.connect(func() -> void: received.append("commandes"))
#@ all
	menu.quit_requested.connect(func() -> void: received.append("quitter"))
	for button: Control in menu.buttons():
		(button as Button).pressed.emit()
#@ 1
	assert_array(received).is_equal(["jouer", "options", "quitter"])
#@ 2+
	assert_array(received).is_equal(["jouer", "options", "commandes", "quitter"])
#@ all


func test_un_premier_bouton_desactive_laisse_le_focus_au_suivant() -> void:
	var menu: MainMenu = _menu()
	(menu.buttons()[0] as Button).disabled = true
	menu.open()
	assert_that(menu.get_viewport().gui_get_focus_owner()).is_same(menu.buttons()[1])
