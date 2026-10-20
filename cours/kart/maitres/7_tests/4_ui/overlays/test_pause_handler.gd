extends GdUnitTestSuite
## Règles du gestionnaire de pause : F1 ou Start ouvrent et ferment le menu des contrôles, B et Échap
## ferment le menu ouvert, et pendant une capture de touche, Échap, F1 ou Start l'annulent sans fermer
## le menu. Le gestionnaire reste actif quand le jeu est en pause.
## « Échap, menu fermé, quitte le jeu » n'est pas testé ici : cela arrêterait les tests eux-mêmes.

const SCRIPT_GESTIONNAIRE := "res://4_ui/overlays/pause_handler.gd"
const SCENE_MENU := "res://4_ui/overlays/input_remap/input_remap_menu.tscn"

var _gestionnaire: Node
var _menu: InputRemapMenu


func before_test() -> void:
	_gestionnaire = auto_free(Node.new())
	_gestionnaire.set_script(load(SCRIPT_GESTIONNAIRE))
	_menu = load(SCENE_MENU).instantiate()
	_menu.name = "InputRemapMenu"
	_gestionnaire.add_child(_menu)
	add_child(_gestionnaire)


func after_test() -> void:
	if _menu.is_open():
		_menu.close()


func _touche(code: Key) -> InputEventKey:
	var evenement := InputEventKey.new()
	evenement.keycode = code
	evenement.pressed = true
	return evenement


func test_f1_ouvre_le_menu_des_controles_et_met_le_jeu_en_pause() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	assert_bool(_menu.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()


func test_f1_une_deuxieme_fois_ferme_le_menu_et_reprend_le_jeu() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	_gestionnaire._input(_touche(KEY_F1))
	assert_bool(_menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_echap_ferme_le_menu_ouvert_sans_quitter() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	_gestionnaire._input(_touche(KEY_ESCAPE))
	assert_bool(_menu.is_open()).is_false()
	assert_bool(is_instance_valid(_gestionnaire)).is_true()


func test_le_gestionnaire_reste_actif_pendant_la_pause() -> void:
	assert_int(_gestionnaire.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)


func _bouton(index: JoyButton) -> InputEventJoypadButton:
	var evenement := InputEventJoypadButton.new()
	evenement.button_index = index
	evenement.pressed = true
	return evenement


func test_start_ouvre_puis_ferme_le_menu() -> void:
	_gestionnaire._input(_bouton(JOY_BUTTON_START))
	assert_bool(_menu.is_open()).is_true()
	_gestionnaire._input(_bouton(JOY_BUTTON_START))
	assert_bool(_menu.is_open()).is_false()


func test_b_ferme_le_menu_ouvert() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	_gestionnaire._input(_bouton(JOY_BUTTON_B))
	assert_bool(_menu.is_open()).is_false()


func test_b_n_ouvre_pas_le_menu() -> void:
	_gestionnaire._input(_bouton(JOY_BUTTON_B))
	assert_bool(_menu.is_open()).is_false()


func test_pendant_une_capture_echap_l_annule_sans_fermer_le_menu() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	_menu._start_binding("move_forward")
	assert_bool(_menu.is_capturing()).is_true()
	_gestionnaire._input(_touche(KEY_ESCAPE))
	assert_bool(_menu.is_capturing()).is_false()
	assert_bool(_menu.is_open()).is_true()


func test_pendant_une_capture_f1_l_annule_sans_fermer_le_menu() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	_menu._start_binding("move_forward")
	_gestionnaire._input(_touche(KEY_F1))
	assert_bool(_menu.is_capturing()).is_false()
	assert_bool(_menu.is_open()).is_true()


func test_pendant_une_capture_start_l_annule_sans_fermer_le_menu() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	_menu._start_binding("move_forward")
	_gestionnaire._input(_bouton(JOY_BUTTON_START))
	assert_bool(_menu.is_capturing()).is_false()
	assert_bool(_menu.is_open()).is_true()


func test_pendant_une_capture_b_ne_ferme_pas_le_menu() -> void:
	_gestionnaire._input(_touche(KEY_F1))
	_menu._start_binding("move_forward")
	_gestionnaire._input(_bouton(JOY_BUTTON_B))
	assert_bool(_menu.is_open()).is_true()


func test_une_touche_qui_se_repete_est_ignoree() -> void:
	var repetition := _touche(KEY_F1)
	repetition.echo = true
	_gestionnaire._input(repetition)
	assert_bool(_menu.is_open()).is_false()


func test_f1_marche_aussi_par_sa_position_sur_le_clavier() -> void:
	var physique := InputEventKey.new()
	physique.physical_keycode = KEY_F1
	physique.pressed = true
	_gestionnaire._input(physique)
	assert_bool(_menu.is_open()).is_true()


func test_une_touche_relachee_ne_fait_rien() -> void:
	var relachee := _touche(KEY_F1)
	relachee.pressed = false
	_gestionnaire._input(relachee)
	assert_bool(_menu.is_open()).is_false()
