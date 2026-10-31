extends GdUnitTestSuite
## Règles de la magie du Gardien. Il lance des boules de feu de loin, pas de près, et attend entre deux ; ses éclairs
## n'existent qu'en seconde phase. Un sort s'annonce avant de partir : la boule grandit dans sa main, le sol est marqué, et
## le temps de voir venir est mesuré. La boule file vers sa cible, la suit un peu, explose près d'elle ou contre le décor ;
## l'explosion frappe à portée, pas au-delà, ni un héros qui roule. En seconde phase, une salve en éventail. Les éclairs
## marquent le sol sous la cible et de chaque côté, frappent depuis le marteau, seulement dans leur rayon et un instant.
## Un sort interrompu s'efface. Tout est préparé d'avance : aucun nœud créé. Éveillé, il a son aura ; plus forte en
## seconde phase ; éteinte à sa chute.

const GOLEM := preload("res://3_entities/boss/golem.tscn")
const DT: float = 1.0 / 60.0


## Une cible qui compte les coups reçus, comme le héros : `take_hit(montant, origine)`.
class Cible extends Node3D:
	var coups: Array[float] = []
	var invulnerable: bool = false

	func take_hit(amount: float, _from: Vector3) -> float:
		if invulnerable:
			return 0.0
		coups.append(amount)
		return amount


func _cible(at: Vector3) -> Cible:
	var cible: Cible = auto_free(Cible.new()) as Cible
	cible.position = at
	add_child(cible)
	return cible


func _golem(cible: Node3D) -> Golem:
	var golem: Golem = auto_free(GOLEM.instantiate()) as Golem
	golem.target = cible
	add_child(golem)
	return golem


func _sorts(golem: Golem) -> GolemSpells:
	return golem.get_node("Spells") as GolemSpells


func _attaque(golem: Golem, id: StringName) -> GolemAttack:
	for a: GolemAttack in golem.settings.attacks:
		if a.id == id:
			return a
	return null


## Joue l'attaque `id` : la machine du golem à la main, `seconds` secondes de clip au plus, image par image.
func _jouer(golem: Golem, id: StringName, seconds: float) -> void:
	golem.machine.process_mode = Node.PROCESS_MODE_DISABLED
	golem.attack = _attaque(golem, id)
	golem.machine.transition_to(&"Attack")
	var etat: GolemAttackState = golem.machine.current as GolemAttackState
	var sorts: GolemSpells = _sorts(golem)
	for _i: int in roundi(seconds * 60.0):
		if golem.machine.current != etat:
			return
		etat.physics_update(DT)
		sorts.update(DT)


func test_il_lance_ses_boules_de_loin_pas_de_pres_et_attend_entre_deux() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	assert_object(golem.choose_attack(3.0).spell).is_equal(&"")
	var sort: GolemAttack = golem.choose_attack(25.0)
	assert_str(sort.id).is_equal("fireball")
	assert_object(golem.choose_attack(25.0)).is_null()
	golem._physics_process(sort.cooldown + 0.1)
	assert_str(golem.choose_attack(25.0).id).is_equal("fireball")


func test_ses_eclairs_n_existent_qu_en_seconde_phase() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	var eclairs: GolemAttack = _attaque(golem, &"lightning")
	assert_bool(eclairs.allowed(25.0, 1)).is_false()
	assert_bool(eclairs.allowed(25.0, 2)).is_true()


func test_un_sort_s_annonce_assez_tot_pour_etre_esquive() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	for id: StringName in [&"fireball", &"lightning"]:
		var sort: GolemAttack = _attaque(golem, id)
		var annonce: float = (sort.cast_time - sort.charge_start) / sort.clip_rate
		assert_float(annonce).is_greater(1.0)
		assert_float(sort.cast_time).is_less(golem.clip_length(sort.clip))


func test_la_boule_grandit_dans_sa_main_puis_part_vers_sa_cible() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	var sorts: GolemSpells = _sorts(golem)
	var sort: GolemAttack = _attaque(golem, &"fireball")
	var lancers: Array[int] = [0]
	sorts.ball_thrown.connect(func(_at: Vector3) -> void: lancers[0] += 1)
	assert_object(sorts.held).is_null()
	_jouer(golem, &"fireball", (sort.charge_start + (sort.cast_time - sort.charge_start) * 0.5) / sort.clip_rate)
	assert_object(sorts.held).is_not_null()
	assert_bool(sorts.held.visible).is_true()
	assert_float(sorts.charge).is_between(0.3, 0.7)
	assert_int(lancers[0]).is_equal(0)
	var boule: Fireball = sorts.held
	var etat: GolemAttackState = golem.machine.current as GolemAttackState
	while etat.clip_time < sort.cast_time:
		etat.physics_update(DT)
		sorts.update(DT)
	assert_int(lancers[0]).is_equal(1)
	assert_bool(boule.active).is_true()
	assert_object(sorts.held).is_null()


func test_la_boule_touche_sa_cible_et_l_explosion_la_frappe() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -30.0)))
	var cible: Cible = _cible(Vector3(0.0, 0.0, -8.0))
	var boule: Fireball = _sorts(golem).balls[0]
	var points: Array[Vector3] = []
	boule.exploded.connect(func(point: Vector3) -> void: points.append(point))
	boule.launch(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, cible, 22.0)
	for _i: int in 90:
		boule.advance(DT)
	assert_bool(boule.active).is_false()
	assert_int(points.size()).is_equal(1)
	assert_array(cible.coups).is_equal([22.0])


func test_l_explosion_ne_frappe_ni_au_dela_de_sa_portee_ni_un_heros_qui_roule() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -30.0)))
	var loin: Cible = _cible(Vector3(30.0, 0.0, 0.0))
	var boule: Fireball = _sorts(golem).balls[0]
	boule.settings = boule.settings.duplicate() as GolemSpellSettings
	boule.settings.ball_turn = 0.0
	boule.settings.ball_life = 0.2
	boule.launch(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, loin, 22.0)
	for _i: int in 30:
		boule.advance(DT)
	assert_bool(boule.active).is_false()
	assert_array(loin.coups).is_empty()
	var roule: Cible = _cible(Vector3(0.0, 0.0, -3.0))
	roule.invulnerable = true
	boule.settings.ball_life = 5.0
	boule.launch(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, roule, 22.0)
	for _i: int in 30:
		boule.advance(DT)
	assert_bool(boule.active).is_false()
	assert_array(roule.coups).is_empty()


func test_la_boule_suit_un_peu_sa_cible_assez_peu_pour_qu_une_roulade_l_evite() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -30.0)))
	var cible: Cible = _cible(Vector3(0.0, 0.0, -30.0))
	var boule: Fireball = _sorts(golem).balls[0]
	boule.launch(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, cible, 22.0)
	cible.position.x = 12.0
	for _i: int in 60:
		boule.advance(DT)
	assert_float(boule.global_position.x).is_between(0.5, 6.0)


func test_le_decor_l_arrete_sans_toucher_la_cible() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -30.0)))
	var cible: Cible = _cible(Vector3(0.0, 0.0, -20.0))
	var mur: StaticBody3D = auto_free(StaticBody3D.new()) as StaticBody3D
	mur.collision_layer = Layers.bit(Layers.WORLD)
	var forme: CollisionShape3D = CollisionShape3D.new()
	var boite: BoxShape3D = BoxShape3D.new()
	boite.size = Vector3(20.0, 20.0, 0.5)
	forme.shape = boite
	mur.add_child(forme)
	mur.position = Vector3(0.0, 0.0, -8.0)
	add_child(mur)
	await get_tree().physics_frame
	var boule: Fireball = _sorts(golem).balls[0]
	var points: Array[Vector3] = []
	boule.exploded.connect(func(point: Vector3) -> void: points.append(point))
	boule.launch(Vector3(0.0, 1.0, 0.0), Vector3.FORWARD, cible, 22.0)
	for _i: int in 90:
		boule.advance(DT)
	assert_int(points.size()).is_equal(1)
	assert_float(points[0].z).is_equal_approx(-7.75, 0.05)
	assert_array(cible.coups).is_empty()


func test_chaque_explosion_joue_sa_salve_au_point_touche() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -30.0)))
	var sorts: GolemSpells = _sorts(golem)
	var point: Vector3 = Vector3(2.0, 1.0, -3.0)
	sorts.balls[0].exploded.emit(point)
	var salve: VfxBurst = sorts.get_node("Blast1") as VfxBurst
	assert_bool(salve.visible).is_true()
	assert_vector(salve.global_position).is_equal_approx(point, Vector3.ONE * 0.001)
	assert_float(salve.light_energy).is_greater(0.0)


func test_en_seconde_phase_une_salve_en_eventail() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	golem.phase = 2
	var sorts: GolemSpells = _sorts(golem)
	var sort: GolemAttack = _attaque(golem, &"fireball")
	_jouer(golem, &"fireball", (sort.cast_time + 0.05) / (sort.clip_rate * golem.clip_speed()))
	var parties: Array[Fireball] = []
	for boule: Fireball in sorts.balls:
		if boule.active:
			parties.append(boule)
	assert_int(parties.size()).is_equal(sorts.settings.phase_two_balls)
	for _i: int in 20:
		for boule: Fireball in parties:
			boule.advance(DT)
	var ecart: float = absf(parties[1].global_position.x - parties[2].global_position.x)
	assert_float(ecart).is_greater(1.0)


func test_les_eclairs_marquent_le_sol_sous_la_cible_et_de_chaque_cote_puis_frappent() -> void:
	var cible: Cible = _cible(Vector3(0.0, 0.0, -20.0))
	var golem: Golem = _golem(cible)
	golem.phase = 2
	var sorts: GolemSpells = _sorts(golem)
	var sort: GolemAttack = _attaque(golem, &"lightning")
	var coups: Array[Vector3] = []
	sorts.lightning_struck.connect(func(point: Vector3) -> void: coups.append(point))
	_jouer(golem, &"lightning", (sort.charge_start + 0.1) / (sort.clip_rate * golem.clip_speed()))
	var premier: GolemLightning = sorts.bolts[0]
	assert_bool(premier.marked).is_true()
	assert_bool((premier.get_node("Ring") as Node3D).visible).is_true()
	assert_vector(premier.global_position).is_equal_approx(Vector3(0.0, 0.0, -20.0), Vector3.ONE * 0.01)
	var ecart: float = sorts.bolts[1].global_position.distance_to(sorts.bolts[2].global_position)
	assert_float(ecart).is_equal_approx(sorts.settings.lightning_spread * 2.0, 0.01)
	assert_array(coups).is_empty()
	var etat: GolemAttackState = golem.machine.current as GolemAttackState
	while etat.clip_time < sort.cast_time:
		etat.physics_update(DT)
	assert_int(coups.size()).is_equal(3)
	assert_bool(premier.striking).is_true()
	assert_bool(premier.zone.active).is_true()
	assert_bool((premier.get_node("Ring") as Node3D).visible).is_false()


func test_la_zone_d_un_eclair_ne_reste_allumee_qu_un_instant() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -20.0)))
	var eclair: GolemLightning = _sorts(golem).bolts[0]
	eclair.mark(Vector3(0.0, 0.0, -20.0), 0.5)
	eclair.strike(Vector3(0.0, 5.0, 0.0), 18.0)
	assert_bool(eclair.zone.active).is_true()
	eclair.update(eclair.settings.zone_time + 0.01)
	assert_bool(eclair.zone.active).is_false()
	assert_bool(eclair.striking).is_true()
	eclair.update(eclair.settings.bolt_time)
	assert_bool(eclair.striking).is_false()
	assert_bool((eclair.get_node("Bolt") as Node3D).visible).is_false()


func test_un_sort_interrompu_s_efface() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	var sorts: GolemSpells = _sorts(golem)
	_jouer(golem, &"fireball", 0.6)
	var boule: Fireball = sorts.held
	assert_object(boule).is_not_null()
	golem.machine.transition_to(&"Dead")
	assert_object(sorts.held).is_null()
	assert_bool(boule.visible).is_false()
	assert_bool(boule.is_free()).is_true()


func test_tout_est_prepare_d_avance_et_cache() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	var sorts: GolemSpells = _sorts(golem)
	assert_int(sorts.balls.size()).is_greater_equal(sorts.settings.phase_two_balls)
	assert_int(sorts.bolts.size()).is_greater_equal(_attaque(golem, &"lightning").spell_count)
	for boule: Fireball in sorts.balls:
		assert_bool(boule.visible).is_false()
		assert_bool(boule.is_free()).is_true()
	var avant: int = golem.find_children("*", "", true, false).size()
	_jouer(golem, &"fireball", 2.0)
	assert_int(golem.find_children("*", "", true, false).size()).is_equal(avant)


func test_eveille_il_a_son_aura_plus_forte_en_seconde_phase_eteinte_a_sa_chute() -> void:
	var golem: Golem = _golem(_cible(Vector3(0.0, 0.0, -25.0)))
	var effets: GolemEffects = golem.get_node("Effects") as GolemEffects
	var braises: GPUParticles3D = effets.get_node("AuraEmbers") as GPUParticles3D
	effets.process_mode = Node.PROCESS_MODE_DISABLED
	assert_bool(braises.emitting).is_false()
	effets.update(1.0)
	assert_float(effets.aura).is_equal(0.0)
	golem.wake_up()
	assert_bool(braises.emitting).is_true()
	for _i: int in 240:
		effets.update(DT)
	assert_float(effets.aura).is_equal_approx(effets.settings.aura_first, 0.01)
	assert_float(braises.amount_ratio).is_equal_approx(effets.settings.embers_first, 0.001)
	assert_float(float(effets.ember_material.get_shader_parameter(&"aura"))).is_greater(0.0)
	assert_bool((effets.get_node("AuraLight") as Light3D).visible).is_true()
	golem.enter_phase_two()
	for _i: int in 240:
		effets.update(DT)
	assert_float(effets.aura).is_equal_approx(effets.settings.aura_second, 0.01)
	assert_float(braises.amount_ratio).is_equal(1.0)
	golem.fall()
	for _i: int in 240:
		effets.update(DT)
	assert_float(effets.aura).is_equal_approx(0.0, 0.01)
	assert_bool(braises.emitting).is_false()
	assert_bool((effets.get_node("AuraLight") as Light3D).visible).is_false()
	(golem.get_node("View") as GolemView).thrown_shield.queue_free()
