extends GdUnitTestSuite
## L'écran des options, piloté comme un joueur : la difficulté a le focus en premier ; droite et gauche la font tourner
## dans les deux sens ; la flèche du bas puis droite change la définition ; valider le plein écran le bascule ; le
## volume monte d'un cran, s'entend tout de suite, et s'arrête à 1 ; B enregistre et ramène au menu, une seule fois ;
## à la réouverture, l'écran montre ce qui a été enregistré.

const SCENE: String = "res://2_sequence/jeu/options_screen.tscn"
const FICHIER: String = "user://test_options_ecran.cfg"

var _volume_avant: float = 0.0


func before_test() -> void:
	_volume_avant = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Musique"))


func after_test() -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Musique"), _volume_avant)
	if FileAccess.file_exists(FICHIER):
		DirAccess.remove_absolute(FICHIER)


func _ecran() -> OptionsScreen:
	var options: OptionsDef = load("res://5_data/jeu/options.tres").duplicate()
	options.file_path = FICHIER
	var ecran: OptionsScreen = auto_free(load(SCENE).instantiate())
	ecran.options = options
	add_child(ecran)
	return ecran


func _appuyer(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	get_viewport().push_input(event)
	var relache: InputEventKey = event.duplicate()
	relache.pressed = false
	get_viewport().push_input(relache)


func _bouton(index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	get_viewport().push_input(event)


func test_la_difficulte_a_le_focus_et_tourne_dans_les_deux_sens() -> void:
	var ecran := _ecran()
	assert_str(ecran.focused_row).is_equal("difficulte")
	assert_str(ecran.settings.difficulty).is_equal("normal")
	_appuyer(KEY_RIGHT)
	assert_str(ecran.settings.difficulty).is_equal("difficile")
	_appuyer(KEY_RIGHT)
	assert_str(ecran.settings.difficulty).is_equal("facile")
	_appuyer(KEY_LEFT)
	assert_str(ecran.settings.difficulty).is_equal("difficile")
	var vue: OptionsView = ecran.get_node("View")
	assert_str(vue.row_text(&"difficulte")).contains("Difficile")


func test_bas_puis_droite_change_la_definition() -> void:
	var ecran := _ecran()
	_appuyer(KEY_DOWN)
	assert_str(ecran.focused_row).is_equal("definition")
	_appuyer(KEY_RIGHT)
	assert_that(ecran.settings.resolution).is_equal(Vector2i(2560, 1440))
	assert_str(ecran.value_text(&"definition")).is_equal("2560 × 1440")


func test_valider_le_plein_ecran_le_bascule() -> void:
	var ecran := _ecran()
	_appuyer(KEY_DOWN)
	_appuyer(KEY_DOWN)
	assert_str(ecran.focused_row).is_equal("plein_ecran")
	_appuyer(KEY_ENTER)
	assert_bool(ecran.settings.fullscreen).is_true()
	assert_str(ecran.value_text(&"plein_ecran")).is_equal("Oui")


func test_le_volume_monte_s_entend_et_s_arrete_a_un() -> void:
	var ecran := _ecran()
	ecran.focused_row = &"Musique"
	_appuyer(KEY_RIGHT)
	assert_float(ecran.settings.volumes[&"Musique"]).is_equal_approx(0.9, 0.0001)
	assert_float(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Musique"))).is_equal_approx(0.9, 0.001)
	assert_str(ecran.value_text(&"Musique")).is_equal("■■■■■■■■■□")
	_appuyer(KEY_RIGHT)
	_appuyer(KEY_RIGHT)
	assert_float(ecran.settings.volumes[&"Musique"]).is_equal(1.0)


func test_b_enregistre_et_ramene_au_menu_une_seule_fois() -> void:
	var ecran := _ecran()
	var fins: Array[StringName] = []
	ecran.finished.connect(func(next: StringName) -> void: fins.append(next))
	_appuyer(KEY_RIGHT)
	_bouton(JOY_BUTTON_B)
	_bouton(JOY_BUTTON_B)
	assert_array(fins).is_equal([&"menu"])
	assert_bool(FileAccess.file_exists(FICHIER)).is_true()


func test_a_la_reouverture_l_ecran_montre_ce_qui_est_enregistre() -> void:
	var premier := _ecran()
	_appuyer(KEY_RIGHT)
	premier.back()
	remove_child(premier)
	var second := _ecran()
	assert_str(second.settings.difficulty).is_equal("difficile")
