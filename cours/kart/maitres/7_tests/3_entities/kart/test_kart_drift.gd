extends GdUnitTestSuite
## Règles du dérapage, du turbo et des figures, avec les réglages de 5_data : un saut en braquant, gaz
## ouverts, lance le dérapage, qui passe en glissade puis aux étincelles et aux étincelles chaudes ; le
## relâcher aux étincelles donne un turbo court, aux étincelles chaudes un turbo long, en glissade rien ; en
## dérapage, le kart tourne plus serré ; le turbo dépasse la vitesse de pointe puis s'éteint ; en l'air, un
## saut fait une figure, et l'atterrissage donne un turbo ; pas de figure juste après un saut depuis le sol.

const KART := preload("res://3_entities/kart/kart.tscn")
const STEP := 1.0 / 60.0

var _kart: Kart
var _settings: KartSettings
var _stages: Array[Kart.DriftStage] = []
var _boosts: Array[bool] = []
var _tricks: Array[int] = [0]


func before_test() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1000.0, 1.0, 1000.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(_kart)
	_settings = _kart.settings
	_stages.clear()
	_boosts.clear()
	_tricks[0] = 0
	_kart.drift_stage_changed.connect(func(stage: Kart.DriftStage) -> void: _stages.append(stage))
	_kart.boost_changed.connect(func(active: bool) -> void: _boosts.append(active))
	_kart.tricked.connect(func() -> void: _tricks[0] += 1)


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


## Un saut d'une image : `jump` vrai, puis faux.
func _press_jump() -> void:
	_kart.commands.jump = true
	await _frames(1)
	_kart.commands.jump = false


## Un relâchement de saut d'une image.
func _release_jump() -> void:
	_kart.commands.jump_released = true
	await _frames(1)
	_kart.commands.jump_released = false


## Pose le kart, le lance gaz ouverts, puis lance un dérapage à droite.
func _start_drift() -> void:
	await _frames(30)
	_kart.commands.throttle = 1.0
	await _frames(60)
	_kart.commands.steering = 1.0
	await _press_jump()


func test_un_saut_en_braquant_gaz_ouverts_lance_le_derapage() -> void:
	await _start_drift()
	await _frames(30)
	assert_bool(_kart.drifting).is_true()
	assert_float(_kart.drift_direction).is_equal(1.0)
	assert_that(_kart.drift_stage).is_equal(Kart.DriftStage.SLIDING)


func test_le_derapage_monte_de_niveau_avec_le_temps() -> void:
	await _start_drift()
	await _frames(int((_settings.drift_hot_sparks_time + 1.0) / STEP))
	assert_array(_stages).is_equal([Kart.DriftStage.SLIDING, Kart.DriftStage.SPARKS, Kart.DriftStage.HOT_SPARKS])


func test_relacher_aux_etincelles_donne_un_turbo_court() -> void:
	await _start_drift()
	await _frames(int((_settings.drift_sparks_time + 0.6) / STEP))
	assert_that(_kart.drift_stage).is_equal(Kart.DriftStage.SPARKS)
	await _release_jump()
	assert_bool(_kart.drifting).is_false()
	assert_float(_kart.boost_time).is_equal_approx(_settings.drift_boost_short, 2.0 * STEP)
	assert_array(_boosts).is_equal([true])


func test_relacher_aux_etincelles_chaudes_donne_un_turbo_long() -> void:
	await _start_drift()
	await _frames(int((_settings.drift_hot_sparks_time + 1.0) / STEP))
	await _release_jump()
	assert_float(_kart.boost_time).is_equal_approx(_settings.drift_boost_long, 2.0 * STEP)


func test_relacher_en_glissade_ne_donne_rien() -> void:
	await _start_drift()
	await _frames(30)
	await _release_jump()
	assert_bool(_kart.is_boosting()).is_false()
	assert_array(_boosts).is_empty()
	assert_that(_kart.drift_stage).is_equal(Kart.DriftStage.NONE)


func test_lacher_les_gaz_arrete_le_derapage() -> void:
	await _start_drift()
	await _frames(30)
	_kart.commands.throttle = 0.0
	await _frames(1)
	assert_bool(_kart.drifting).is_false()


func test_en_derapage_le_kart_tourne_plus_serre() -> void:
	await _frames(30)
	_kart.set_physics_process(false)
	var turn := func(drifting: bool) -> float:
		_kart.rotation.y = 0.0
		_kart.velocity = -_kart.global_basis.z * 10.0
		_kart.commands.steering = 1.0
		_kart.steering = 1.0
		_kart.drifting = drifting
		_kart.drift_direction = 1.0
		for _step: int in 15:
			_kart.apply_steering(STEP)
			_kart.velocity = -_kart.global_basis.z * 10.0
		return absf(_kart.rotation.y)
	var normal: float = turn.call(false)
	var drift: float = turn.call(true)
	assert_float(drift).is_greater(normal)


func test_le_turbo_depasse_la_vitesse_de_pointe_puis_s_eteint() -> void:
	await _frames(30)
	_kart.commands.throttle = 1.0
	_kart.set_boost(2.5)
	await _frames(int(2.0 / STEP))
	assert_float(_kart.forward_speed()).is_greater(_settings.top_speed)
	await _frames(int(1.0 / STEP))
	assert_bool(_kart.is_boosting()).is_false()
	assert_array(_boosts).is_equal([true, false])


func test_une_figure_en_l_air_puis_l_atterrissage_donnent_un_turbo() -> void:
	_kart.global_position = Vector3(0.0, 6.0, 0.0)
	await _frames(5)
	assert_bool(_kart.is_on_ground()).is_false()
	await _press_jump()
	assert_int(_tricks[0]).is_equal(1)
	assert_bool(_kart.has_tricked).is_true()
	await _frames(90)
	assert_bool(_kart.is_on_ground()).is_true()
	assert_bool(_kart.has_tricked).is_false()
	assert_array(_boosts).is_equal([true])


func test_pas_de_figure_juste_apres_un_saut_depuis_le_sol() -> void:
	await _frames(30)
	await _press_jump()
	await _frames(3)
	assert_bool(_kart.is_on_ground()).is_false()
	await _press_jump()
	assert_int(_tricks[0]).is_equal(0)
