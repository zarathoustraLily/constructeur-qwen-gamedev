extends GdUnitTestSuite
## Règles de conduite du kart, avec ses réglages de 5_data : vitesse de pointe, marche arrière, gaz
## analogiques, roue libre, frein, virages (sens, arrêt, rotation sur place, en l'air, plus serrés lentement),
## braquage progressif, saut, gravité, pas de glissade de côté. Le kart est posé sur un vrai sol, puis piloté
## pas à pas : ses méthodes sont appelées directement, moteur physique arrêté.

const KART := preload("res://3_entities/kart/kart.tscn")
const STEP := 1.0 / 60.0

var _kart: Kart
var _settings: KartSettings


func before_test() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(_kart)
	_settings = _kart.settings


## Laisse le kart tomber sur le sol, puis arrête sa physique : on le pilote ensuite pas à pas.
func _land() -> void:
	for _frame: int in 30:
		await get_tree().physics_frame
		if _kart.is_on_ground():
			break
	_kart.set_physics_process(false)
	assert_bool(_kart.is_on_ground()).override_failure_message("le kart n'a pas touché le sol").is_true()


## Lance le kart en l'air, loin du sol, physique arrêtée.
func _fly() -> void:
	_kart.set_physics_process(false)
	_kart.global_position = Vector3(0.0, 50.0, 0.0)
	_kart.move_and_slide()
	assert_bool(_kart.is_on_ground()).is_false()


func _engine(seconds: float) -> void:
	for _frame: int in int(seconds / STEP):
		_kart.apply_engine(STEP)


func _speed() -> float:
	return _kart.get_horizontal_velocity().length()


## Rotation du kart autour de la verticale pendant `seconds`, à `speed` vers l'avant, braquage `steering`.
func _turn(speed: float, steering: float, seconds: float = 0.25) -> float:
	var start := _kart.rotation.y
	_kart.commands.steering = steering
	for _frame: int in int(seconds / STEP):
		_kart.velocity = -_kart.global_basis.z * speed
		_kart.apply_steering(STEP)
	return _kart.rotation.y - start


func test_en_ligne_droite_la_vitesse_plafonne_a_la_vitesse_de_pointe() -> void:
	await _land()
	_kart.commands.throttle = 1.0
	_engine(10.0)
	assert_float(_speed()).is_between(_settings.top_speed * 0.95, _settings.top_speed + _settings.acceleration * STEP)


func test_le_kart_avance_vers_l_avant() -> void:
	await _land()
	_kart.commands.throttle = 1.0
	_engine(1.0)
	assert_float(_kart.velocity.z).is_less(0.0)
	assert_float(_kart.forward_speed()).is_greater(0.0)


func test_la_marche_arriere_plafonne_a_sa_propre_vitesse() -> void:
	await _land()
	_kart.commands.throttle = -1.0
	_engine(10.0)
	assert_float(_kart.forward_speed()).is_less(0.0)
	assert_float(_speed()).is_between(_settings.top_reverse_speed * 0.95,
		_settings.top_reverse_speed + _settings.acceleration * STEP)


func test_une_gachette_a_moitie_accelere_deux_fois_moins() -> void:
	await _land()
	_kart.commands.throttle = 0.5
	_engine(0.5)
	var half := _speed()
	_kart.velocity = Vector3.ZERO
	_kart.commands.throttle = 1.0
	_engine(0.5)
	assert_float(half / _speed()).is_equal_approx(0.5, 0.02)


func test_en_roue_libre_la_vitesse_est_divisee_par_deux_en_ln2_sur_l_amortissement() -> void:
	await _land()
	_kart.velocity = -_kart.global_basis.z * 10.0
	_engine(log(2.0) / _settings.rolling_decay)
	assert_float(_speed()).is_equal_approx(5.0, 0.15)


func test_freiner_arrete_plus_vite_que_rouler_en_roue_libre() -> void:
	await _land()
	_kart.velocity = -_kart.global_basis.z * 15.0
	_engine(2.0)
	var coasting := _speed()
	_kart.velocity = -_kart.global_basis.z * 15.0
	_kart.commands.brake = true
	_engine(2.0)
	assert_float(_speed()).is_less(coasting * 0.5)


func test_braquer_a_droite_tourne_le_kart_vers_la_droite() -> void:
	await _land()
	assert_float(_turn(10.0, 1.0)).is_less(0.0)


func test_braquer_a_gauche_tourne_le_kart_vers_la_gauche() -> void:
	await _land()
	assert_float(_turn(10.0, -1.0)).is_greater(0.0)


func test_a_l_arret_le_kart_ne_tourne_pas() -> void:
	await _land()
	assert_float(_turn(0.0, 1.0)).is_equal(0.0)


func test_en_freinant_a_l_arret_le_kart_tourne_sur_place() -> void:
	await _land()
	_kart.commands.brake = true
	assert_float(_turn(0.0, 1.0)).is_less(0.0)


func test_en_l_air_le_kart_tourne_meme_sans_vitesse() -> void:
	_fly()
	assert_float(_turn(0.0, 1.0)).is_less(0.0)


func test_le_virage_est_plus_serre_a_basse_vitesse() -> void:
	await _land()
	var slow := absf(_turn(5.0, 1.0, 0.1)) / 5.0
	_kart.rotation = Vector3.ZERO
	_kart.steering = 0.0
	var fast := absf(_turn(15.0, 1.0, 0.1)) / 15.0
	assert_float(slow).is_greater(fast)


func test_le_braquage_s_etablit_progressivement() -> void:
	await _land()
	_turn(10.0, 1.0, STEP)
	assert_float(_kart.steering).is_between(0.01, 0.99)
	_turn(10.0, 1.0, 0.5)
	assert_float(_kart.steering).is_equal_approx(1.0, 0.01)


func test_sauter_donne_la_vitesse_de_saut_vers_le_haut_et_le_signale() -> void:
	await _land()
	var jumps: Array[int] = [0]
	_kart.jumped.connect(func() -> void: jumps[0] += 1)
	_kart.velocity = Vector3.ZERO
	_kart.commands.jump = true
	_kart._physics_process(STEP)
	assert_float(_kart.velocity.y).is_equal_approx(_settings.jump_velocity, 0.01)
	assert_int(jumps[0]).is_equal(1)


func test_en_l_air_on_ne_saute_pas() -> void:
	_fly()
	_kart.velocity = Vector3.ZERO
	_kart.commands.jump = true
	_kart._physics_process(STEP)
	assert_float(_kart.velocity.y).is_less(0.0)


func test_en_l_air_la_gravite_tire_vers_le_bas() -> void:
	_fly()
	_kart.velocity = Vector3.ZERO
	_kart.apply_air(STEP)
	assert_float(_kart.velocity.y).is_equal_approx(-_settings.gravity * STEP, 0.0001)


func test_en_l_air_le_kart_ne_glisse_pas_de_cote() -> void:
	_fly()
	_kart.velocity = Vector3(5.0, 0.0, -3.0)
	_kart.apply_air(STEP)
	assert_float(_kart.velocity.x).is_equal_approx(0.0, 0.0001)
	assert_float(_kart.velocity.z).is_equal_approx(-3.0, 0.0001)


func test_au_sol_le_kart_ne_glisse_pas_de_cote() -> void:
	await _land()
	_kart.velocity = Vector3(5.0, 0.0, -3.0)
	_kart.apply_engine(STEP)
	assert_float(_kart.velocity.x).is_equal_approx(0.0, 0.0001)


func test_avec_son_adaptateur_le_kart_lit_les_commandes_du_pilote() -> void:
	var driven: Kart = auto_free(KART.instantiate())
	add_child(driven)
	assert_object(driven.input).is_not_null()
	Input.action_press("move_forward")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("move_forward")
	assert_float(driven.commands.throttle).is_equal_approx(1.0, 0.001)
