extends GdUnitTestSuite
## La course : le véhicule roule sur la piste, la caméra le suit.


func after_test() -> void:
	for action in ["left", "right", "forward", "back"]:
		Input.action_release(action)


func test_vehicule_avance_en_accelerant() -> void:
	var runner := scene_runner("res://scenes/main.tscn")
	await runner.simulate_frames(20)
	var v: Vehicle = runner.scene().get_node("Vehicle")
	var depart: Vector3 = v.sphere.global_position
	Input.action_press("forward")
	await runner.simulate_frames(90)
	assert_float(v.linear_speed).is_greater(0.5)
	assert_float(v.sphere.global_position.distance_to(depart)).is_greater(1.0)


func test_vehicule_freine_en_marche_arriere() -> void:
	var runner := scene_runner("res://scenes/main.tscn")
	await runner.simulate_frames(20)
	var v: Vehicle = runner.scene().get_node("Vehicle")
	Input.action_press("back")
	await runner.simulate_frames(60)
	assert_float(v.linear_speed).is_less(0.0)


func test_vehicule_pose_sur_la_piste() -> void:
	var runner := scene_runner("res://scenes/main.tscn")
	await runner.simulate_frames(30)
	var v: Vehicle = runner.scene().get_node("Vehicle")
	assert_bool(v.raycast.is_colliding()).is_true()


func test_camera_suit_le_vehicule() -> void:
	var main: Node3D = auto_free(load("res://scenes/main.tscn").instantiate())
	add_child(main)
	var vue: Node3D = main.get_node("View")
	var v: Vehicle = main.get_node("Vehicle")
	vue.position = Vector3.ZERO
	v.vehicle_model.global_position = Vector3(10, 0, 0)
	vue._physics_process(0.1)
	assert_float(vue.position.x).is_equal_approx(4.0, 0.0001)


func test_camera_recule_avec_la_vitesse() -> void:
	var main: Node3D = auto_free(load("res://scenes/main.tscn").instantiate())
	add_child(main)
	var vue: Node3D = main.get_node("View")
	var v: Vehicle = main.get_node("Vehicle")
	vue.camera.position.z = 10.0
	v.linear_speed = 1.0
	vue._physics_process(1.0)
	# Cible 20 ; lerp de 10 vers 20 à 0.5 → 15.
	assert_float(vue.camera.position.z).is_equal_approx(15.0, 0.0001)


func test_vue_cible_le_vehicule() -> void:
	var main: Node3D = auto_free(load("res://scenes/main.tscn").instantiate())
	add_child(main)
	assert_object(main.get_node("View").target).is_same(main.get_node("Vehicle"))
