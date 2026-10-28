extends GdUnitTestSuite
## Règles de l'onde : rien avant l'impact ni au-delà du front ; une sinusoïde de la longueur d'onde voulue derrière
## le front ; elle s'amortit avec la distance et avec le temps ; seuls les y des points changent.

const SETTINGS := preload("res://5_data/vfx/ripple.tres")


func test_rien_avant_l_impact_ni_au_dela_du_front() -> void:
	assert_float(Ripple.height(0.0, 0.0, SETTINGS)).is_equal(0.0)
	assert_float(Ripple.height(SETTINGS.speed * 1.0 + 0.1, 1.0, SETTINGS)).is_equal(0.0)


func test_le_nombre_d_onde() -> void:
	assert_float(Ripple.wave_number(SETTINGS)).is_equal_approx(TAU / SETTINGS.wavelength, 0.0001)


func test_derriere_le_front_une_sinusoide() -> void:
	var time: float = 1.0
	var distance: float = SETTINGS.speed * time - SETTINGS.wavelength / 4.0
	var expected: float = SETTINGS.amplitude * exp(-SETTINGS.distance_damping * distance - SETTINGS.time_damping * time)
	assert_float(Ripple.height(distance, time, SETTINGS)).is_equal_approx(expected, 0.0001)


func test_elle_s_amortit_avec_la_distance_et_le_temps() -> void:
	var near: float = absf(Ripple.height(SETTINGS.speed * 2.0 - SETTINGS.wavelength * 0.25, 2.0, SETTINGS))
	var far: float = absf(Ripple.height(SETTINGS.speed * 3.0 - SETTINGS.wavelength * 0.25, 3.0, SETTINGS))
	assert_float(far).is_less(near)


func test_seuls_les_y_changent() -> void:
	var points: PackedVector3Array = PackedVector3Array([Vector3(0.5, 0.0, 0.0), Vector3(2.0, 0.0, 1.0)])
	var moved: PackedVector3Array = Ripple.displace(points, Vector2.ZERO, 0.6, SETTINGS)
	assert_float(moved[0].x).is_equal(0.5)
	assert_float(moved[1].z).is_equal(1.0)
	assert_float(moved[0].y).is_equal_approx(Ripple.height(0.5, 0.6, SETTINGS), 0.0001)
	assert_float(points[0].y).is_equal(0.0)
