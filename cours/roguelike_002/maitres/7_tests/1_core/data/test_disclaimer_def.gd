extends GdUnitTestSuite
## La donnée de l'avertissement : celle du jeu est juste ; le validateur refuse un texte vide, une consigne vide, une
## durée négative, et un écran qui passerait seul avant qu'on puisse le passer.


func _juste() -> DisclaimerDef:
	var disclaimer := DisclaimerDef.new()
	disclaimer.body = "Texte."
	disclaimer.hint = "Continuer"
	return disclaimer


func test_la_donnee_du_jeu_est_juste() -> void:
	var disclaimer: DisclaimerDef = load("res://5_data/jeu/avertissement.tres")
	assert_array(disclaimer.validate()).is_empty()


func test_une_donnee_juste_passe() -> void:
	assert_array(_juste().validate()).is_empty()


func test_un_texte_vide_est_refuse() -> void:
	var disclaimer := _juste()
	disclaimer.body = ""
	assert_array(disclaimer.validate()).contains(["avertissement : texte vide"])


func test_une_consigne_vide_est_refusee() -> void:
	var disclaimer := _juste()
	disclaimer.hint = " "
	assert_array(disclaimer.validate()).contains(["avertissement : consigne vide"])


func test_une_duree_negative_est_refusee() -> void:
	var disclaimer := _juste()
	disclaimer.fade_s = -0.5
	assert_array(disclaimer.validate()).contains(["avertissement : durée négative"])


func test_passer_seul_avant_de_pouvoir_passer_est_refuse() -> void:
	var disclaimer := _juste()
	disclaimer.skip_after_s = 3.0
	disclaimer.auto_next_s = 2.0
	assert_array(disclaimer.validate()).contains(["avertissement : il passerait seul avant qu'on puisse le passer"])
#@ 4+


func test_l_avertissement_charge_le_menu_et_y_mene() -> void:
	var disclaimer: DisclaimerDef = load("res://5_data/jeu/avertissement.tres")
	var sequence: SequenceDef = load("res://5_data/jeu/sequence.tres")
	assert_str(disclaimer.next_screen).is_equal("menu")
	assert_array(disclaimer.preload_paths).contains([sequence.screens[disclaimer.next_screen]])
#@ all
