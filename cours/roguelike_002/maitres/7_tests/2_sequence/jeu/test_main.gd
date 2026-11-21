extends GdUnitTestSuite
## La coquille : elle ouvre le premier écran, passe à celui qu'un écran nomme en finissant, libère l'ancien, et ne
## quitte pas l'écran ouvert quand on lui en demande un qui n'existe pas. La scène du jeu s'ouvre sans erreur.

const TEMOIN: String = "res://7_tests/2_sequence/jeu/ecran_temoin.tscn"
#@ 5+
const FICHIER: String = "user://test_main_options.cfg"


func after_test() -> void:
	if FileAccess.file_exists(FICHIER):
		DirAccess.remove_absolute(FICHIER)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Musique"), 1.0)
#@ all


func _coquille() -> Main:
	var sequence := SequenceDef.new()
	sequence.first_screen = &"premier"
	sequence.screens = {&"premier": TEMOIN, &"second": TEMOIN}
	var main := Main.new()
	main.sequence = sequence
	add_child(main)
	auto_free(main)
	return main


func test_le_premier_ecran_s_ouvre() -> void:
	var main := _coquille()
	assert_str(main.current_name).is_equal("premier")
	assert_object(main.current_screen()).is_not_null()


func test_un_ecran_fini_ouvre_celui_qu_il_nomme() -> void:
	var main := _coquille()
	var premier: Node = main.current_screen()
	main.current_screen().call(&"finish", &"second")
	assert_str(main.current_name).is_equal("second")
	assert_object(main.current_screen()).is_not_same(premier)
	assert_bool(premier.is_queued_for_deletion()).is_true()


func test_un_ecran_inconnu_laisse_l_ecran_ouvert() -> void:
	var main := _coquille()
	var premier: Node = main.current_screen()
	var manquants: Array[StringName] = []
	main.screen_missing.connect(func(screen: StringName) -> void: manquants.append(screen))
	main.show_screen(&"ailleurs")
	assert_array(manquants).is_equal([&"ailleurs"])
	assert_object(main.current_screen()).is_same(premier)


func test_la_scene_du_jeu_s_ouvre() -> void:
	var main: Main = auto_free(load("res://2_sequence/jeu/main.tscn").instantiate())
	add_child(main)
	assert_object(main.sequence).is_not_null()
	assert_object(main.rng()).is_not_null()
#@ 2+
	assert_str(main.current_name).is_equal("studio")


func test_un_ecran_qui_ne_nomme_rien_arrete_l_enchainement() -> void:
	var main := _coquille()
	var premier: Node = main.current_screen()
	main.current_screen().call(&"finish", &"")
	assert_object(main.current_screen()).is_same(premier)
#@ all
#@ 5+


func test_les_reglages_enregistres_s_appliquent_a_l_ouverture() -> void:
	var options: OptionsDef = load("res://5_data/jeu/options.tres").duplicate()
	options.file_path = FICHIER
	var reglages := GameSettings.defaults(options)
	reglages.volumes[&"Musique"] = 0.4
	reglages.save_to(options)
	var sequence := SequenceDef.new()
	var main := Main.new()
	main.sequence = sequence
	main.options = options
	add_child(main)
	auto_free(main)
	assert_float(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(&"Musique"))).is_equal_approx(0.4, 0.001)
#@ all
