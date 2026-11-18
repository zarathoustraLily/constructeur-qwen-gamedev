extends GdUnitTestSuite
## Les réglages se lisent du fichier du projet sans erreur ; un JSON invalide, une catégorie inconnue, un dossier
## manquant ou un fichier absent sont dits dans `errors`, et le reste du fichier est lu quand même.
#@ 2+
## Les pixels par mètre se lisent ; une valeur négative est refusée et remplacée par celle par défaut.
#@ 3+
## La vue du jeu se lit ; une inclinaison hors de ]0, 90] est refusée.
#@ all


func test_les_reglages_du_projet_se_lisent_sans_erreur() -> void:
	var config: ViewerConfig = ViewerConfig.load_file("res://5_data/visualiseur/config.json")
	assert_array(config.errors).is_empty()
	assert_int(config.sources.size()).is_equal(4)
	assert_str(config.sources[1].folder).is_equal("res://6_assets/exemple/ennemis")
	assert_str(config.sources[1].category).is_equal("ennemi")


func test_un_json_invalide_est_signale_avec_sa_ligne() -> void:
	var config: ViewerConfig = ViewerConfig.parse("{\n\"sources\": [\n}")
	assert_int(config.errors.size()).is_equal(1)
	assert_str(config.errors[0]).starts_with("JSON invalide, ligne 3")


func test_une_categorie_inconnue_est_signalee_et_les_autres_sources_restent() -> void:
	var config: ViewerConfig = ViewerConfig.parse(
			"{\"sources\": [{\"dossier\": \"a\", \"categorie\": \"monstre\"}, {\"dossier\": \"b\", \"categorie\": \"boss\"},"
			+ " {\"categorie\": \"prop\"}]}")
	assert_int(config.sources.size()).is_equal(1)
	assert_str(config.sources[0].folder).is_equal("b")
	assert_array(config.errors).is_equal([
			"source 1 : catégorie « monstre » inconnue (attendu : heros, ennemi, boss, prop, effet)",
			"source 3 : « dossier » manque"])


func test_un_fichier_absent_est_une_erreur() -> void:
	var config: ViewerConfig = ViewerConfig.load_file("res://5_data/visualiseur/absent.json")
	assert_array(config.errors).is_equal(["réglages introuvables : res://5_data/visualiseur/absent.json"])
	assert_array(config.sources).is_empty()
#@ 2+


func test_les_pixels_par_metre_se_lisent() -> void:
	assert_float(ViewerConfig.parse("{\"pixels_par_metre\": 128}").pixels_per_meter).is_equal(128.0)
	var config: ViewerConfig = ViewerConfig.parse("{\"pixels_par_metre\": -4}")
	assert_float(config.pixels_per_meter).is_equal(ViewerConfig.DEFAULT_PIXELS_PER_METER)
	assert_array(config.errors).is_equal(["« pixels_par_metre » doit être plus grand que 0"])
#@ 3+


func test_la_vue_du_jeu_se_lit() -> void:
	var config: ViewerConfig = ViewerConfig.load_file("res://5_data/visualiseur/config.json")
	assert_float(config.game_pitch_deg).is_equal(30.0)
	assert_float(config.game_yaw_deg).is_equal(45.0)
	assert_float(config.game_ortho_size).is_equal(8.0)


func test_une_inclinaison_hors_bornes_est_refusee() -> void:
	var config: ViewerConfig = ViewerConfig.parse("{\"vue_jeu\": {\"inclinaison\": 120}}")
	assert_float(config.game_pitch_deg).is_equal(30.0)
	assert_array(config.errors).is_equal(["« vue_jeu.inclinaison » doit être entre 0 (exclu) et 90 degrés"])
#@ all
