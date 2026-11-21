extends GdUnitTestSuite
## La donnée du menu : celle du jeu est juste, sa durée d'entrée est celle du dernier arrivé ; le validateur refuse un
## choix sans texte, un choix de sortie absent, une planète immobile et un choix mis en avant qui rapetisse.


func _juste() -> MenuDef:
	var menu := MenuDef.new()
	menu.game_title = "Titre"
	menu.items = [&"jouer", &"quitter"]
	menu.labels = {&"jouer": "Jouer", &"quitter": "Quitter"}
	menu.quit_item = &"quitter"
	menu.planet_period_s = 1.0
	return menu


func test_la_donnee_du_jeu_est_juste() -> void:
	var menu: MenuDef = load("res://5_data/jeu/menu.tres")
	assert_array(menu.validate()).is_empty()


func test_l_entree_dure_jusqu_au_dernier_arrive() -> void:
	var menu := _juste()
	menu.title_delay_s = 0.2
	menu.title_in_s = 0.5
	menu.items_delay_s = 0.4
	menu.item_stagger_s = 0.25
	menu.item_in_s = 0.5
	assert_float(menu.intro_s()).is_equal_approx(1.15, 0.0001)
	menu.title_in_s = 2.0
	assert_float(menu.intro_s()).is_equal_approx(2.2, 0.0001)


func test_une_donnee_juste_passe() -> void:
	assert_array(_juste().validate()).is_empty()


func test_un_choix_sans_texte_est_refuse() -> void:
	var menu := _juste()
	menu.labels.erase(&"jouer")
	assert_array(menu.validate()).contains(["menu : choix « jouer » sans texte"])


func test_un_choix_de_sortie_absent_est_refuse() -> void:
	var menu := _juste()
	menu.quit_item = &"sortir"
	assert_array(menu.validate()).contains(["menu : le choix qui quitte (« sortir ») n'est pas dans les choix"])


func test_une_planete_immobile_est_refusee() -> void:
	var menu := _juste()
	menu.planet_period_s = 0.0
	assert_array(menu.validate()).contains(["menu : période de la planète nulle"])


func test_un_choix_qui_rapetisse_est_refuse() -> void:
	var menu := _juste()
	menu.focus_scale = 0.9
	assert_array(menu.validate()).contains(["menu : un choix mis en avant ne rapetisse pas"])
#@ 5+


func test_options_mene_a_l_ecran_des_options() -> void:
	var menu: MenuDef = load("res://5_data/jeu/menu.tres")
	var sequence: SequenceDef = load("res://5_data/jeu/sequence.tres")
	assert_str(menu.targets[&"options"]).is_equal("options")
	assert_bool(sequence.screens.has(&"options")).is_true()
#@ all
