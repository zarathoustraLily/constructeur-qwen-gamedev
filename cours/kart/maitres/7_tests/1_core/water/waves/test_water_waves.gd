extends GdUnitTestSuite
## Règles de la simulation de vagues : à chaque pas, elle garde les impulsions les plus fortes (hauteur ×
## rayon), au plus MAX_POINTS_PER_FRAME, converties en pixels de sa texture centrée sur le joueur, puis vide
## l'attente ; hors de sa texture, la hauteur vaut 0 ; sans fenêtre (pas de RenderingDevice), rien n'est
## calculé et l'eau reste à 0.

var _waves: WaterWaves


func before_test() -> void:
	_waves = auto_free(WaterWaves.new())
	_waves.texture_resolution = Vector2i(512, 512)
	_waves.texture_size = Vector2(64.0, 64.0)
	add_child(_waves)


func test_le_centre_de_la_texture_tombe_au_milieu() -> void:
	_waves.add_ripple(Vector3.ZERO, 1.0, 4.0)
	var points := _waves.take_frame_points()
	assert_that(points[0]).is_equal(Vector4(256.0, 256.0, 1.0, 4.0))


func test_un_metre_vaut_huit_pixels() -> void:
	_waves.add_ripple(Vector3(2.0, 0.0, -1.0), 1.0, 4.0)
	var point := _waves.take_frame_points()[0]
	assert_float(point.x).is_equal(272.0)
	assert_float(point.y).is_equal(248.0)


func test_seules_les_plus_fortes_impulsions_passent() -> void:
	for strength: int in 6:
		_waves.add_ripple(Vector3(strength, 0.0, 0.0), float(strength + 1), 1.0)
	var points := _waves.take_frame_points()
	assert_int(points.size()).is_equal(WaterWaves.MAX_POINTS_PER_FRAME)
	assert_float(points[0].z).is_equal(6.0)
	assert_float(points[3].z).is_equal(3.0)


func test_l_attente_est_videe_a_chaque_pas() -> void:
	_waves.add_ripple(Vector3.ZERO, 1.0, 4.0)
	_waves.take_frame_points()
	assert_int(_waves.take_frame_points().size()).is_equal(0)


func test_hors_de_la_texture_la_hauteur_vaut_zero() -> void:
	assert_float(_waves.get_height(Vector3(100.0, 0.0, 0.0))).is_equal(0.0)


func test_sans_rendering_device_l_eau_reste_a_zero() -> void:
	for _frame: int in 5:
		_waves.add_ripple(Vector3.ZERO, 1.0, 8.0)
		await get_tree().physics_frame
	assert_object(RenderingServer.get_rendering_device()).is_null()
	assert_float(_waves.get_height(Vector3.ZERO)).is_equal(0.0)
