extends GdUnitTestSuite
## La caméra tourne autour du point visé : au lacet 0 elle est devant le sujet (+Z), à 90 de son côté gauche (+X), et
## regarde toujours le point visé. Le tangage et la distance ont leurs bornes. La vue du jeu prend l'inclinaison et la
## rotation des réglages, en orthographique, et ne se rapproche pas ; tourner la quitte en partant de son angle.
## Cadrer un pavé recule assez pour le voir en entier.


func _rig() -> OrbitRig:
	var rig: OrbitRig = OrbitRig.new()
	rig.pitch_deg = 0.0
	rig.distance = 4.0
	return rig


func test_au_lacet_0_la_camera_est_devant_le_sujet_et_le_regarde() -> void:
	var xform: Transform3D = _rig().camera_transform()
	assert_vector(xform.origin).is_equal_approx(Vector3(0, 0, 4), Vector3.ONE * 0.0001)
	assert_vector(-xform.basis.z).is_equal_approx(Vector3(0, 0, -1), Vector3.ONE * 0.0001)


func test_au_lacet_90_la_camera_est_du_cote_gauche_du_sujet() -> void:
	var rig: OrbitRig = _rig()
	rig.orbit(90.0, 0.0)
	assert_vector(rig.camera_transform().origin).is_equal_approx(Vector3(4, 0, 0), Vector3.ONE * 0.0001)


func test_le_tangage_et_la_distance_ont_leurs_bornes() -> void:
	var rig: OrbitRig = _rig()
	rig.orbit(-400.0, 200.0)
	assert_float(rig.yaw_deg).is_equal_approx(320.0, 0.0001)
	assert_float(rig.pitch_deg).is_equal(OrbitRig.MAX_PITCH_DEG)
	rig.zoom(0.001)
	assert_float(rig.distance).is_equal(OrbitRig.MIN_DISTANCE)


func test_la_vue_du_jeu_prend_les_reglages_et_ne_se_rapproche_pas() -> void:
	var rig: OrbitRig = _rig()
	rig.use_config(ViewerConfig.load_file("res://5_data/visualiseur/config.json"))
	rig.game_view = true
	rig.zoom(0.5)
	assert_float(rig.distance).is_equal(4.0)
	assert_float(rig.view_yaw()).is_equal(45.0)
	var camera: Camera3D = auto_free(Camera3D.new())
	rig.apply(camera)
	assert_int(camera.projection).is_equal(Camera3D.PROJECTION_ORTHOGONAL)
	assert_float(camera.size).is_equal(8.0)
	var up: float = rad_to_deg(asin(rig.eye_direction().y))
	assert_float(up).is_equal_approx(30.0, 0.0001)


func test_tourner_quitte_la_vue_du_jeu_en_partant_de_son_angle() -> void:
	var rig: OrbitRig = _rig()
	rig.game_view = true
	rig.orbit(10.0, 0.0)
	assert_bool(rig.game_view).is_false()
	assert_float(rig.yaw_deg).is_equal_approx(55.0, 0.0001)
	assert_float(rig.pitch_deg).is_equal_approx(30.0, 0.0001)


func test_cadrer_recule_assez_pour_voir_le_pave_en_entier() -> void:
	var rig: OrbitRig = _rig()
	rig.frame(AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 2, 1)))
	assert_vector(rig.target).is_equal_approx(Vector3(0, 1, 0), Vector3.ONE * 0.0001)
	var radius: float = Vector3(1, 2, 1).length() * 0.5
	var half_fov: float = deg_to_rad(OrbitRig.FOV_DEG) * 0.5
	assert_float(sin(half_fov) * rig.distance).is_greater_equal(radius)
