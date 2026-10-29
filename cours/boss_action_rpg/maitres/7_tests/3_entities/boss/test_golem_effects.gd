extends GdUnitTestSuite
## Règles des effets du golem : un impact fait partir une onde de poussière du point touché, qui s'étend puis
## s'efface, et relance la poussière et les éclats au même point ; pendant la fenêtre du marteau, une traînée suit sa
## tête, puis s'efface ; un coup qui porte fait jaillir des étincelles sur le héros, un coup esquivé non ; à la seconde
## phase, les jointures de son armure s'allument (une couche à lui, sur chaque pièce d'armure, le matériau de l'armure
## restant éteint) et s'éteignent à sa chute ; la
## caméra tremble à un impact proche, pas à un impact lointain ; aucun nœud n'est créé pendant un coup.

const GOLEM := preload("res://3_entities/boss/golem.tscn")
const CAMERA := preload("res://1_core/camera/orbit_camera.tscn")
const ARMOR := preload("res://6_assets/Characters/Golem/Materials/M_Golem_Armor.tres")
const DT: float = 1.0 / 60.0

var _mark: Node3D


func before_test() -> void:
	_mark = auto_free(Node3D.new()) as Node3D
	_mark.position = Vector3(0.0, 0.0, -3.0)
	add_child(_mark)


func _golem() -> Golem:
	var golem: Golem = auto_free(GOLEM.instantiate()) as Golem
	golem.target = _mark
	add_child(golem)
	return golem


func _effets(golem: Golem) -> GolemEffects:
	return golem.get_node("Effects") as GolemEffects


func _process_frames(count: int) -> void:
	for _i: int in count:
		await get_tree().process_frame


func test_un_impact_fait_partir_une_onde_qui_s_etend_puis_s_efface() -> void:
	var golem: Golem = _golem()
	var effets: GolemEffects = _effets(golem)
	effets.process_mode = Node.PROCESS_MODE_DISABLED
	var onde: MeshInstance3D = effets.get_node("Shockwave") as MeshInstance3D
	assert_bool(onde.visible).is_false()
	var point: Vector3 = Vector3(2.0, 0.0, -5.0)
	golem.slammed.emit(point, 3.5)
	assert_bool(onde.visible).is_true()
	assert_vector(onde.global_position).is_equal_approx(point + Vector3(0.0, 0.05, 0.0), Vector3.ONE * 0.001)
	assert_float(onde.scale.x).is_equal_approx(3.5 * effets.settings.shockwave_reach, 0.001)
	for nom: String in ["SlamDust", "SlamDebris"]:
		var salve: GPUParticles3D = effets.get_node(nom) as GPUParticles3D
		assert_bool(salve.emitting).is_true()
		assert_vector(salve.global_position).is_equal_approx(point, Vector3.ONE * 0.001)
	effets.update(effets.settings.shockwave_time * 0.5)
	assert_float(effets.shockwave_progress).is_equal_approx(0.5, 0.001)
	effets.update(effets.settings.shockwave_time)
	assert_bool(onde.visible).is_false()


func test_pendant_la_fenetre_du_marteau_une_trainee_suit_sa_tete_puis_s_efface() -> void:
	var golem: Golem = _golem()
	var effets: GolemEffects = _effets(golem)
	effets.process_mode = Node.PROCESS_MODE_DISABLED
	golem.machine.process_mode = Node.PROCESS_MODE_DISABLED
	golem.attack = golem.choose_attack(3.0)
	golem.machine.transition_to(&"Attack")
	var state: GolemAttackState = golem.machine.current as GolemAttackState
	var avant: int = 0
	var pendant: int = 0
	while state.clip_time < golem.attack.strike_end:
		state.physics_update(DT)
		effets.update(DT)
		if state.clip_time < golem.attack.strike_start - effets.settings.trail_margin - 0.05:
			avant = maxi(avant, effets.trail_count)
		elif state.clip_time > golem.attack.strike_start:
			pendant = maxi(pendant, effets.trail_count)
	assert_int(avant).is_equal(0)
	assert_int(pendant).is_greater(3)
	golem.machine.transition_to(&"Recover")
	for _i: int in roundi(effets.settings.trail_time * 60.0) + 2:
		effets.update(DT)
	assert_int(effets.trail_count).is_equal(0)


func test_un_coup_qui_porte_fait_jaillir_des_etincelles_sur_le_heros() -> void:
	var golem: Golem = _golem()
	var etincelles: GPUParticles3D = _effets(golem).get_node("HitSparks") as GPUParticles3D
	golem.hammer.landed.emit(_mark, 0.0)
	assert_bool(etincelles.emitting).is_false()
	golem.slam_zone.landed.emit(_mark, 25.0)
	assert_bool(etincelles.emitting).is_true()
	assert_vector(etincelles.global_position).is_equal_approx(_mark.global_position + Vector3.UP, Vector3.ONE * 0.001)


func test_a_la_seconde_phase_les_jointures_s_allument_et_s_eteignent_a_sa_chute() -> void:
	var golem: Golem = _golem()
	var effets: GolemEffects = _effets(golem)
	assert_int(effets.armor_pieces.size()).is_equal(8)
	for piece: MeshInstance3D in effets.armor_pieces:
		assert_object(piece.material_overlay).is_same(effets.ember_material)
	assert_object(effets.ember_material).is_not_same(effets.ember)
	golem.enter_phase_two()
	await _process_frames(roundi(effets.settings.glow_time * 60.0) + 20)
	assert_float(effets.glow).is_equal_approx(effets.settings.glow_energy, 0.01)
	assert_float(float(effets.ember_material.get_shader_parameter(&"glow"))).is_greater(0.0)
	assert_float(ARMOR.emission_energy_multiplier).is_equal(0.0)
	golem.fall()
	await _process_frames(roundi(effets.settings.glow_time * 60.0) + 20)
	assert_float(effets.glow).is_equal_approx(0.0, 0.01)
	(golem.get_node("View") as GolemView).thrown_shield.queue_free()


func test_la_camera_tremble_a_un_impact_proche_pas_a_un_impact_lointain() -> void:
	var golem: Golem = _golem()
	var effets: GolemEffects = _effets(golem)
	var orbit: OrbitCamera = CAMERA.instantiate() as OrbitCamera
	orbit.get_node("Input").free()
	orbit.target = _mark
	add_child(auto_free(orbit))
	effets.camera = orbit
	golem.slammed.emit(orbit.global_position + Vector3(effets.settings.shake_range + 5.0, 0.0, 0.0), 3.5)
	assert_float(orbit.current_shake()).is_equal(0.0)
	golem.slammed.emit(orbit.global_position + Vector3(2.0, 0.0, 0.0), 3.5)
	assert_float(orbit.current_shake()).is_greater(effets.settings.slam_shake * 0.8)


func test_aucun_noeud_n_est_cree_pendant_un_coup() -> void:
	var golem: Golem = _golem()
	var effets: GolemEffects = _effets(golem)
	var avant: int = golem.find_children("*", "", true, false).size()
	golem.slammed.emit(Vector3(0.0, 0.0, -4.0), 3.5)
	golem.hammer.landed.emit(_mark, 30.0)
	for _i: int in 30:
		effets.update(DT)
	assert_int(golem.find_children("*", "", true, false).size()).is_equal(avant)
