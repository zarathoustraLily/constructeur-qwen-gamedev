extends GdUnitTestSuite
## Règles de la vue du héros (le soldat animé) : le modèle a le squelette reciblé (os du profil humanoïde) et tient
## le fusil dans la main droite ; la bibliothèque a chaque clip, et aucun ne garde l'os Root (le code déplace le
## corps) ; au départ, la vue montre la course ; chaque état du héros (Roll, Hit, Heal, Dead) montre son animation,
## et le retour à Move remontre la course ; la roulade dure ce que dure l'état, le soin aussi ; course, sprint et
## marche visée jouent à la vitesse du corps (les pieds ne glissent pas) ; la vitesse au sol règle le mélange de
## course ; en visant, la course passe à la marche visée en un temps donné, et revient en lâchant ; un tir joue le
## recul du haut du corps seulement ; la bouche de l'arme du héros suit celle du fusil.

const HERO := preload("res://3_entities/hero/hero.tscn")
const CLIPS: Array[StringName] = [&"idle", &"aim_idle", &"aim_walk_f", &"aim_walk_b", &"aim_walk_l", &"aim_walk_r",
		&"run", &"sprint", &"fire", &"roll", &"hit", &"heal", &"death"]

var _world: Node3D


func before_test() -> void:
	_world = auto_free(Node3D.new())
	var floor_body: StaticBody3D = StaticBody3D.new()
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(shape)
	_world.add_child(floor_body)
	add_child(_world)


func _hero() -> Hero:
	var hero: Hero = HERO.instantiate() as Hero
	hero.get_node("Input").free()
	hero.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(hero)
	return hero


func _view(hero: Hero) -> HeroView:
	return hero.get_node("View") as HeroView


func _shown(view: HeroView) -> StringName:
	view.tree.advance(0.0)
	return view.tree.get(&"parameters/state/current_state") as StringName


func _clip_node(view: HeroView, clip: StringName) -> AnimationNodeAnimation:
	var root: AnimationNodeBlendTree = view.tree.tree_root as AnimationNodeBlendTree
	return root.get_node(clip) as AnimationNodeAnimation


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_le_modele_a_le_squelette_recible_et_le_fusil_en_main_droite() -> void:
	var view: HeroView = _view(_hero())
	var skeleton: Skeleton3D = view.model.get_node(^"%GeneralSkeleton") as Skeleton3D
	for bone: String in ["Hips", "Spine", "Head", "RightHand", "LeftFoot"]:
		assert_int(skeleton.find_bone(bone)).override_failure_message("os absent : " + bone).is_greater_equal(0)
	await _frames(2)
	var hand: Vector3 = skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("RightHand")).origin)
	assert_float(view.muzzle.global_position.distance_to(hand)).is_less(0.9)


func test_chaque_clip_est_dans_la_bibliotheque_sans_os_root() -> void:
	var view: HeroView = _view(_hero())
	var player: AnimationPlayer = view.model.get_node(^"AnimationPlayer") as AnimationPlayer
	for clip: StringName in CLIPS:
		assert_bool(player.has_animation(clip)).override_failure_message("clip absent : " + clip).is_true()
		var animation: Animation = player.get_animation(clip)
		for t: int in animation.get_track_count():
			assert_str(String(animation.track_get_path(t))).is_not_equal("%GeneralSkeleton:Root")


func test_au_depart_la_vue_montre_la_course() -> void:
	var view: HeroView = _view(_hero())
	assert_str(_shown(view)).is_equal("move")


func test_chaque_etat_montre_son_animation() -> void:
	var hero: Hero = _hero()
	var view: HeroView = _view(hero)
	for state: StringName in [&"Roll", &"Hit", &"Heal", &"Dead"]:
		hero.machine.transition_to(state)
		assert_str(_shown(view)).is_equal(HeroView.STATES[state])
		hero.machine.transition_to(&"Move")
		assert_str(_shown(view)).is_equal("move")


func test_la_roulade_et_le_soin_durent_ce_que_durent_leurs_etats() -> void:
	var hero: Hero = _hero()
	var view: HeroView = _view(hero)
	var roll: AnimationNodeAnimation = _clip_node(view, &"roll")
	assert_bool(roll.use_custom_timeline and roll.stretch_time_scale).is_true()
	assert_float(roll.timeline_length).is_equal_approx(hero.settings.roll_duration, 0.0001)
	var heal: AnimationNodeAnimation = _clip_node(view, &"heal")
	assert_bool(heal.use_custom_timeline and heal.stretch_time_scale).is_true()
	assert_float(heal.timeline_length).is_equal_approx(hero.settings.heal_duration, 0.0001)


func test_course_sprint_et_marche_visee_jouent_a_la_vitesse_du_corps() -> void:
	var hero: Hero = _hero()
	var view: HeroView = _view(hero)
	var player: AnimationPlayer = view.model.get_node(^"AnimationPlayer") as AnimationPlayer
	var cases: Dictionary[StringName, Vector2] = {
		&"run": Vector2(view.settings.run_clip_speed, hero.settings.run_speed),
		&"sprint": Vector2(view.settings.sprint_clip_speed, hero.settings.sprint_speed),
		&"aim_walk_f": Vector2(view.settings.aim_walk_clip_speed, hero.settings.aim_speed),
	}
	for clip: StringName in cases:
		var node: AnimationNodeAnimation = view.clip_nodes[clip]
		var expected: float = player.get_animation(clip).length * cases[clip].x / cases[clip].y
		assert_bool(node.stretch_time_scale).is_true()
		assert_float(node.timeline_length).override_failure_message(String(clip)).is_equal_approx(expected, 0.0001)


func test_la_vitesse_au_sol_regle_le_melange_de_course() -> void:
	var hero: Hero = _hero()
	var view: HeroView = _view(hero)
	hero.velocity = Vector3(3.0, -2.0, -4.0)
	view.update(1.0 / 60.0)
	assert_float(view.tree.get(&"parameters/locomotion/blend_position") as float).is_equal_approx(5.0, 0.001)


func test_en_visant_la_course_passe_a_la_marche_visee_puis_revient() -> void:
	var hero: Hero = _hero()
	var view: HeroView = _view(hero)
	var step: float = 1.0 / 60.0
	hero.aiming = true
	view.update(view.settings.aim_blend_time / 2.0)
	assert_float(view.tree.get(&"parameters/aim/blend_amount") as float).is_equal_approx(0.5, 0.001)
	view.update(view.settings.aim_blend_time)
	assert_float(view.tree.get(&"parameters/aim/blend_amount") as float).is_equal_approx(1.0, 0.001)
	hero.aiming = false
	for _i: int in ceili(view.settings.aim_blend_time / step) + 1:
		view.update(step)
	assert_float(view.tree.get(&"parameters/aim/blend_amount") as float).is_equal_approx(0.0, 0.001)


func test_un_tir_joue_le_recul_du_haut_du_corps_seulement() -> void:
	var hero: Hero = _hero()
	var view: HeroView = _view(hero)
	hero.gun.fired.emit(Vector3.ZERO, Vector3.FORWARD)
	view.tree.advance(1.0 / 60.0)
	assert_bool(view.tree.get(&"parameters/fire/active") as bool).is_true()
	var fire: AnimationNodeOneShot = (view.tree.tree_root as AnimationNodeBlendTree).get_node(&"fire") as AnimationNodeOneShot
	assert_bool(fire.filter_enabled).is_true()
	assert_bool(fire.is_path_filtered(^"%GeneralSkeleton:Spine")).is_true()
	assert_bool(fire.is_path_filtered(^"%GeneralSkeleton:RightHand")).is_true()
	assert_bool(fire.is_path_filtered(^"%GeneralSkeleton:Hips")).is_false()
	assert_bool(fire.is_path_filtered(^"%GeneralSkeleton:LeftFoot")).is_false()


func test_la_bouche_de_l_arme_suit_celle_du_fusil() -> void:
	var hero: Hero = _hero()
	var view: HeroView = _view(hero)
	hero.machine.transition_to(&"Roll")
	await _frames(12)
	assert_float(hero.gun.global_position.distance_to(view.muzzle.global_position)).is_less(0.001)
