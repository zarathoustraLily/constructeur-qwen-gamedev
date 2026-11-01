extends GdUnitTestSuite
## Règles de l'écran du barrage : il pose l'eau contre le mur de gauche, il montre une image à sa taille, et chaque image de physique
## fait avancer l'eau et la redessine.

const SCENE := preload("res://2_sequence/flip_tank.tscn")


func _tank() -> Control:
	var tank: Control = auto_free(SCENE.instantiate())
	add_child(tank)
	return tank


func test_l_eau_part_contre_le_mur_de_gauche() -> void:
	var tank: Control = _tank()
	var solver: FlipSolver = tank.get("_solver")
	var settings: FlipSettings = tank.get("settings")
	assert_int(solver.positions.size()).is_greater(100)
	for place: Vector2 in solver.positions:
		assert_float(place.x).is_less_equal(settings.width * 0.4)


func test_elle_montre_une_image_a_sa_taille() -> void:
	var tank: Control = _tank()
	var settings: FlipSettings = tank.get("settings")
	var vue: TextureRect = tank.get_node("View") as TextureRect
	assert_int(vue.texture.get_width()).is_equal(settings.width * 4)
	assert_int(vue.texture.get_height()).is_equal(settings.height * 4)


func test_l_eau_avance_et_se_dessine() -> void:
	var tank: Control = _tank()
	var solver: FlipSolver = tank.get("_solver")
	var avant: Vector2 = solver.positions[0]
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(solver.positions[0].is_equal_approx(avant)).is_false()
	var image: Image = tank.get("_image")
	var pixel: Vector2i = Vector2i(((solver.positions[0] + Vector2(0.5, 0.5)) * 4.0).floor())
	assert_float(image.get_pixelv(pixel).b).is_greater(0.0)
