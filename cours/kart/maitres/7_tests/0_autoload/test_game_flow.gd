extends GdUnitTestSuite
## Règles du chef d'orchestre : l'ordre des étapes, le retour au début, les scènes hors séquence,
## et la séquence du jeu elle-même.

const TITRE := "res://2_sequence/menus/titre.tscn"
const INTRO := "res://2_sequence/cinematics/intro.tscn"
const NIVEAU := "res://2_sequence/levels/island/island.tscn"
const ETAPE_A := "res://7_tests/0_autoload/etape_a.tscn"
const ETAPE_B := "res://7_tests/0_autoload/etape_b.tscn"

var _sequence_du_jeu: Sequence
var _scene_du_test: Node
var _scene_d_avant: Node


func before_test() -> void:
	_sequence_du_jeu = GameFlow.sequence
	_scene_d_avant = get_tree().current_scene
	var sequence := Sequence.new()
	sequence.etapes = [TITRE, INTRO, NIVEAU]
	GameFlow.sequence = sequence


func after_test() -> void:
	GameFlow.sequence = _sequence_du_jeu
	var courante := get_tree().current_scene
	if courante and courante != _scene_d_avant:
		courante.free()
	get_tree().current_scene = _scene_d_avant
	if is_instance_valid(_scene_du_test):
		_scene_du_test.free()


## Deux vraies scènes d'étape, minuscules, pour les changements de scène.
func _sequence_reelle() -> void:
	var sequence := Sequence.new()
	sequence.etapes = [ETAPE_A, ETAPE_B]
	GameFlow.sequence = sequence


## Un changement de scène se termine à la fin de l'image en cours.
func _attendre_le_changement() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


## Fait comme si la scène `chemin` était l'étape en cours, sans la charger.
func _jouer(chemin: String) -> void:
	_scene_du_test = Node.new()
	_scene_du_test.scene_file_path = chemin
	get_tree().root.add_child(_scene_du_test)
	get_tree().current_scene = _scene_du_test


func test_les_etapes_s_enchainent_dans_l_ordre() -> void:
	assert_str(GameFlow.etape_apres(TITRE)).is_equal(INTRO)
	assert_str(GameFlow.etape_apres(INTRO)).is_equal(NIVEAU)


func test_apres_la_derniere_etape_on_revient_a_la_premiere() -> void:
	assert_str(GameFlow.etape_apres(NIVEAU)).is_equal(TITRE)


func test_une_scene_hors_sequence_mene_a_la_premiere_etape() -> void:
	assert_str(GameFlow.etape_apres("res://ailleurs.tscn")).is_equal(TITRE)


func test_l_etape_courante_est_le_rang_de_la_scene_jouee() -> void:
	_jouer(INTRO)
	assert_int(GameFlow.etape_courante()).is_equal(1)


func test_une_scene_hors_sequence_n_a_pas_de_rang() -> void:
	_jouer("res://ailleurs.tscn")
	assert_int(GameFlow.etape_courante()).is_equal(-1)


func test_sans_scene_courante_il_n_y_a_pas_de_rang() -> void:
	get_tree().current_scene = null
	assert_int(GameFlow.etape_courante()).is_equal(-1)


func test_etape_suivante_charge_la_scene_de_l_etape_d_apres() -> void:
	_sequence_reelle()
	_jouer(ETAPE_A)
	GameFlow.etape_suivante()
	await _attendre_le_changement()
	assert_str(get_tree().current_scene.scene_file_path).is_equal(ETAPE_B)


func test_apres_la_derniere_etape_le_jeu_recharge_la_premiere() -> void:
	_sequence_reelle()
	_jouer(ETAPE_B)
	GameFlow.etape_suivante()
	await _attendre_le_changement()
	assert_str(get_tree().current_scene.scene_file_path).is_equal(ETAPE_A)


func test_une_sequence_vide_ne_change_pas_de_scene() -> void:
	GameFlow.sequence = Sequence.new()
	_jouer(ETAPE_A)
	GameFlow.etape_suivante()
	await _attendre_le_changement()
	assert_object(get_tree().current_scene).is_same(_scene_du_test)


func test_recommencer_relance_l_etape_en_cours() -> void:
	_sequence_reelle()
	_jouer(ETAPE_A)
	var avant := get_tree().current_scene.get_instance_id()
	GameFlow.recommencer()
	await _attendre_le_changement()
	assert_int(get_tree().current_scene.get_instance_id()).is_not_equal(avant)
	assert_str(get_tree().current_scene.scene_file_path).is_equal(ETAPE_A)


func test_chaque_etape_du_jeu_existe() -> void:
	assert_array(_sequence_du_jeu.etapes).is_not_empty()
	for chemin in _sequence_du_jeu.etapes:
		assert_bool(ResourceLoader.exists(chemin)).override_failure_message("étape absente : " + chemin).is_true()


func test_le_jeu_demarre_sur_la_premiere_etape() -> void:
	var depart: String = ProjectSettings.get_setting("application/run/main_scene")
	if depart.begins_with("uid://"):
		depart = ResourceUID.get_id_path(ResourceUID.text_to_id(depart))
	assert_str(depart).is_equal(_sequence_du_jeu.etapes[0])


## Joue pour de vrai la scène d'étape `chemin`, comme si le jeu venait de la charger.
func _jouer_l_etape(chemin: String) -> Step:
	var etape: Step = load(chemin).instantiate()
	get_tree().root.add_child(etape)
	get_tree().current_scene = etape
	GameFlow._ecouter_etape()
	return etape


func test_une_etape_terminee_mene_a_la_suivante() -> void:
	_sequence_reelle()
	_jouer_l_etape(ETAPE_A).terminer()
	await _attendre_le_changement()
	assert_str(get_tree().current_scene.scene_file_path).is_equal(ETAPE_B)


func test_l_etape_chargee_ensuite_est_ecoutee_a_son_tour() -> void:
	_sequence_reelle()
	_jouer_l_etape(ETAPE_A).terminer()
	await _attendre_le_changement()
	(get_tree().current_scene as Step).terminer()
	await _attendre_le_changement()
	assert_str(get_tree().current_scene.scene_file_path).is_equal(ETAPE_A)


func test_une_etape_qui_demande_a_rejouer_est_relancee() -> void:
	_sequence_reelle()
	var etape := _jouer_l_etape(ETAPE_A)
	var avant := etape.get_instance_id()
	etape.rejouer()
	await _attendre_le_changement()
	assert_int(get_tree().current_scene.get_instance_id()).is_not_equal(avant)
	assert_str(get_tree().current_scene.scene_file_path).is_equal(ETAPE_A)


func test_une_etape_n_est_ecoutee_qu_une_fois() -> void:
	var etape := _jouer_l_etape(ETAPE_A)
	GameFlow._ecouter_etape()
	assert_int(etape.terminee.get_connections().size()).is_equal(1)
	assert_int(etape.a_rejouer.get_connections().size()).is_equal(1)


func test_chaque_etape_du_jeu_respecte_le_contrat_step() -> void:
	for chemin in _sequence_du_jeu.etapes:
		var racine: Node = load(chemin).instantiate()
		assert_bool(racine is Step).override_failure_message(chemin + " : la racine n'est pas une Step").is_true()
		racine.free()
