extends GdUnitTestSuite
## Règles de la scène principale : elle montre à chaque image les commandes que l'adaptateur a lues ; la flèche
## de visée suit la marche quand on ne vise pas, tournée comme la caméra ; la vibration du coup est réglée.

const MAIN := preload("res://2_sequence/main.tscn")


func after_test() -> void:
	Input.action_release("move_right")


## Trois images : le signal physics_frame part avant que les nœuds ne jouent leur image ; à la troisième, la
## lecture des commandes, puis leur affichage, ont eu lieu.
func _frames() -> void:
	for _frame: int in 3:
		await get_tree().physics_frame


func test_la_scene_montre_les_commandes_lues() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	Input.action_press("move_right")
	await _frames()
	assert_float((main.get_node("InputDisplay/Panel/Rows/MoveX") as ProgressBar).value).is_equal_approx(1.0, 0.001)


func test_sans_visee_la_fleche_suit_la_marche_tournee_comme_la_camera() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	# Un bouton de manette : la visée passe au stick droit, au repos ; la flèche suit alors la marche.
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_X
	button.pressed = true
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	Input.action_press("move_right")
	await _frames()
	var camera := main.get_node("Hero/CameraRoot/Camera3D") as Camera3D
	var expected := Vector3.RIGHT.rotated(Vector3.UP, camera.global_rotation.y)
	var pivot := main.get_node("Hero/AimPivot") as Node3D
	assert_bool(pivot.visible).is_true()
	assert_vector(-pivot.global_basis.z).is_equal_approx(expected, Vector3.ONE * 0.01)


func test_la_vibration_du_coup_est_reglee() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	var rumble: Rumble = main.get("attack_rumble")
	assert_object(rumble).is_not_null()
	assert_float(rumble.duration).is_greater(0.0)
	assert_float(maxf(rumble.weak_magnitude, rumble.strong_magnitude)).is_greater(0.0)
