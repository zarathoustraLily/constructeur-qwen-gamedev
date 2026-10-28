extends GdUnitTestSuite
## Règles du mouvement : pousser le stick vers le haut avance là où regarde la caméra ; la direction ne dépasse jamais
## un ; la vitesse rejoint la cible au rythme de l'accélération et freine au rythme du freinage ; la vitesse verticale
## n'est pas touchée ; le corps tourne vers sa marche par le plus court chemin, sans dépasser sa vitesse de virage ;
## les couches donnent leur bit.


func test_le_haut_du_stick_avance_la_ou_regarde_la_camera() -> void:
	assert_vector(Motion.camera_relative(Vector2(0.0, -1.0), 0.0)).is_equal_approx(Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.0001)
	assert_vector(Motion.camera_relative(Vector2(0.0, -1.0), PI / 2.0)).is_equal_approx(Vector3(-1.0, 0.0, 0.0), Vector3.ONE * 0.0001)
	assert_vector(Motion.camera_relative(Vector2(1.0, 0.0), 0.0)).is_equal_approx(Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.0001)


func test_la_direction_ne_depasse_jamais_un() -> void:
	assert_float(Motion.camera_relative(Vector2(1.0, -1.0), 0.3).length()).is_equal_approx(1.0, 0.0001)
	assert_float(Motion.camera_relative(Vector2(0.3, 0.0), 0.0).length()).is_equal_approx(0.3, 0.0001)


func test_la_vitesse_rejoint_la_cible_puis_freine() -> void:
	var v: Vector3 = Motion.approach(Vector3.ZERO, Vector3(5.0, 0.0, 0.0), 45.0, 60.0, 0.05)
	assert_float(v.x).is_equal_approx(2.25, 0.0001)
	var stopping: Vector3 = Motion.approach(Vector3(5.0, -3.0, 0.0), Vector3.ZERO, 45.0, 60.0, 0.05)
	assert_float(stopping.x).is_equal_approx(2.0, 0.0001)
	assert_float(stopping.y).is_equal(-3.0)


func test_le_corps_tourne_vers_sa_marche_par_le_plus_court_chemin() -> void:
	assert_float(Motion.face(0.0, Vector3(0.0, 0.0, -1.0), 10.0, 1.0)).is_equal_approx(0.0, 0.0001)
	var turned: float = Motion.face(0.0, Vector3(-1.0, 0.0, 0.0), 100.0, 1.0)
	assert_float(turned).is_equal_approx(PI / 2.0, 0.0001)
	var short_way: float = Motion.face(deg_to_rad(170.0), Vector3(0.0, 0.0, 1.0).rotated(Vector3.UP, deg_to_rad(-170.0)), 100.0, 1.0)
	assert_float(absf(angle_difference(short_way, deg_to_rad(-170.0) + PI))).is_less(0.0001)


func test_le_virage_ne_depasse_pas_sa_vitesse() -> void:
	assert_float(Motion.face(0.0, Vector3(1.0, 0.0, 0.0), 2.0, 0.1)).is_equal_approx(-0.2, 0.0001)


func test_sans_direction_le_corps_ne_tourne_pas() -> void:
	assert_float(Motion.face(1.2, Vector3.ZERO, 10.0, 1.0)).is_equal(1.2)


func test_les_couches_donnent_leur_bit() -> void:
	assert_int(Layers.bit(Layers.HERO)).is_equal(2)
	assert_int(Layers.mask([Layers.WORLD, Layers.BOSS])).is_equal(0b101)
	assert_bool(Layers.has(Layers.mask([Layers.PROJECTILES]), Layers.PROJECTILES)).is_true()
