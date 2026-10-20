extends GdUnitTestSuite
## Règles du capteur de flottaison : dans l'eau, sous l'eau, sur l'eau, profondeur ; avec une surface d'eau,
## la hauteur et la pente de la surface sous le capteur. Sans surface dans la scène, la hauteur reste celle
## qu'on lui donne, et par défaut le capteur n'est jamais dans l'eau.

const SurfaceTemoin := preload("res://7_tests/1_core/water/surface_temoin.gd")


func _ocean(hauteur: Callable) -> WaterSurface:
	var ocean: WaterSurface = auto_free(SurfaceTemoin.new())
	ocean.set("hauteur", hauteur)
	add_child(ocean)
	return ocean


func _capteur(y: float, surface: float = 0.0) -> WaterBuoyancySensor:
	var capteur: WaterBuoyancySensor = auto_free(WaterBuoyancySensor.new())
	add_child(capteur)
	capteur.set_physics_process(false)
	capteur.position.y = y
	capteur.water_height = surface
	return capteur


func test_dans_l_eau_des_que_la_surface_atteint_le_capteur() -> void:
	assert_bool(_capteur(0.0).is_in_water()).is_true()
	assert_bool(_capteur(-0.5).is_in_water()).is_true()
	assert_bool(_capteur(0.1).is_in_water()).is_false()


func test_sous_l_eau_quand_la_surface_depasse_le_capteur_de_sa_hauteur() -> void:
	var capteur := _capteur(-1.0)
	assert_float(capteur.height).is_equal(1.0)
	assert_bool(capteur.is_under_water()).is_true()
	assert_bool(_capteur(-0.9).is_under_water()).is_false()


func test_sur_l_eau_c_est_dans_l_eau_sans_etre_dessous() -> void:
	assert_bool(_capteur(-0.5).is_on_water()).is_true()
	assert_bool(_capteur(-1.5).is_on_water()).is_false()
	assert_bool(_capteur(0.5).is_on_water()).is_false()


func test_la_profondeur_est_negative_sous_la_surface() -> void:
	assert_float(_capteur(-0.25, 0.5).get_water_depth()).is_equal_approx(-0.75, 0.0001)
	assert_float(_capteur(2.0, 0.5).get_water_depth()).is_equal_approx(1.5, 0.0001)


func test_sans_surface_le_capteur_n_est_jamais_dans_l_eau() -> void:
	var capteur: WaterBuoyancySensor = auto_free(WaterBuoyancySensor.new())
	add_child(capteur)
	capteur.position.y = -100.0
	await get_tree().physics_frame
	assert_bool(capteur.is_in_water()).is_false()


func test_sans_surface_la_hauteur_donnee_ne_bouge_pas_et_reste_horizontale() -> void:
	var capteur := _capteur(0.0, 0.3)
	capteur._physics_process(1.0 / 60.0)
	assert_float(capteur.get_water_height()).is_equal(0.3)
	assert_vector(capteur.compute_normal()).is_equal(Vector3.UP)


func test_le_capteur_trouve_la_surface_de_la_scene() -> void:
	var ocean := _ocean(func(_p: Vector3) -> float: return 0.0)
	assert_object(_capteur(0.0).ocean_node).is_same(ocean)


func test_une_surface_deja_donnee_n_est_pas_remplacee() -> void:
	_ocean(func(_p: Vector3) -> float: return 0.0)
	var choisi: WaterSurface = auto_free(SurfaceTemoin.new())
	choisi.remove_from_group("ocean")
	var capteur: WaterBuoyancySensor = auto_free(WaterBuoyancySensor.new())
	capteur.ocean_node = choisi
	add_child(capteur)
	assert_object(capteur.ocean_node).is_same(choisi)


func test_le_capteur_lit_la_hauteur_de_la_surface_sous_lui() -> void:
	_ocean(func(p: Vector3) -> float: return 0.5 + 0.1 * p.x)
	var capteur := _capteur(0.0)
	capteur.position.x = 2.0
	capteur._physics_process(1.0 / 60.0)
	assert_float(capteur.get_water_height()).is_equal_approx(0.7, 0.0001)


func test_la_normale_suit_la_pente_de_la_surface() -> void:
	_ocean(func(p: Vector3) -> float: return 0.5 * p.x + 0.25 * p.z)
	var capteur := _capteur(0.0)
	capteur.position = Vector3(1, 0, 2)
	capteur._physics_process(1.0 / 60.0)
	assert_vector(capteur.compute_normal()).is_equal_approx(Vector3(-0.5, 1.0, -0.25).normalized(), Vector3.ONE * 0.0001)
