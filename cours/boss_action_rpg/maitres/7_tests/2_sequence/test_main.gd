extends GdUnitTestSuite
## Règles de la scène principale : elle se charge ; elle a un sol avec sa collision, une lumière qui fait des ombres,
## un ciel, et sa caméra est la caméra active.

const MAIN := preload("res://2_sequence/main.tscn")


func _main() -> Node3D:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	return main


func test_un_sol_avec_sa_collision() -> void:
	var main: Node3D = _main()
	var floor_body: StaticBody3D = main.get_node("Floor") as StaticBody3D
	assert_object(floor_body).is_not_null()
	assert_object((floor_body.get_node("Shape") as CollisionShape3D).shape).is_not_null()


func test_une_lumiere_qui_fait_des_ombres_et_un_ciel() -> void:
	var main: Node3D = _main()
	assert_bool((main.get_node("Sun") as DirectionalLight3D).shadow_enabled).is_true()
	assert_int((main.get_node("World") as WorldEnvironment).environment.background_mode).is_equal(Environment.BG_SKY)


func test_sa_camera_est_active() -> void:
	var main: Node3D = _main()
	assert_that(main.get_viewport().get_camera_3d()).is_same(main.get_node("Camera"))
