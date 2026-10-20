extends GdUnitTestSuite
## Règles de la pluie : la route se mouille peu à peu, la pluie est partagée par GameState,
## le soleil baisse sous la pluie, et tout revient comme avant quand la pluie s'en va.

const SCENE_PLUIE := "res://3_entities/effects/rain/rain.tscn"
const PAS_UNE_IMAGE := 1.0 / 60.0

var _soleil: DirectionalLight3D


func before_test() -> void:
	_soleil = auto_free(DirectionalLight3D.new())
	_soleil.light_energy = 1.0
	add_child(_soleil)


func _pluie(intensite: float, deja_mouillee: bool) -> RainController:
	var pluie: RainController = load(SCENE_PLUIE).instantiate()
	pluie.intensity = intensite
	pluie.start_wet = deja_mouillee
	add_child(pluie)
	pluie.set_process(false)
	return pluie


func test_s_il_pleut_au_lancement_la_route_est_deja_mouillee() -> void:
	var pluie: RainController = auto_free(_pluie(0.8, true))
	assert_float(pluie.wetness).is_equal(0.8)


func test_sinon_la_route_part_seche_et_se_mouille_peu_a_peu() -> void:
	var pluie: RainController = auto_free(_pluie(0.8, false))
	assert_float(pluie.wetness).is_equal(0.0)
	pluie._process(1.0)
	assert_float(pluie.wetness).is_equal_approx(pluie.wetness_speed, 0.0001)
	pluie._process(100.0)
	assert_float(pluie.wetness).is_equal(0.8)


func test_la_pluie_est_partagee_par_game_state() -> void:
	var pluie: RainController = auto_free(_pluie(0.6, false))
	pluie._process(1.0)
	assert_float(GameState.rain_intensity).is_equal(0.6)
	assert_float(GameState.rain_wetness).is_equal(pluie.wetness)


func test_sans_pluie_aucune_goutte_ne_tombe() -> void:
	var pluie: RainController = auto_free(_pluie(0.0, false))
	pluie._process(PAS_UNE_IMAGE)
	assert_bool(pluie._drops.emitting).is_false()
	var averse: RainController = auto_free(_pluie(1.0, false))
	averse._process(PAS_UNE_IMAGE)
	assert_bool(averse._drops.emitting).is_true()


func test_le_soleil_baisse_sous_la_pluie() -> void:
	var pluie: RainController = auto_free(_pluie(0.8, true))
	await get_tree().process_frame
	pluie._process(PAS_UNE_IMAGE)
	assert_float(_soleil.light_energy).is_equal_approx(1.0 - pluie.sun_dim * 0.8, 0.0001)


func test_quand_la_pluie_s_en_va_tout_revient_comme_avant() -> void:
	var pluie := _pluie(0.8, true)
	await get_tree().process_frame
	pluie._process(PAS_UNE_IMAGE)
	pluie.free()
	assert_float(GameState.rain_intensity).is_equal(0.0)
	assert_float(GameState.rain_wetness).is_equal(0.0)
	assert_float(_soleil.light_energy).is_equal(1.0)



func _camera(position: Vector3) -> Camera3D:
	var camera: Camera3D = auto_free(Camera3D.new())
	camera.position = position
	add_child(camera)
	camera.make_current()
	return camera


func test_la_pluie_tombe_au_dessus_de_la_camera() -> void:
	var camera := _camera(Vector3(3, 2, 1))
	var pluie: RainController = auto_free(_pluie(0.8, true))
	pluie._process(PAS_UNE_IMAGE)
	pluie._process(PAS_UNE_IMAGE)
	assert_vector(pluie.global_position).is_equal_approx(camera.global_position + Vector3.UP * pluie.height_above_camera, Vector3.ONE * 0.001)


func test_la_pluie_tombe_devant_une_camera_qui_avance() -> void:
	var camera := _camera(Vector3.ZERO)
	var pluie: RainController = auto_free(_pluie(0.8, true))
	pluie._process(PAS_UNE_IMAGE)
	for i in 120:
		camera.position += Vector3(10, 3, 0) * PAS_UNE_IMAGE
		pluie._process(PAS_UNE_IMAGE)
	var avance := pluie.global_position - camera.global_position
	assert_float(avance.x).is_between(10.0 * pluie.follow_lead * 0.9, 10.0 * pluie.follow_lead)
	assert_float(avance.y).is_equal_approx(pluie.height_above_camera, 0.001)


func test_le_brouillard_s_epaissit_sous_la_pluie_puis_revient() -> void:
	var monde: WorldEnvironment = auto_free(WorldEnvironment.new())
	monde.environment = Environment.new()
	monde.environment.fog_density = 0.01
	add_child(monde)
	var pluie := _pluie(0.8, true)
	await get_tree().process_frame
	pluie._process(PAS_UNE_IMAGE)
	assert_float(monde.environment.fog_density).is_equal_approx(0.01 + pluie.extra_fog_density * 0.8, 0.00001)
	pluie.free()
	assert_float(monde.environment.fog_density).is_equal_approx(0.01, 0.00001)


func test_sans_assombrissement_le_soleil_ne_change_pas() -> void:
	var pluie: RainController = load(SCENE_PLUIE).instantiate()
	pluie.darken_scene = false
	add_child(auto_free(pluie))
	pluie.set_process(false)
	await get_tree().process_frame
	pluie._process(PAS_UNE_IMAGE)
	assert_float(_soleil.light_energy).is_equal(1.0)


func test_la_quantite_de_gouttes_suit_l_intensite() -> void:
	var pluie: RainController = auto_free(_pluie(0.6, false))
	pluie._process(PAS_UNE_IMAGE)
	assert_float(pluie._drops.amount_ratio).is_equal_approx(0.6, 0.0001)
