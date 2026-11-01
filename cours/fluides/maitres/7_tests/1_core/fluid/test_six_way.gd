extends GdUnitTestSuite
## Règles du mélange : une lumière sur un axe ne lit que l'image de ce côté ; les poids font toujours 1 ; le signe de l'axe choisit l'image.

const FIRST := Color(0.1, 0.2, 0.3, 1.0)
const SECOND := Color(0.4, 0.5, 0.6, 1.0)


func test_une_lumiere_de_droite_lit_la_droite() -> void:
	assert_float(SixWay.lit(FIRST, SECOND, Vector3.RIGHT)).is_equal_approx(0.1, 0.0001)


func test_une_lumiere_de_gauche_lit_la_gauche() -> void:
	assert_float(SixWay.lit(FIRST, SECOND, Vector3.LEFT)).is_equal_approx(0.4, 0.0001)


func test_une_lumiere_d_en_haut_lit_le_haut() -> void:
	assert_float(SixWay.lit(FIRST, SECOND, Vector3.UP)).is_equal_approx(0.2, 0.0001)


func test_une_lumiere_d_en_bas_lit_le_bas() -> void:
	assert_float(SixWay.lit(FIRST, SECOND, Vector3.DOWN)).is_equal_approx(0.5, 0.0001)


func test_une_lumiere_derriere_la_camera_lit_l_avant() -> void:
	assert_float(SixWay.lit(FIRST, SECOND, Vector3(0.0, 0.0, 1.0))).is_equal_approx(0.6, 0.0001)


func test_une_lumiere_derriere_la_fumee_lit_l_arriere() -> void:
	assert_float(SixWay.lit(FIRST, SECOND, Vector3(0.0, 0.0, -1.0))).is_equal_approx(0.3, 0.0001)


func test_une_fumee_egale_partout_ne_depend_pas_de_la_direction() -> void:
	var partout: Color = Color(0.7, 0.7, 0.7, 1.0)
	for direction: Vector3 in [Vector3(1.0, 1.0, 0.0), Vector3(-1.0, 2.0, 3.0), Vector3(2.0, -1.0, -1.0)]:
		assert_float(SixWay.lit(partout, partout, direction.normalized())).is_equal_approx(0.7, 0.0001)


func test_entre_deux_axes_on_melange_les_deux_cotes() -> void:
	var direction: Vector3 = Vector3(1.0, 1.0, 0.0).normalized()
	assert_float(SixWay.lit(FIRST, SECOND, direction)).is_equal_approx((0.1 + 0.2) * 0.5, 0.0001)
