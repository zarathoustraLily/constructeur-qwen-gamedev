extends GdUnitTestSuite
## La donnée de l'enchaînement : celle du jeu est juste, et le validateur refuse un premier écran inconnu, une scène
## introuvable et un identifiant vide.

const TEMOIN: String = "res://7_tests/2_sequence/jeu/ecran_temoin.tscn"


func test_la_donnee_du_jeu_est_juste() -> void:
	var sequence: SequenceDef = load("res://5_data/jeu/sequence.tres")
	assert_array(sequence.validate()).is_empty()


func test_un_premier_ecran_inconnu_est_refuse() -> void:
	var sequence := SequenceDef.new()
	sequence.first_screen = &"studio"
	assert_array(sequence.validate()).contains(["sequence : premier écran « studio » absent des écrans"])


func test_une_scene_introuvable_est_refusee() -> void:
	var sequence := SequenceDef.new()
	sequence.screens = {&"studio": "res://nulle_part.tscn"}
	assert_array(sequence.validate()).contains(["sequence : écran « studio », scène introuvable (res://nulle_part.tscn)"])


func test_un_identifiant_vide_est_refuse() -> void:
	var sequence := SequenceDef.new()
	sequence.id = &""
	assert_array(sequence.validate()).contains(["sequence : id vide"])


func test_un_enchainement_juste_passe() -> void:
	var sequence := SequenceDef.new()
	sequence.first_screen = &"temoin"
	sequence.screens = {&"temoin": TEMOIN}
	assert_array(sequence.validate()).is_empty()
