extends GdUnitTestSuite
## L'écran d'avertissement : une demande trop tôt est ignorée ; après le temps de lecture, la consigne se montre et
## une demande fait partir l'écran, qui finit une seule fois avec la suite ; sans rien faire, il passe seul. Dans la
## scène du jeu, le texte vient de la donnée, et le bouton A, pressé à temps, fait partir l'écran.

const SCENE: String = "res://2_sequence/jeu/disclaimer_screen.tscn"
const PAS: float = 0.1


func _donnee() -> DisclaimerDef:
	var disclaimer := DisclaimerDef.new()
	disclaimer.body = "Texte témoin."
	disclaimer.hint = "Continuer"
	disclaimer.fade_s = 0.5
	disclaimer.skip_after_s = 1.0
	disclaimer.auto_next_s = 5.0
	disclaimer.next_screen = &"suite"
	return disclaimer


func _ecran(disclaimer: DisclaimerDef) -> DisclaimerScreen:
	var ecran: DisclaimerScreen = auto_free(load(SCENE).instantiate())
	if disclaimer != null:
		ecran.disclaimer = disclaimer
	add_child(ecran)
	ecran.set_process(false)
	return ecran


func _avancer(ecran: DisclaimerScreen, secondes: float) -> void:
	var reste: float = secondes
	while reste > 0.0:
		ecran.advance(minf(PAS, reste))
		reste -= PAS


func _fins(ecran: DisclaimerScreen) -> Array[StringName]:
	var fins: Array[StringName] = []
	ecran.finished.connect(func(next: StringName) -> void: fins.append(next))
	return fins


func test_une_demande_trop_tot_est_ignoree() -> void:
	var ecran := _ecran(_donnee())
	_avancer(ecran, 0.5)
	ecran.request_skip()
	assert_int(ecran.phase).is_not_equal(DisclaimerScreen.Phase.FADE_OUT)
	var vue: DisclaimerView = ecran.get_node("View")
	assert_bool(vue.hint_shown()).is_false()


func test_apres_la_lecture_la_consigne_se_montre_et_l_ecran_part() -> void:
	var ecran := _ecran(_donnee())
	var fins := _fins(ecran)
	_avancer(ecran, 1.2)
	var vue: DisclaimerView = ecran.get_node("View")
	assert_bool(vue.hint_shown()).is_true()
	ecran.request_skip()
	assert_int(ecran.phase).is_equal(DisclaimerScreen.Phase.FADE_OUT)
	_avancer(ecran, 1.0)
	assert_array(fins).is_equal([&"suite"])


func test_sans_rien_faire_l_ecran_passe_seul() -> void:
	var ecran := _ecran(_donnee())
	var fins := _fins(ecran)
	_avancer(ecran, 4.5)
	assert_array(fins).is_empty()
	_avancer(ecran, 1.5)
	assert_array(fins).is_equal([&"suite"])


func test_dans_le_jeu_le_bouton_a_fait_partir_l_ecran() -> void:
#@ 3-3
	var ecran := _ecran(null)
#@ 4+
	var ecran: DisclaimerScreen = auto_free(load(SCENE).instantiate())
	var chargement := BackgroundLoader.new()
	ecran.setup(chargement)
	add_child(ecran)
	ecran.set_process(false)
#@ all
	var disclaimer: DisclaimerDef = load("res://5_data/jeu/avertissement.tres")
	var vue: DisclaimerView = ecran.get_node("View")
	assert_str(vue.shown_body()).is_equal(disclaimer.body)
	_avancer(ecran, disclaimer.skip_after_s + PAS)
#@ 4+
	chargement.release()
#@ all
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	get_viewport().push_input(event)
	assert_int(ecran.phase).is_equal(DisclaimerScreen.Phase.FADE_OUT)
#@ 4+


func test_on_ne_passe_pas_avant_que_le_suivant_soit_charge() -> void:
	var disclaimer := _donnee()
	disclaimer.preload_paths = ["res://2_sequence/jeu/menu_screen.tscn"]
	var ecran: DisclaimerScreen = auto_free(load(SCENE).instantiate())
	ecran.disclaimer = disclaimer
	var chargement := BackgroundLoader.new()
	ecran.setup(chargement)
	add_child(ecran)
	ecran.set_process(false)
	_avancer(ecran, disclaimer.skip_after_s + PAS)
	assert_bool(ecran.can_skip()).is_equal(chargement.is_done())
	chargement.release()
	assert_bool(ecran.can_skip()).is_true()
#@ all
