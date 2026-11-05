extends GdUnitTestSuite
## La projection de la caméra du jeu : le calcul et la `Camera3D` de Godot tombent au même pixel ; la profondeur du sol
## est écrasée de sin(30°) = 0,5, une hauteur se voit à cos(30°) ; écran et sol se convertissent dans les deux sens ; le
## zoom garde le point du sol sous le curseur ; cadrer montre la salle entière ; déplacer fait suivre le sol à la souris.

const VIEW: Vector2 = Vector2(800, 600)

var _camera_def: CameraDef
var _transform: CameraTransform


func before_test() -> void:
	_camera_def = ResourceLoader.load("res://5_data/camera/camera.tres") as CameraDef
	_transform = CameraTransform.new()
	_transform.setup(ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef, _camera_def)
	_transform.frame(Vector2(24, 20), VIEW)


func test_la_camera_est_inclinee_de_30_degres() -> void:
	assert_float(_camera_def.pitch_deg).is_equal(30.0)
	assert_array(_camera_def.validate()).is_empty()


func test_le_calcul_et_godot_tombent_au_meme_pixel() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(VIEW)
	add_child(viewport)
	var camera: Camera3D = Camera3D.new()
	viewport.add_child(camera)
	camera.current = true
	_transform.apply_to(camera)
	for point: Vector3 in [Vector3.ZERO, Vector3(24, 0, 20), Vector3(5, 3, 7), Vector3(12, 0, 10)]:
		assert_vector(camera.unproject_position(point)).is_equal_approx(_transform.world_to_screen(point),
				Vector2.ONE * 0.5)


func test_la_profondeur_est_ecrasee_et_la_hauteur_se_voit() -> void:
	var ppm: float = _transform.pixels_per_meter()
	var yaw: float = deg_to_rad(_camera_def.yaw_deg)
	var right: Vector3 = Vector3(cos(yaw), 0, -sin(yaw))
	var toward_camera: Vector3 = Vector3(sin(yaw), 0, cos(yaw))
	var ground: Vector3 = Vector3(5, 0, 5)
	var at: Vector2 = _transform.world_to_screen(ground)
	assert_vector(_transform.world_to_screen(ground + right) - at).is_equal_approx(Vector2(ppm, 0), Vector2.ONE * 0.001)
	assert_vector(_transform.world_to_screen(ground + toward_camera) - at).is_equal_approx(Vector2(0, ppm * 0.5),
			Vector2.ONE * 0.001)
	assert_vector(_transform.world_to_screen(ground + Vector3.UP) - at).is_equal_approx(Vector2(0, -ppm * cos(PI / 6.0)),
			Vector2.ONE * 0.001)


func test_les_axes_du_sol_partent_en_diagonale() -> void:
	var origin: Vector2 = _transform.world_to_screen(Vector3.ZERO)
	var x_axis: Vector2 = _transform.world_to_screen(Vector3.RIGHT) - origin
	var z_axis: Vector2 = _transform.world_to_screen(Vector3.BACK) - origin
	assert_bool(x_axis.x > 0.0 and x_axis.y > 0.0).is_true()
	assert_bool(z_axis.x < 0.0 and z_axis.y > 0.0).is_true()


func test_ecran_et_sol_se_convertissent_dans_les_deux_sens() -> void:
	var point: Vector3 = Vector3(7.5, 0, 3.25)
	assert_vector(_transform.screen_to_world(_transform.world_to_screen(point))).is_equal_approx(point,
			Vector3.ONE * 0.0001)


func test_le_zoom_garde_le_point_sous_le_curseur() -> void:
	var cursor: Vector2 = Vector2(610, 140)
	var under: Vector3 = _transform.screen_to_world(cursor)
	_transform.zoom_at(cursor, 1.5)
	assert_vector(_transform.screen_to_world(cursor)).is_equal_approx(under, Vector3.ONE * 0.0001)


func test_cadrer_montre_la_salle_entiere() -> void:
	var view_rect: Rect2 = Rect2(Vector2.ZERO, VIEW)
	for corner: Vector3 in [Vector3.ZERO, Vector3(24, 0, 0), Vector3(24, 0, 20), Vector3(0, 0, 20)]:
		assert_bool(view_rect.grow(0.5).has_point(_transform.world_to_screen(corner))).is_true()


func test_deplacer_fait_suivre_le_sol_a_la_souris() -> void:
	var grabbed: Vector3 = _transform.screen_to_world(Vector2(300, 300))
	_transform.pan(Vector2(40, -25))
	assert_vector(_transform.world_to_screen(grabbed)).is_equal_approx(Vector2(340, 275), Vector2.ONE * 0.01)


func test_la_vue_s_ouvre_comme_le_jeu_sur_le_depart_du_heros() -> void:
	_transform.show_like_game(Vector3(30, 0, 25), VIEW)
	assert_float(_transform.zoom).is_equal(1.0)
	assert_float(_transform.ortho_size()).is_equal(_camera_def.view_height_m)
	assert_vector(_transform.world_to_screen(Vector3(30, 0, 25))).is_equal(VIEW / 2.0)
	var depth_m: float = VIEW.y / _transform.pixels_per_meter() / sin(deg_to_rad(_camera_def.pitch_deg))
	assert_float(depth_m).is_equal_approx(2.0 * _camera_def.view_height_m, 0.001)

