extends GdUnitTestSuite
## Scène principale, HUD, caméra et file de sons.


func after_test() -> void:
	for action in ["camera_left", "camera_right", "camera_up", "camera_down", "zoom_in", "zoom_out"]:
		Input.action_release(action)


func _main() -> Node3D:
	var main: Node3D = auto_free(load("res://scenes/main.tscn").instantiate())
	add_child(main)
	return main


func test_hud_affiche_les_pieces_du_joueur() -> void:
	var main := _main()
	main.get_node("Player").collect_coin()
	main.get_node("Player").collect_coin()
	assert_str(main.get_node("HUD/Coins").text).is_equal("2")


func test_connexions_de_la_scene() -> void:
	var main := _main()
	var joueur: Node = main.get_node("Player")
	assert_bool(joueur.coin_collected.is_connected(main.get_node("HUD")._on_coin_collected)).is_true()
	assert_object(joueur.view).is_same(main.get_node("View"))
	assert_object(main.get_node("View").target).is_same(joueur)


func test_joueur_pose_sur_le_sol() -> void:
	var runner := scene_runner("res://scenes/main.tscn")
	await runner.simulate_frames(30)
	var joueur: CharacterBody3D = runner.scene().get_node("Player")
	assert_bool(joueur.is_on_floor()).is_true()
	assert_float(joueur.position.y).is_between(0.0, 1.0)


func test_camera_suit_le_joueur() -> void:
	var main := _main()
	var vue: Node3D = main.get_node("View")
	main.get_node("Player").position = Vector3(4, 0, 0)
	vue._physics_process(0.1)
	assert_float(vue.position.x).is_equal_approx(1.6, 0.0001)


func test_zoom_borne() -> void:
	var main := _main()
	var vue: Node3D = main.get_node("View")
	Input.action_press("zoom_out")
	for i in 30:
		vue.handle_input(0.1)
	assert_float(float(vue.zoom)).is_equal(16.0)
	Input.action_release("zoom_out")
	Input.action_press("zoom_in")
	for i in 30:
		vue.handle_input(0.1)
	assert_float(float(vue.zoom)).is_equal(4.0)


func test_inclinaison_de_camera_bornee() -> void:
	var main := _main()
	var vue: Node3D = main.get_node("View")
	Input.action_press("camera_down")
	for i in 30:
		vue.handle_input(0.1)
	assert_float(vue.camera_rotation.x).is_equal(-10.0)
	Input.action_release("camera_down")
	Input.action_press("camera_up")
	for i in 30:
		vue.handle_input(0.1)
	assert_float(vue.camera_rotation.x).is_equal(-80.0)


func test_rotation_de_camera() -> void:
	var main := _main()
	var vue: Node3D = main.get_node("View")
	var y0: float = vue.camera_rotation.y
	Input.action_press("camera_right")
	vue.handle_input(0.5)
	assert_float(vue.camera_rotation.y - y0).is_equal_approx(60.0, 0.001)


func test_file_de_sons() -> void:
	var audio: Node = get_tree().root.get_node("Audio")
	var libres: int = audio.available.size()
	assert_int(libres).is_greater(0)
	audio.play("res://sounds/coin.ogg")
	assert_array(audio.queue).contains(["res://sounds/coin.ogg"])
	audio._process(0.0)
	assert_array(audio.queue).is_empty()
	assert_int(audio.available.size()).is_equal(libres - 1)
