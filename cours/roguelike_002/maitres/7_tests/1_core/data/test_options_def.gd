extends GdUnitTestSuite
## La donnée des options : celle du jeu est juste et ses lignes vont de la difficulté au retour ; le validateur refuse
## un fichier hors de user://, une difficulté ou une définition par défaut absente, un pas de volume nul et une ligne
## sans texte.


func _jeu() -> OptionsDef:
	return load("res://5_data/jeu/options.tres").duplicate()


func test_la_donnee_du_jeu_est_juste() -> void:
	assert_array(_jeu().validate()).is_empty()


func test_les_lignes_vont_de_la_difficulte_au_retour() -> void:
	var rows: Array[StringName] = _jeu().rows()
	assert_str(rows[0]).is_equal("difficulte")
	assert_str(rows[rows.size() - 1]).is_equal("retour")
	assert_array(rows).contains([&"Musique", &"Effets"])


func test_un_fichier_hors_de_user_est_refuse() -> void:
	var options := _jeu()
	options.file_path = "res://options.cfg"
	assert_array(options.validate()).contains(["options : le fichier doit être dans user://"])


func test_une_difficulte_par_defaut_absente_est_refusee() -> void:
	var options := _jeu()
	options.default_difficulty = &"impossible"
	assert_array(options.validate()).contains(["options : difficulté par défaut absente des difficultés"])


func test_une_definition_par_defaut_absente_est_refusee() -> void:
	var options := _jeu()
	options.default_resolution = Vector2i(800, 600)
	assert_array(options.validate()).contains(["options : définition par défaut absente des définitions"])


func test_un_pas_de_volume_nul_est_refuse() -> void:
	var options := _jeu()
	options.volume_step = 0.0
	assert_array(options.validate()).contains(["options : pas de volume hors de ]0, 1]"])


func test_une_ligne_sans_texte_est_refusee() -> void:
	var options := _jeu()
	options.row_labels.erase(&"retour")
	assert_array(options.validate()).contains(["options : ligne « retour » sans texte"])
