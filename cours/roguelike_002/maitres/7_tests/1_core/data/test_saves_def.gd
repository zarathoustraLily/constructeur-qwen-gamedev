extends GdUnitTestSuite
## La donnée des sauvegardes : celle du jeu est juste et mène du menu aux sauvegardes ; le validateur refuse aucun
## emplacement, un dossier hors de user://, un nom sans numéro et une action sans texte.


func _jeu() -> SavesDef:
	return load("res://5_data/jeu/sauvegardes.tres").duplicate()


func test_la_donnee_du_jeu_est_juste() -> void:
	assert_array(_jeu().validate()).is_empty()


func test_jouer_mene_aux_sauvegardes() -> void:
	var menu: MenuDef = load("res://5_data/jeu/menu.tres")
	var sequence: SequenceDef = load("res://5_data/jeu/sequence.tres")
	assert_str(menu.targets[&"jouer"]).is_equal("sauvegardes")
	assert_bool(sequence.screens.has(&"sauvegardes")).is_true()


func test_aucun_emplacement_est_refuse() -> void:
	var saves := _jeu()
	saves.slot_count = 0
	assert_array(saves.validate()).contains(["sauvegardes : aucun emplacement"])


func test_un_dossier_hors_de_user_est_refuse() -> void:
	var saves := _jeu()
	saves.directory = "res://sauvegardes"
	assert_array(saves.validate()).contains(["sauvegardes : le dossier doit être dans user://"])


func test_un_nom_sans_numero_est_refuse() -> void:
	var saves := _jeu()
	saves.file_pattern = "sauvegarde.json"
	assert_array(saves.validate()).contains(["sauvegardes : nom de fichier ou d'emplacement sans numéro (%d)"])


func test_une_action_sans_texte_est_refusee() -> void:
	var saves := _jeu()
	saves.action_labels.erase(&"effacer")
	assert_array(saves.validate()).contains(["sauvegardes : action « effacer » sans texte"])
