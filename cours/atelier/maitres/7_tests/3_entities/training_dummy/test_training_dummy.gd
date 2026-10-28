extends GdUnitTestSuite
## Règles du mannequin : au repos au départ ; un coup l'étourdit (Hit), puis il revient au repos ; à zéro point de
## vie, il tombe (Defeated) et ne réagit plus ; sa vue penche pendant un coup et se couche une fois vaincu, en
## rejoignant l'inclinaison sans dépendre du nombre d'images.

const DUMMY := preload("res://3_entities/training_dummy/training_dummy.tscn")
const SETTINGS := preload("res://5_data/gameplay/dummy.tres")


func _dummy() -> TrainingDummy:
	var dummy: TrainingDummy = auto_free(DUMMY.instantiate())
	add_child(dummy)
	return dummy


func test_au_repos_au_depart() -> void:
	assert_str(String(_dummy().state())).is_equal("Idle")


func test_un_coup_l_etourdit_puis_il_revient_au_repos() -> void:
	var dummy: TrainingDummy = _dummy()
	assert_float(dummy.hit(5.0)).is_equal(5.0)
	assert_str(String(dummy.state())).is_equal("Hit")
	var hit_state: DummyHitState = dummy.machine.current as DummyHitState
	hit_state.physics_update(SETTINGS.hit_stun_time + 0.01)
	assert_str(String(dummy.state())).is_equal("Idle")


func test_l_etourdissement_dure_le_temps_des_reglages() -> void:
	var dummy: TrainingDummy = _dummy()
	dummy.hit(5.0)
	var hit_state: DummyHitState = dummy.machine.current as DummyHitState
	hit_state.physics_update(SETTINGS.hit_stun_time * 0.5)
	assert_str(String(dummy.state())).is_equal("Hit")
	assert_float(hit_state.time_left).is_equal_approx(SETTINGS.hit_stun_time * 0.5, 0.0001)


func test_a_zero_il_tombe_et_ne_reagit_plus() -> void:
	var dummy: TrainingDummy = _dummy()
	dummy.hit(1000.0)
	assert_str(String(dummy.state())).is_equal("Defeated")
	dummy.health.tick(10.0)
	assert_float(dummy.hit(5.0)).is_equal(0.0)
	assert_str(String(dummy.state())).is_equal("Defeated")


func test_l_inclinaison_voulue_suit_l_etat() -> void:
	assert_float(TrainingDummyView.target_tilt(&"Idle", SETTINGS)).is_equal(0.0)
	assert_float(TrainingDummyView.target_tilt(&"Hit", SETTINGS)).is_equal(-SETTINGS.hit_tilt)
	assert_float(TrainingDummyView.target_tilt(&"Defeated", SETTINGS)).is_equal(-SETTINGS.defeated_tilt)


func test_l_approche_ne_depend_pas_du_nombre_d_images() -> void:
	var once: float = TrainingDummyView.approach(0.0, 1.0, 10.0, 0.1)
	var twice: float = TrainingDummyView.approach(TrainingDummyView.approach(0.0, 1.0, 10.0, 0.05), 1.0, 10.0, 0.05)
	assert_float(once).is_equal_approx(twice, 0.0001)
	assert_float(once).is_equal_approx(1.0 - exp(-1.0), 0.0001)


func test_vaincu_la_vue_se_couche() -> void:
	var dummy: TrainingDummy = _dummy()
	dummy.hit(1000.0)
	var view: TrainingDummyView = dummy.get_node("View") as TrainingDummyView
	for _frame: int in 60:
		view._process(1.0 / 60.0)
	assert_float(view.rotation.x).is_equal_approx(-SETTINGS.defeated_tilt, 0.01)
