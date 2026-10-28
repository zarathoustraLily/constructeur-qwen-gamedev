extends GdUnitTestSuite
## Règles des vibrations : le petit moteur suit la force du choc ; le gros ne tourne que pour un choc fort ; la durée
## croît avec la force ; coupées dans les réglages ou pour un choc nul, la manette ne vibre pas.

const SETTINGS := preload("res://5_data/input/gamepad_settings.tres")


func after_test() -> void:
	Input.stop_joy_vibration(0)


func test_un_choc_leger_ne_fait_tourner_que_le_petit_moteur() -> void:
	var motors: Vector2 = Rumble.strengths(0.3, SETTINGS)
	assert_float(motors.x).is_equal_approx(0.3 * SETTINGS.weak_motor_scale, 0.0001)
	assert_float(motors.y).is_equal(0.0)


func test_un_choc_fort_fait_tourner_les_deux_moteurs() -> void:
	var motors: Vector2 = Rumble.strengths(0.8, SETTINGS)
	assert_float(motors.x).is_equal_approx(0.8 * SETTINGS.weak_motor_scale, 0.0001)
	assert_float(motors.y).is_equal_approx(0.8 * SETTINGS.strong_motor_scale, 0.0001)


func test_la_force_est_bornee() -> void:
	assert_vector(Rumble.strengths(3.0, SETTINGS)).is_equal(Rumble.strengths(1.0, SETTINGS))


func test_la_duree_croit_avec_la_force() -> void:
	assert_float(Rumble.duration(0.0, SETTINGS)).is_equal_approx(SETTINGS.min_rumble_duration, 0.0001)
	assert_float(Rumble.duration(1.0, SETTINGS)).is_equal_approx(SETTINGS.max_rumble_duration, 0.0001)
	assert_float(Rumble.duration(0.5, SETTINGS)).is_greater(Rumble.duration(0.2, SETTINGS))


func test_un_choc_fait_vibrer_la_manette() -> void:
	Rumble.play(0, 0.8, SETTINGS)
	assert_vector(Input.get_joy_vibration_strength(0)).is_equal(Rumble.strengths(0.8, SETTINGS))


func test_coupees_dans_les_reglages_les_vibrations_ne_partent_pas() -> void:
	var settings: GamepadSettings = SETTINGS.duplicate() as GamepadSettings
	settings.rumble_enabled = false
	Rumble.play(0, 0.8, settings)
	assert_vector(Input.get_joy_vibration_strength(0)).is_equal(Vector2.ZERO)
