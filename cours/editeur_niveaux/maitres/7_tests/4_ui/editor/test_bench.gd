extends GdUnitTestSuite
## Le banc d'essai : la marche avance à la vitesse des réglages et tourne le modèle dans le sens de la marche ; poser une
## animation joue son clip de repos ; un état joue son clip à sa vitesse ; marcher passe à la course, s'arrêter revient
## au repos ; un effet ajouté porte le débit et la durée de sa définition, et se retire ; les actions du projet font
## marcher et attaquer ; le banc ne touche jamais à une salle.

var _settings: EditorSettingsDef
var _bench: BenchView
var _brute: AnimationDef


func before_test() -> void:
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_brute = ResourceLoader.load("res://5_data/animations/brute.tres") as AnimationDef
	_bench = auto_free(BenchView.new())
	add_child(_bench)
	_bench.setup(_settings)


func after_test() -> void:
	for action: StringName in [&"bench_right", &"bench_attack"]:
		Input.action_release(action)


func test_la_marche_avance_et_tourne_le_modele() -> void:
	var motion: BenchMotion = BenchMotion.new()
	motion.step(Vector2(1, 0), 0.5, 4.0)
	assert_vector(motion.position).is_equal_approx(Vector3(2, 0, 0), Vector3.ONE * 0.0001)
	assert_float(motion.facing).is_equal_approx(-PI / 2.0, 0.0001)
	assert_str(String(motion.state)).is_equal("move")
	motion.step(Vector2.ZERO, 0.5, 4.0)
	assert_str(String(motion.state)).is_equal("idle")


func test_poser_une_animation_joue_le_repos_et_un_etat_sa_vitesse() -> void:
	assert_bool(_bench.show_animation(_brute)).is_true()
	assert_str(String(_bench.current_clip())).is_equal("repos")
	assert_bool(_bench.play_state(&"attack")).is_true()
	assert_str(String(_bench.current_clip())).is_equal("attaque")
	assert_float(_bench.current_speed()).is_equal_approx(_brute.speeds[&"attack"], 0.0001)


func test_marcher_passe_a_la_course_s_arreter_revient_au_repos() -> void:
	_bench.show_animation(_brute)
	_bench.step(Vector2(0, -1), 0.5)
	assert_str(String(_bench.current_clip())).is_equal("course")
	assert_vector(_bench.model_position()).is_equal_approx(Vector3(0, 0, -_settings.bench_move_speed_mps * 0.5),
			Vector3.ONE * 0.0001)
	_bench.step(Vector2.ZERO, 0.5)
	assert_str(String(_bench.current_clip())).is_equal("repos")


func test_un_effet_ajoute_porte_sa_definition_et_se_retire() -> void:
	_bench.show_animation(_brute)
	var smoke: FxDef = ResourceLoader.load("res://5_data/effets/fumee.tres") as FxDef
	var particles: CPUParticles3D = _bench.add_effect(smoke)
	assert_int(particles.amount).is_equal(EffectPreview.count(smoke))
	assert_float(particles.lifetime).is_equal(smoke.lifetime_s)
	assert_int(_bench.effects().size()).is_equal(1)
	_bench.clear_effects()
	assert_int(_bench.effects().size()).is_equal(0)


func test_les_actions_du_projet_font_marcher_et_attaquer() -> void:
	_bench.show_animation(_brute)
	var input: BenchInput = auto_free(BenchInput.new())
	input.setup(_bench)
	Input.action_press(&"bench_right")
	input.read_frame(0.5)
	assert_float(_bench.model_position().x).is_greater(0.0)
	Input.action_release(&"bench_right")
	Input.action_press(&"bench_attack")
	input.read_frame(0.1)
	assert_str(String(_bench.current_clip())).is_equal("attaque")
