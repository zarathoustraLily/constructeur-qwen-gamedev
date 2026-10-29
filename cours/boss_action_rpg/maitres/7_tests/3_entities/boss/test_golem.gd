extends GdUnitTestSuite
## Règles du golem, à cette étape : il est sur la couche du boss et regarde le monde et le héros ; il est quatre fois
## plus grand qu'un homme ; la zone qui reçoit les tirs passe les dégâts à sa santé ; le point verrouillé est dans le
## groupe des cibles, à hauteur de poitrine ; son modèle joue l'attente.
#@ 12+
## Le combat : il dort tant que le héros est loin, s'éveille quand il approche ou le touche ; il marche vers lui ; il
## choisit son coup selon la distance et la phase, sans répéter le même, et ne bondit pas si un mur barre le chemin ;
## son marteau ne frappe que dans sa fenêtre, au ras du sol grâce au penché du buste ; son corps suit le déplacement du
## clip, et son bond visé retombe sur sa cible ; un écrasement frappe dans son rayon, pas au-delà ; après son coup il
## récupère ; son dos prend double, son bouclier bloque ; à 70 % de sa vie, la seconde phase commence une fois
## (bouclier jeté, coups plus vifs, deux coups enchaînés) ; à zéro, il tombe.
#@ all

const GOLEM := preload("res://3_entities/boss/golem.tscn")


func _golem() -> Golem:
	var golem: Golem = auto_free(GOLEM.instantiate()) as Golem
	add_child(golem)
	return golem


func test_il_est_sur_sa_couche_et_regarde_le_monde_et_le_heros() -> void:
	var golem: Golem = _golem()
	assert_int(golem.collision_layer).is_equal(Layers.bit(Layers.BOSS))
	assert_bool(Layers.has(golem.collision_mask, Layers.WORLD)).is_true()
	assert_bool(Layers.has(golem.collision_mask, Layers.HERO)).is_true()


func test_il_est_quatre_fois_plus_grand_qu_un_homme() -> void:
	var golem: Golem = _golem()
	var model: Node3D = golem.get_node("Model") as Node3D
	var body: MeshInstance3D = model.get_node("Skeleton3D/Body_geo") as MeshInstance3D
	var hauteur: float = body.mesh.get_aabb().size.y * model.scale.y
	assert_float(hauteur).is_between(6.5, 8.0)


func test_ses_tirs_recus_vont_a_sa_sante() -> void:
	var golem: Golem = _golem()
	var hurtbox: Hurtbox = golem.get_node("Hurtbox") as Hurtbox
	assert_that(hurtbox.health).is_same(golem.health)
	assert_float(hurtbox.receive(30.0)).is_equal(30.0)
	assert_float(golem.health.health).is_equal(golem.health.settings.max_health - 30.0)


func test_le_point_verrouille_est_a_hauteur_de_poitrine() -> void:
	var golem: Golem = _golem()
	assert_bool(golem.lock_point.is_in_group(LockOn.GROUP)).is_true()
	assert_float(golem.lock_point.position.y).is_between(4.0, 6.0)


func test_son_modele_joue_l_attente() -> void:
	var golem: Golem = _golem()
	await get_tree().process_frame
	var animation: AnimationPlayer = golem.get_node("Model/AnimationPlayer") as AnimationPlayer
	assert_str(animation.current_animation).is_equal("idle1")
	assert_bool(animation.is_playing()).is_true()
#@ 12+


## Un corps de test sur la couche du héros, qui note les coups reçus.
class Victim extends CharacterBody3D:
	var hits: Array[float] = []

	func take_hit(amount: float, _from: Vector3) -> float:
		hits.append(amount)
		return amount


func _victime(at: Vector3) -> Victim:
	var victim: Victim = auto_free(Victim.new()) as Victim
	victim.collision_layer = Layers.bit(Layers.HERO)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.9, 0.0)
	victim.add_child(shape)
	victim.position = at
	add_child(victim)
	return victim


## Un golem face à `target` (devant lui, vers -Z).
func _combat(target: Node3D) -> Golem:
	var golem: Golem = _golem()
	golem.target = target
	return golem


## Une cible sans corps, posée en `at`.
func _repere(at: Vector3) -> Node3D:
	var mark: Node3D = auto_free(Node3D.new()) as Node3D
	mark.position = at
	add_child(mark)
	return mark


## Fait avancer la machine du golem de `seconds` secondes, image par image, sans attendre le moteur.
func _avancer(golem: Golem, seconds: float) -> void:
	golem.machine.process_mode = Node.PROCESS_MODE_DISABLED
	for _i: int in roundi(seconds * 60.0):
		golem.machine.current.physics_update(1.0 / 60.0)


func _attaque(id: StringName) -> GolemAttack:
	for a: GolemAttack in (load("res://5_data/boss/golem.tres") as GolemSettings).attacks:
		if a.id == id:
			return a
	return null


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_il_dort_tant_que_le_heros_est_loin_et_s_eveille_quand_il_approche() -> void:
	var mark: Node3D = _repere(Vector3(0.0, 0.0, -20.0))
	var golem: Golem = _combat(mark)
	var reveils: Array[int] = [0]
	golem.woke.connect(func() -> void: reveils[0] += 1)
	_avancer(golem, 1.0)
	assert_str(golem.machine.current.name).is_equal("Dormant")
	mark.position = Vector3(0.0, 0.0, -golem.settings.wake_distance + 1.0)
	_avancer(golem, 0.1)
	assert_str(golem.machine.current.name).is_equal("Wake")
	assert_int(reveils[0]).is_equal(1)


func test_un_tir_le_reveille() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -20.0)))
	(golem.get_node("Hurtbox") as Hurtbox).receive(12.0)
	assert_str(golem.machine.current.name).is_equal("Wake")


func test_reveille_il_marche_vers_le_heros() -> void:
	var mark: Node3D = _repere(Vector3(0.0, 0.0, -14.0))
	var golem: Golem = _combat(mark)
	golem.machine.transition_to(&"Wake")
	_avancer(golem, golem.settings.wake_time + 1.0)
	assert_str(golem.machine.current.name).is_equal("Approach")
	assert_float(golem.distance_to_target()).is_less(14.0 - golem.settings.walk_speed * 0.8)


func test_il_choisit_son_coup_selon_la_distance_et_la_phase_sans_le_repeter() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -20.0)))
	var premier: StringName = golem.choose_attack(3.0).id
	var second: StringName = golem.choose_attack(3.0).id
	assert_array([premier, second]).contains_exactly_in_any_order([&"sweep", &"backhand"])
	assert_str(golem.choose_attack(8.0).id).is_equal("crush")
	assert_object(golem.choose_attack(15.0)).is_null()
	golem.phase = 2
	assert_str(golem.choose_attack(15.0).id).is_equal("leap")


func test_il_ne_bondit_pas_si_un_mur_barre_le_chemin() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -15.0)))
	golem.phase = 2
	assert_str(golem.choose_attack(15.0).id).is_equal("leap")
	var mur: StaticBody3D = auto_free(StaticBody3D.new()) as StaticBody3D
	mur.collision_layer = Layers.bit(Layers.WORLD)
	var forme: CollisionShape3D = CollisionShape3D.new()
	var boite: BoxShape3D = BoxShape3D.new()
	boite.size = Vector3(10.0, 6.0, 0.5)
	forme.shape = boite
	mur.add_child(forme)
	mur.position = Vector3(0.0, 3.0, -8.0)
	add_child(mur)
	await get_tree().physics_frame
	assert_object(golem.choose_attack(15.0)).is_null()


func test_son_marteau_ne_frappe_que_dans_sa_fenetre() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -3.0)))
	golem.attack = _attaque(&"sweep")
	golem.machine.transition_to(&"Attack")
	golem.machine.process_mode = Node.PROCESS_MODE_DISABLED
	var state: GolemAttackState = golem.machine.current as GolemAttackState
	var actif: Array[float] = []
	while golem.machine.current == state:
		state.physics_update(1.0 / 60.0)
		if golem.hammer.active:
			actif.append(state.clip_time)
	assert_array(actif).is_not_empty()
	assert_float(actif.min()).is_greater_equal(golem.attack.strike_start)
	assert_float(actif.max()).is_less(golem.attack.strike_end)
	assert_bool(golem.hammer.active).is_false()


func test_son_corps_suit_le_deplacement_du_clip() -> void:
	var mark: Node3D = _repere(Vector3(0.0, 0.0, -15.0))
	var golem: Golem = _combat(mark)
	assert_vector(golem.root_offset(&"attack1", 1.0)).is_equal(Vector3.ZERO)
	var bond: Vector3 = golem.root_offset(&"attack5", golem.clip_length(&"attack5"))
	assert_float(bond.z).is_less(-14.0)
	assert_float(absf(bond.x)).is_less(0.5)
	golem.phase = 2
	golem.attack = _attaque(&"leap")
	golem.machine.transition_to(&"Attack")
	_avancer(golem, golem.clip_length(&"attack5") / golem.clip_speed() + 0.1)
	assert_float(golem.global_position.z).is_less(-12.0)


func test_son_bond_vise_retombe_sur_sa_cible() -> void:
	for distance: float in [10.0, 13.0, 16.0]:
		var mark: Node3D = _repere(Vector3(0.0, 0.0, -distance))
		var golem: Golem = _combat(mark)
		var impacts: Array[Vector3] = []
		golem.slammed.connect(func(point: Vector3, _radius: float) -> void: impacts.append(point))
		golem.phase = 2
		golem.attack = _attaque(&"leap")
		golem.machine.transition_to(&"Attack")
		_avancer(golem, golem.clip_length(&"attack5") / golem.clip_speed() + 0.1)
		assert_int(impacts.size()).is_equal(1)
		assert_float(impacts[0].distance_to(mark.global_position)).is_less(3.0)


func test_un_ecrasement_frappe_dans_son_rayon_pas_au_dela() -> void:
	var proche: Victim = _victime(Vector3(0.0, 0.0, -8.0))
	var loin: Victim = _victime(Vector3(9.0, 0.0, -8.0))
	var golem: Golem = _combat(proche)
	var impacts: Array[float] = []
	golem.slammed.connect(func(_point: Vector3, radius: float) -> void: impacts.append(radius))
	golem.attack = _attaque(&"crush")
	golem.machine.transition_to(&"Attack")
	await _frames(roundi(golem.clip_length(&"attack4") * 60.0) + 5)
	assert_array(impacts).is_equal([golem.attack.slam_radius])
	assert_array(proche.hits).contains([golem.attack.slam_damage])
	assert_array(loin.hits).is_empty()


func test_apres_son_coup_il_recupere_puis_revient() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -3.0)))
	golem.attack = _attaque(&"sweep")
	golem.machine.transition_to(&"Attack")
	_avancer(golem, golem.clip_length(&"attack1") + 0.05)
	assert_str(golem.machine.current.name).is_equal("Recover")
	var cap: float = golem.rotation.y
	golem.target.position = Vector3(10.0, 0.0, 0.0)
	_avancer(golem, golem.attack.recover - 0.1)
	assert_float(golem.rotation.y).is_equal(cap)
	_avancer(golem, 0.2)
	assert_str(golem.machine.current.name).is_not_equal("Recover")


func test_son_dos_prend_double_et_son_bouclier_bloque() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -20.0)))
	assert_float((golem.get_node("BackWeakPoint") as Hurtbox).receive(10.0)).is_equal(20.0)
	assert_float(golem.shield.receive(10.0)).is_equal(0.0)
	assert_float((golem.get_node("Hurtbox") as Hurtbox).receive(10.0)).is_equal(10.0)
	assert_int(golem.shield.collision_layer).is_equal(Layers.bit(Layers.TARGETS))


func test_a_70_pourcent_de_sa_vie_la_seconde_phase_commence_une_fois() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -20.0)))
	var phases: Array[int] = []
	golem.phase_changed.connect(func(p: int) -> void: phases.append(p))
	golem.health.take_damage(golem.health.settings.max_health * 0.29)
	assert_int(golem.phase).is_equal(1)
	golem.health.take_damage(golem.health.settings.max_health * 0.02)
	assert_str(golem.machine.current.name).is_equal("PhaseShift")
	golem.health.take_damage(50.0)
	assert_array(phases).is_equal([2])
	assert_int(golem.shield.collision_layer).is_equal(0)
	assert_float(golem.clip_speed()).is_greater(1.0)


func test_en_seconde_phase_il_enchaine_deux_coups_avant_de_recuperer() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -3.0)))
	golem.enter_phase_two()
	golem.attack = golem.choose_attack(golem.distance_to_target())
	assert_str(golem.attack.id).is_equal("sweep")
	golem.machine.transition_to(&"Attack")
	_avancer(golem, golem.clip_length(&"attack1") / golem.clip_speed() + 0.05)
	assert_str(golem.machine.current.name).is_equal("Attack")
	assert_str(golem.attack.id).is_equal("backhand")
	_avancer(golem, golem.clip_length(&"attack2") / golem.clip_speed() + 0.05)
	assert_str(golem.machine.current.name).is_equal("Recover")


func test_a_zero_il_tombe() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -3.0)))
	var chutes: Array[int] = [0]
	golem.defeated.connect(func() -> void: chutes[0] += 1)
	golem.attack = _attaque(&"sweep")
	golem.machine.transition_to(&"Attack")
	golem.health.take_damage(golem.health.settings.max_health)
	assert_str(golem.machine.current.name).is_equal("Dead")
	assert_int(chutes[0]).is_equal(1)
	assert_bool(golem.hammer.active).is_false()
	assert_int((golem.get_node("Hurtbox") as Hurtbox).collision_layer).is_equal(0)
	assert_int((golem.get_node("BackWeakPoint") as Hurtbox).collision_layer).is_equal(0)


func test_sa_vue_penche_son_buste_et_son_marteau_passe_au_ras_du_sol() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -3.0)))
	golem.attack = _attaque(&"sweep")
	golem.machine.transition_to(&"Attack")
	var player: AnimationPlayer = golem.get_node("Model/AnimationPlayer") as AnimationPlayer
	var bend: GolemStrikeModifier = golem.get_node("Model/Skeleton3D/StrikeBend") as GolemStrikeModifier
	var shape: Node3D = golem.get_node("Model/Skeleton3D/WeaponR/HammerHit/Shape") as Node3D
	var plus_bas: float = INF
	for _i: int in 80:
		await get_tree().physics_frame
		await get_tree().process_frame
		var t: float = player.current_animation_position
		if t >= golem.attack.strike_start and t < golem.attack.strike_end:
			assert_float(bend.bend).is_equal_approx(golem.attack.bend, 0.01)
			plus_bas = minf(plus_bas, shape.global_position.y)
	assert_str(player.current_animation).is_equal("attack1")
	assert_float(plus_bas).is_less(1.8)


func test_a_la_seconde_phase_il_jette_son_bouclier() -> void:
	var golem: Golem = _combat(_repere(Vector3(0.0, 0.0, -20.0)))
	await _frames(2)
	golem.health.take_damage(golem.health.settings.max_health * 0.31)
	var view: GolemView = golem.get_node("View") as GolemView
	assert_object(view.thrown_shield).is_not_null()
	assert_bool(golem.is_ancestor_of(view.thrown_shield)).is_false()
	await _frames(60)
	assert_float(view.thrown_shield.global_position.y).is_less(1.0)
	view.thrown_shield.queue_free()
#@ all
