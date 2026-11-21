extends GdUnitTestSuite
## Les réglages du joueur : par défaut d'après la donnée ; enregistrés puis relus à l'identique ; un fichier absent
## donne les valeurs par défaut ; une valeur inconnue ou hors bornes, écrite à la main, est corrigée.

const FICHIER: String = "user://test_reglages.cfg"


func after_test() -> void:
	if FileAccess.file_exists(FICHIER):
		DirAccess.remove_absolute(FICHIER)


func _options() -> OptionsDef:
	var options: OptionsDef = load("res://5_data/jeu/options.tres").duplicate()
	options.file_path = FICHIER
	return options


func test_par_defaut_d_apres_la_donnee() -> void:
	var options := _options()
	var settings := GameSettings.defaults(options)
	assert_str(settings.difficulty).is_equal(options.default_difficulty)
	assert_that(settings.resolution).is_equal(options.default_resolution)
	assert_float(settings.volumes[&"Musique"]).is_equal(options.default_volume)


func test_enregistres_puis_relus_a_l_identique() -> void:
	var options := _options()
	var settings := GameSettings.defaults(options)
	settings.difficulty = &"difficile"
	settings.resolution = Vector2i(1280, 720)
	settings.fullscreen = true
	settings.volumes[&"Effets"] = 0.3
	assert_int(settings.save_to(options)).is_equal(OK)
	var relus := GameSettings.load_from(options)
	assert_str(relus.difficulty).is_equal("difficile")
	assert_that(relus.resolution).is_equal(Vector2i(1280, 720))
	assert_bool(relus.fullscreen).is_true()
	assert_float(relus.volumes[&"Effets"]).is_equal_approx(0.3, 0.0001)


func test_un_fichier_absent_donne_les_valeurs_par_defaut() -> void:
	var options := _options()
	var relus := GameSettings.load_from(options)
	assert_str(relus.difficulty).is_equal(options.default_difficulty)


func test_une_valeur_ecrite_a_la_main_est_corrigee() -> void:
	var options := _options()
	var file := ConfigFile.new()
	file.set_value("jeu", "difficulte", &"impossible")
	file.set_value("ecran", "definition", Vector2i(123, 456))
	file.set_value("son", "Musique", 4.0)
	file.save(FICHIER)
	var relus := GameSettings.load_from(options)
	assert_str(relus.difficulty).is_equal(options.default_difficulty)
	assert_that(relus.resolution).is_equal(options.default_resolution)
	assert_float(relus.volumes[&"Musique"]).is_equal(1.0)
