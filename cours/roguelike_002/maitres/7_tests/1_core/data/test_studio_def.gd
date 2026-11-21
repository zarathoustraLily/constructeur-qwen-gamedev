extends GdUnitTestSuite
## La donnée de l'écran du studio : celle du jeu est juste et charge les images du menu ; le validateur refuse un nom
## vide, une durée négative et une ressource introuvable.


func _juste() -> StudioDef:
	var studio := StudioDef.new()
	studio.studio_name = "Studio"
	return studio


func test_la_donnee_du_jeu_est_juste() -> void:
	var studio: StudioDef = load("res://5_data/jeu/studio.tres")
	assert_array(studio.validate()).is_empty()
#@ 2-3
	assert_array(studio.preload_paths).contains(["res://6_assets/jeu/menu/fond.png"])
#@ all


func test_une_donnee_juste_passe() -> void:
	assert_array(_juste().validate()).is_empty()


func test_un_nom_vide_est_refuse() -> void:
	var studio := _juste()
	studio.studio_name = "   "
	assert_array(studio.validate()).contains(["studio : nom de la boîte vide"])


func test_une_duree_negative_est_refusee() -> void:
	var studio := _juste()
	studio.min_hold_s = -1.0
	assert_array(studio.validate()).contains(["studio : durée négative"])


func test_une_ressource_introuvable_est_refusee() -> void:
	var studio := _juste()
	studio.preload_paths = ["res://nulle_part.png"]
	assert_array(studio.validate()).contains(["studio : ressource à charger introuvable (res://nulle_part.png)"])
#@ 3+


func test_l_ecran_du_studio_mene_a_l_avertissement() -> void:
	var studio: StudioDef = load("res://5_data/jeu/studio.tres")
	var sequence: SequenceDef = load("res://5_data/jeu/sequence.tres")
	assert_str(studio.next_screen).is_equal("avertissement")
	assert_bool(sequence.screens.has(studio.next_screen)).is_true()
	assert_array(studio.preload_paths).contains([sequence.screens[studio.next_screen]])
#@ all
