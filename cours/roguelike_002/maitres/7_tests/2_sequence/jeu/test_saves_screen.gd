extends GdUnitTestSuite
## L'écran des sauvegardes, piloté comme un joueur : quatre emplacements libres ; Entrée sur un libre lance une partie
## neuve, écrite, avec une graine tirée du hasard donné ; un occupé ouvre ses actions ; Continuer lance la partie
## enregistrée ; Effacer demande confirmation avec « Non » en avant, Non revient aux actions, Oui efface ; B revient
## d'un cran jusqu'au menu ; un fichier illisible n'offre pas « Continuer ».

const SCENE: String = "res://2_sequence/jeu/saves_screen.tscn"
const DOSSIER: String = "user://test_sauvegardes_ecran"
const GRAINE: int = 99

var _fins: Array[StringName] = []


func after_test() -> void:
	if not DirAccess.dir_exists_absolute(DOSSIER):
		return
	for nom: String in DirAccess.get_files_at(DOSSIER):
		DirAccess.remove_absolute(DOSSIER.path_join(nom))
	DirAccess.remove_absolute(DOSSIER)


func _donnee() -> SavesDef:
	var saves: SavesDef = load("res://5_data/jeu/sauvegardes.tres").duplicate()
	saves.directory = DOSSIER
	saves.start_screen = &"partie"
	return saves


func _ecran() -> SavesScreen:
	_fins.clear()
	var ecran: SavesScreen = auto_free(load(SCENE).instantiate())
	ecran.saves = _donnee()
	ecran.use_rng(RngSource.new(GRAINE).instance())
	ecran.finished.connect(func(next: StringName) -> void: _fins.append(next))
	add_child(ecran)
	return ecran


func _occuper(slot: int) -> void:
	SaveSystem.new(_donnee()).new_game(slot, 5)


func _appuyer(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	get_viewport().push_input(event)
	var relache: InputEventKey = event.duplicate()
	relache.pressed = false
	get_viewport().push_input(relache)


func _vue(ecran: SavesScreen) -> SavesView:
	return ecran.get_node("View")


func test_quatre_emplacements_libres() -> void:
	var ecran := _ecran()
	for slot: int in 4:
		assert_str(_vue(ecran).slot_text(slot)).is_equal("Emplacement %d — libre : nouvelle partie" % (slot + 1))


func test_entree_sur_un_libre_lance_une_partie_neuve() -> void:
	var ecran := _ecran()
	var lancees: Array[int] = []
	ecran.game_started.connect(func(slot: int, _save: Dictionary) -> void: lancees.append(slot))
	_appuyer(KEY_DOWN)
	_appuyer(KEY_ENTER)
	assert_array(lancees).is_equal([1])
	assert_array(_fins).is_equal([&"partie"])
	assert_int(ecran.system().state_of(1)).is_equal(SaveSystem.SlotState.VALID)
	assert_int(int(ecran.started_save["graine"])).is_equal(RngSource.new(GRAINE).instance().randi())


func test_un_occupe_ouvre_ses_actions_et_continuer_lance_la_partie() -> void:
	_occuper(0)
	var ecran := _ecran()
	assert_str(_vue(ecran).slot_text(0)).contains("camp")
	_appuyer(KEY_ENTER)
	assert_str(_vue(ecran).visible_panel()).is_equal("actions")
	assert_array(_vue(ecran).shown_actions()).is_equal([&"continuer", &"effacer", &"retour"])
	_appuyer(KEY_ENTER)
	assert_array(_fins).is_equal([&"partie"])
	assert_int(int(ecran.started_save["graine"])).is_equal(5)


func test_effacer_demande_confirmation_non_d_abord() -> void:
	_occuper(0)
	var ecran := _ecran()
	_appuyer(KEY_ENTER)
	_appuyer(KEY_DOWN)
	_appuyer(KEY_ENTER)
	assert_int(ecran.mode).is_equal(SavesScreen.Mode.CONFIRM)
	_appuyer(KEY_ENTER)
	assert_int(ecran.mode).is_equal(SavesScreen.Mode.ACTIONS)
	assert_int(ecran.system().state_of(0)).is_equal(SaveSystem.SlotState.VALID)


func test_oui_efface_et_revient_a_la_liste() -> void:
	_occuper(0)
	var ecran := _ecran()
	ecran.choose_slot(0)
	ecran.choose_action(&"effacer")
	ecran.confirm(true)
	assert_int(ecran.mode).is_equal(SavesScreen.Mode.LIST)
	assert_int(ecran.system().state_of(0)).is_equal(SaveSystem.SlotState.EMPTY)
	assert_str(_vue(ecran).slot_text(0)).contains("libre")


func test_b_revient_d_un_cran_jusqu_au_menu() -> void:
	_occuper(0)
	var ecran := _ecran()
	ecran.choose_slot(0)
	ecran.choose_action(&"effacer")
	_appuyer(KEY_ESCAPE)
	assert_int(ecran.mode).is_equal(SavesScreen.Mode.ACTIONS)
	_appuyer(KEY_ESCAPE)
	assert_int(ecran.mode).is_equal(SavesScreen.Mode.LIST)
	_appuyer(KEY_ESCAPE)
	assert_array(_fins).is_equal([&"menu"])


func test_un_fichier_illisible_n_offre_pas_continuer() -> void:
	var saves := _donnee()
	DirAccess.make_dir_recursive_absolute(DOSSIER)
	var fichier := FileAccess.open(SaveSystem.new(saves).path_of(2), FileAccess.WRITE)
	fichier.store_string("abîmé")
	fichier.close()
	var ecran := _ecran()
	assert_str(_vue(ecran).slot_text(2)).contains("illisible")
	ecran.choose_slot(2)
	assert_array(_vue(ecran).shown_actions()).is_equal([&"effacer", &"retour"])
	ecran.choose_action(&"continuer")
	assert_array(_fins).is_empty()
