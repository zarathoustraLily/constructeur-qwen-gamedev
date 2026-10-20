extends GdUnitTestSuite
## Règles de la scène principale : elle montre à chaque image les commandes que l'adaptateur a lues, et la
## vibration du saut est réglée.

const MAIN := preload("res://2_sequence/main.tscn")


func after_test() -> void:
	Input.action_release("move_forward")


func test_la_scene_montre_les_commandes_lues() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	Input.action_press("move_forward")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_float((main.get_node("InputDisplay/Panel/Rows/Throttle") as ProgressBar).value).is_equal_approx(1.0, 0.001)


func test_la_vibration_du_saut_est_reglee() -> void:
	var main: Node3D = auto_free(MAIN.instantiate())
	var rumble: Rumble = main.get("jump_rumble")
	assert_object(rumble).is_not_null()
	assert_float(rumble.duration).is_greater(0.0)
	assert_float(maxf(rumble.weak_magnitude, rumble.strong_magnitude)).is_greater(0.0)
