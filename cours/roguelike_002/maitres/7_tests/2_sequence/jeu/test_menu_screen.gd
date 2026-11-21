extends GdUnitTestSuite
## Le menu principal et son mouvement, mesurés image par image : le titre tombe à sa place, les choix arrivent l'un
## après l'autre, on ne peut rien choisir pendant l'entrée, puis le premier choix a le focus ; la flèche du bas met le
## suivant en avant, qui grandit ; un choix pas encore disponible tremble puis revient ; quitter le demande ; un choix
## qui mène quelque part fait partir l'écran, qui finit une seule fois. Le fond glisse et revient.

const SCENE: String = "res://2_sequence/jeu/menu_screen.tscn"
const PAS: float = 0.05


func _donnee() -> MenuDef:
	var menu: MenuDef = load("res://5_data/jeu/menu.tres").duplicate()
	menu.targets = {&"jouer": &"suite"}
	return menu


func _ecran(menu: MenuDef) -> MenuScreen:
	var ecran: MenuScreen = auto_free(load(SCENE).instantiate())
	if menu != null:
		ecran.menu = menu
	ecran.quits_game = false
	add_child(ecran)
	ecran.set_process(false)
	return ecran


func _avancer(ecran: MenuScreen, secondes: float) -> void:
	var reste: float = secondes
	while reste > 0.0:
		ecran.advance(minf(PAS, reste))
		reste -= PAS


func _touche(code: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event


func _vue(ecran: MenuScreen) -> MenuView:
	return ecran.get_node("View")


func test_le_titre_tombe_a_sa_place() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	var titre: Label = _vue(ecran).title_label()
	assert_float(titre.position.y).is_equal_approx(menu.title_y_px - menu.title_drop_px, 0.01)
	assert_float(titre.modulate.a).is_equal(0.0)
	_avancer(ecran, menu.title_delay_s + menu.title_in_s)
	assert_float(titre.position.y).is_equal_approx(menu.title_y_px, 0.01)
	assert_float(titre.modulate.a).is_equal(1.0)


func test_les_choix_arrivent_l_un_apres_l_autre() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	var premier: Button = _vue(ecran).button_of(&"jouer")
	var second: Button = _vue(ecran).button_of(&"options")
	_avancer(ecran, menu.items_delay_s + menu.item_in_s)
	assert_float(premier.position.x).is_equal_approx(menu.items_origin_px.x, 0.01)
	assert_float(second.position.x).is_greater(menu.items_origin_px.x)
	assert_float(second.modulate.a).is_less(1.0)
	assert_float(second.position.y - premier.position.y).is_equal_approx(menu.item_spacing_px, 0.01)


func test_pendant_l_entree_on_ne_choisit_rien() -> void:
	var ecran := _ecran(_donnee())
	ecran.choose(&"jouer")
	assert_int(ecran.phase).is_equal(MenuScreen.Phase.INTRO)
	assert_int(_vue(ecran).button_of(&"jouer").focus_mode).is_equal(Control.FOCUS_NONE)


func test_apres_l_entree_le_premier_choix_a_le_focus() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	_avancer(ecran, menu.intro_s() + PAS)
	assert_int(ecran.phase).is_equal(MenuScreen.Phase.READY)
	assert_bool(_vue(ecran).button_of(&"jouer").has_focus()).is_true()
	assert_str(ecran.focused).is_equal("jouer")


func test_la_fleche_du_bas_met_le_suivant_en_avant() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	_avancer(ecran, menu.intro_s() + PAS)
	get_viewport().push_input(_touche(KEY_DOWN, true))
	get_viewport().push_input(_touche(KEY_DOWN, false))
	assert_str(ecran.focused).is_equal("options")
	_avancer(ecran, menu.focus_s)
	var options: Button = _vue(ecran).button_of(&"options")
	assert_float(options.scale.x).is_equal_approx(menu.focus_scale, 0.001)
	assert_float(options.position.x).is_equal_approx(menu.items_origin_px.x + menu.focus_shift_px, 0.01)
	assert_float(_vue(ecran).button_of(&"jouer").scale.x).is_equal(1.0)


func test_un_choix_indisponible_tremble_puis_revient() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	_avancer(ecran, menu.intro_s() + PAS)
	var refuses: Array[StringName] = []
	ecran.unavailable.connect(func(item: StringName) -> void: refuses.append(item))
	ecran.choose(&"options")
	assert_array(refuses).is_equal([&"options"])
	assert_int(ecran.phase).is_equal(MenuScreen.Phase.READY)
	var options: Button = _vue(ecran).button_of(&"options")
	var ecarts: Array[float] = []
	var temps: float = 0.0
	while temps < menu.refuse_s:
		_avancer(ecran, PAS)
		temps += PAS
		ecarts.append(absf(options.position.x - menu.items_origin_px.x))
	assert_float(ecarts.max()).is_greater(1.0)
	_avancer(ecran, PAS)
	assert_float(options.position.x).is_equal_approx(menu.items_origin_px.x, 0.01)


func test_quitter_le_demande() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	_avancer(ecran, menu.intro_s() + PAS)
	var demandes: Array[bool] = []
	ecran.quit_requested.connect(func() -> void: demandes.append(true))
	ecran.choose(&"quitter")
	assert_array(demandes).has_size(1)


func test_un_choix_qui_mene_quelque_part_fait_partir_l_ecran() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	var fins: Array[StringName] = []
	ecran.finished.connect(func(next: StringName) -> void: fins.append(next))
	_avancer(ecran, menu.intro_s() + PAS)
	ecran.choose(&"jouer")
	assert_int(ecran.phase).is_equal(MenuScreen.Phase.LEAVING)
	assert_int(_vue(ecran).button_of(&"jouer").focus_mode).is_equal(Control.FOCUS_NONE)
	_avancer(ecran, menu.leave_s + PAS)
	assert_array(fins).is_equal([&"suite"])
	assert_float(_vue(ecran).modulate.a).is_equal(0.0)


func test_le_fond_glisse_puis_revient() -> void:
	var menu := _donnee()
	var ecran := _ecran(menu)
	var fond: TextureRect = _vue(ecran).background()
	var aller: float = menu.background_travel_px / menu.background_speed_px_s
	_avancer(ecran, aller * 0.5)
	assert_float(fond.position.x).is_equal_approx(-menu.background_travel_px * 0.5, 0.5)
	_avancer(ecran, aller)
	assert_float(fond.position.x).is_equal_approx(-menu.background_travel_px * 0.5, 0.5)
#@ 4-5


func test_dans_le_jeu_jouer_n_est_pas_encore_disponible() -> void:
	var ecran := _ecran(null)
	_avancer(ecran, ecran.menu.intro_s() + PAS)
	var refuses: Array[StringName] = []
	ecran.unavailable.connect(func(item: StringName) -> void: refuses.append(item))
	get_viewport().push_input(_touche(KEY_ENTER, true))
	get_viewport().push_input(_touche(KEY_ENTER, false))
	assert_array(refuses).is_equal([&"jouer"])
#@ all
