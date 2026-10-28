extends GdUnitTestSuite
## Règles du cycle jour-nuit : le soleil est à l'horizon à l'aube, au zénith à midi ; éteint la nuit, au plus fort
## à midi ; de la couleur de l'aube près de l'horizon, de celle de midi en haut ; l'heure avance et boucle ; le
## soleil suit l'heure.

const SETTINGS := preload("res://5_data/world/day.tres")


func _cycle() -> Array:
	var sun: DirectionalLight3D = auto_free(DirectionalLight3D.new())
	add_child(sun)
	var cycle: DayCycle = auto_free(DayCycle.new())
	cycle.sun = sun
	cycle.settings = SETTINGS
	add_child(cycle)
	return [cycle, sun]


func test_le_soleil_a_l_horizon_a_l_aube_et_au_zenith_a_midi() -> void:
	assert_float(DayCycle.sun_pitch(0.25)).is_equal_approx(0.0, 0.0001)
	assert_float(DayCycle.sun_pitch(0.5)).is_equal_approx(-PI / 2.0, 0.0001)
	assert_float(DayCycle.sun_pitch(0.0)).is_equal_approx(PI / 2.0, 0.0001)


func test_eteint_la_nuit_au_plus_fort_a_midi() -> void:
	assert_float(DayCycle.sun_energy(0.0, SETTINGS)).is_equal(0.0)
	assert_float(DayCycle.sun_energy(0.9, SETTINGS)).is_equal(0.0)
	assert_float(DayCycle.sun_energy(0.5, SETTINGS)).is_equal_approx(SETTINGS.noon_energy, 0.0001)
	assert_float(DayCycle.sun_energy(0.375, SETTINGS)).is_equal_approx(SETTINGS.noon_energy * sin(PI / 4.0), 0.0001)


func test_la_couleur_va_de_l_aube_a_midi() -> void:
	assert_that(DayCycle.sun_color(0.25, SETTINGS)).is_equal(SETTINGS.dawn_color)
	assert_that(DayCycle.sun_color(0.5, SETTINGS)).is_equal(SETTINGS.noon_color)
	assert_that(DayCycle.sun_color(0.0, SETTINGS)).is_equal(SETTINGS.dawn_color)


func test_l_heure_avance_et_boucle() -> void:
	var parts: Array = _cycle()
	var cycle: DayCycle = parts[0]
	assert_float(cycle.time_of_day).is_equal_approx(SETTINGS.start_time, 0.0001)
	cycle.advance(SETTINGS.day_length * 0.5)
	assert_float(cycle.time_of_day).is_equal_approx(fposmod(SETTINGS.start_time + 0.5, 1.0), 0.0001)
	cycle.advance(SETTINGS.day_length)
	assert_float(cycle.time_of_day).is_equal_approx(fposmod(SETTINGS.start_time + 0.5, 1.0), 0.0001)


func test_le_soleil_suit_l_heure() -> void:
	var parts: Array = _cycle()
	var cycle: DayCycle = parts[0]
	var sun: DirectionalLight3D = parts[1]
	cycle.time_of_day = 0.5
	cycle.apply()
	assert_float(sun.rotation.x).is_equal_approx(-PI / 2.0, 0.0001)
	assert_float(sun.light_energy).is_equal_approx(SETTINGS.noon_energy, 0.0001)
	assert_that(sun.light_color).is_equal(SETTINGS.noon_color)
