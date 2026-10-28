extends GdUnitTestSuite
## Règles du mouvement : au sol, la vitesse rejoint celle voulue au rythme de l'accélération ; stick lâché, elle
## freine ; en l'air, moins de contrôle, et sans direction l'élan est gardé ; la gravité est bornée ; un saut monte
## de la hauteur des réglages ; on peut sauter peu après un bord ; un appui trop tôt est gardé un instant.

const SETTINGS := preload("res://5_data/gameplay/player_move.tres")
const DT: float = 1.0 / 60.0


func test_au_sol_la_vitesse_rejoint_celle_voulue_au_rythme_de_l_acceleration() -> void:
	var v: Vector3 = Motion.horizontal(Vector3.ZERO, Vector2.RIGHT, true, SETTINGS, DT)
	assert_float(v.x).is_equal_approx(SETTINGS.ground_acceleration * DT, 0.0001)
	for _i: int in 120:
		v = Motion.horizontal(v, Vector2.RIGHT, true, SETTINGS, DT)
	assert_float(v.x).is_equal_approx(SETTINGS.max_speed, 0.0001)


func test_la_direction_voulue_est_bornee_a_un() -> void:
	var v: Vector3 = Vector3.ZERO
	for _i: int in 120:
		v = Motion.horizontal(v, Vector2(3.0, 0.0), true, SETTINGS, DT)
	assert_float(v.x).is_equal_approx(SETTINGS.max_speed, 0.0001)


func test_stick_lache_au_sol_elle_freine() -> void:
	var v: Vector3 = Motion.horizontal(Vector3(4.0, 0.0, 0.0), Vector2.ZERO, true, SETTINGS, DT)
	assert_float(v.x).is_equal_approx(4.0 - SETTINGS.friction * DT, 0.0001)


func test_en_l_air_moins_de_controle_et_l_elan_garde() -> void:
	var v: Vector3 = Motion.horizontal(Vector3.ZERO, Vector2.RIGHT, false, SETTINGS, DT)
	assert_float(v.x).is_equal_approx(SETTINGS.air_acceleration * DT, 0.0001)
	var coasting: Vector3 = Motion.horizontal(Vector3(4.0, -2.0, 1.0), Vector2.ZERO, false, SETTINGS, DT)
	assert_vector(coasting).is_equal(Vector3(4.0, -2.0, 1.0))


func test_la_vitesse_verticale_n_est_pas_touchee() -> void:
	assert_float(Motion.horizontal(Vector3(0.0, 3.0, 0.0), Vector2.UP, true, SETTINGS, DT).y).is_equal(3.0)


func test_la_gravite_est_bornee() -> void:
	assert_float(Motion.fall(0.0, SETTINGS, DT)).is_equal_approx(-SETTINGS.gravity * DT, 0.0001)
	assert_float(Motion.fall(-SETTINGS.max_fall_speed, SETTINGS, 1.0)).is_equal(-SETTINGS.max_fall_speed)


func test_un_saut_monte_de_la_hauteur_des_reglages() -> void:
	var speed: float = Motion.jump_speed(SETTINGS)
	# Hauteur atteinte : v² / 2g.
	assert_float(speed * speed / (2.0 * SETTINGS.gravity)).is_equal_approx(SETTINGS.jump_height, 0.0001)


func test_on_peut_sauter_peu_apres_un_bord() -> void:
	assert_bool(Motion.can_jump(true, 5.0, SETTINGS)).is_true()
	assert_bool(Motion.can_jump(false, SETTINGS.coyote_time * 0.5, SETTINGS)).is_true()
	assert_bool(Motion.can_jump(false, SETTINGS.coyote_time + 0.01, SETTINGS)).is_false()


func test_un_appui_trop_tot_est_garde_un_instant() -> void:
	assert_bool(Motion.jump_buffered(0.0, SETTINGS)).is_true()
	assert_bool(Motion.jump_buffered(SETTINGS.jump_buffer_time, SETTINGS)).is_true()
	assert_bool(Motion.jump_buffered(SETTINGS.jump_buffer_time + 0.01, SETTINGS)).is_false()
	assert_bool(Motion.jump_buffered(-1.0, SETTINGS)).is_false()
