extends GdUnitTestSuite
## Non-régression de la partie complète (2_sequence/main.tscn) : avec une conduite scriptée
## (avancer dès l'image 30, tourner à gauche de l'image 120 à 200), le kart passe aux mêmes
## positions que dans le projet d'origine (conduite_attendue.json), à 1 cm près.
## La physique n'est reproductible qu'à cadence fixe : 7_tests/lancer_tests.bat lance Godot avec
## --fixed-fps 60 et le signale par l'argument « ++ cadence_fixe ». Sans ce signal (panneau GdUnit4
## de l'éditeur, par exemple), la suite est mise de côté ; si le signal ment, le test échoue.

const ATTENDU := "res://7_tests/2_sequence/conduite_attendue.json"
const IMAGES := 300
const TOLERANCE := 0.01
const ACTIONS := ["move_forward", "move_left"]


func before(_do_skip := not OS.get_cmdline_user_args().has("cadence_fixe"),
		_skip_reason := "cadence fixe exigée : lancer 7_tests/lancer_tests.bat") -> void:
	pass


func after_test() -> void:
	for action: String in ACTIONS:
		Input.action_release(action)


func _kart(partie: Node) -> Kart:
	for joueur in get_tree().get_nodes_in_group("player"):
		if partie.is_ancestor_of(joueur):
			return joueur.find_children("*", "Kart", true, false)[0]
	return null


func test_le_kart_suit_la_trajectoire_d_origine() -> void:
	var attendu: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ATTENDU))
	var partie: Node = auto_free(load(ProjectSettings.get_setting("application/run/main_scene")).instantiate())
	add_child(partie)
	var kart := _kart(partie)
	assert_object(kart).is_not_null()
	var images_affichees := Engine.get_process_frames()
	var positions := {}
	for image in range(1, IMAGES + 1):
		await get_tree().physics_frame
		if image == 30:
			Input.action_press("move_forward")
		elif image == 120:
			Input.action_press("move_left")
		elif image == 200:
			Input.action_release("move_left")
		if attendu.has(str(image)):
			positions[str(image)] = kart.global_position
	images_affichees = Engine.get_process_frames() - images_affichees
	assert_int(images_affichees).override_failure_message(
		"cadence non fixe (%d images pour %d pas de physique) : lancer avec --fixed-fps 60" % [images_affichees, IMAGES]
	).is_between(IMAGES - 1, IMAGES + 1)
	for image: String in attendu:
		var voulu: Array = attendu[image]
		assert_vector(positions[image]).override_failure_message(
			"image %s : kart en %s, attendu %s" % [image, positions[image], voulu]
		).is_equal_approx(Vector3(voulu[0], voulu[1], voulu[2]), Vector3.ONE * TOLERANCE)
