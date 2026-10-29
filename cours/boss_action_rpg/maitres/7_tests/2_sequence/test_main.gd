extends GdUnitTestSuite
#@ 1-6
## Règles de la scène principale : elle se charge ; elle a un sol avec sa collision, une lumière qui fait des ombres,
## un ciel, et sa caméra est la caméra active.
#@ 7+
## Règles de la scène principale : elle se charge ; le saloon a sa collision et le héros se pose sur son plancher ;
## l'ambiance a sa lune qui fait des ombres, son brouillard et sa brume au sol ; sa caméra est la caméra active.
#@ 5-6
## Le héros a sa réserve de projectiles et sa caméra de visée ; la cible reçoit les tirs ; tirer sur elle lui retire
## de la vie.
#@ 7+
## Le héros a sa réserve de projectiles et sa caméra de visée ; le golem reçoit les tirs et se verrouille ; tirer sur
## lui lui retire de la vie.
#@ 6+
## Quand le héros tombe, le niveau recommence après le délai de la rencontre.
#@ 9+
## L'interface est branchée : un coup au héros baisse sa vie, un tir chauffe l'arme, une fiole bue se compte, un coup au
## golem baisse sa jauge (montrée à son nom) ; la chute montre l'écran de chute.
#@ 10+
## La carboglace est une nappe posée sur le plancher, plus basse que le héros, faite par le shader de brouillard, avec
## son bruit et sa dérive.
#@ 11
## Trois spectres dorment au départ ; quand la vie du golem passe sous le seuil, ils sortent tous et chassent le héros.
#@ 12+
## La jauge du boss n'apparaît qu'à son réveil. Trois spectres dorment au départ ; quand la seconde phase du golem
## commence (il a perdu 30 % de sa vie), ils sortent tous et chassent le héros.
#@ 13+
## Les effets du golem font trembler la caméra du héros ; les étincelles montrent les impacts de ses tirs.
#@ all

const MAIN := preload("res://2_sequence/main.tscn")


func _main() -> Node3D:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	return main


#@ 1-6
func test_un_sol_avec_sa_collision() -> void:
	var main: Node3D = _main()
	var floor_body: StaticBody3D = main.get_node("Floor") as StaticBody3D
	assert_object(floor_body).is_not_null()
	assert_object((floor_body.get_node("Shape") as CollisionShape3D).shape).is_not_null()


func test_une_lumiere_qui_fait_des_ombres_et_un_ciel() -> void:
	var main: Node3D = _main()
	assert_bool((main.get_node("Sun") as DirectionalLight3D).shadow_enabled).is_true()
	assert_int((main.get_node("World") as WorldEnvironment).environment.background_mode).is_equal(Environment.BG_SKY)
#@ 7+
func test_le_saloon_a_sa_collision_et_le_heros_se_pose_sur_son_plancher() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var shape: Shape3D = (main.get_node("Saloon/Collision/Shape") as CollisionShape3D).shape
	assert_object(shape as ConcavePolygonShape3D).is_not_null()
	var hero: Hero = main.get_node("Hero") as Hero
	hero.get_node("Input").free()
	for _i: int in 30:
		await get_tree().physics_frame
	assert_bool(hero.is_on_floor()).is_true()
	assert_float(absf(hero.global_position.y)).is_less(0.3)


func test_une_lune_qui_fait_des_ombres_un_brouillard_et_une_brume_au_sol() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	assert_bool((main.get_node("Moon") as DirectionalLight3D).shadow_enabled).is_true()
	assert_bool((main.get_node("World") as WorldEnvironment).environment.volumetric_fog_enabled).is_true()
	var mist: FogVolume = main.get_node("GroundMist") as FogVolume
#@ 7-9
	assert_object(mist.material as FogMaterial).is_not_null()
#@ 10+
	assert_object(mist.material as ShaderMaterial).is_not_null()
#@ 7+
	assert_float(mist.global_position.y - mist.size.y / 2.0).is_less_equal(0.0)
#@ all


func test_sa_camera_est_active() -> void:
	var main: Node3D = _main()
#@ 1-2
	assert_that(main.get_viewport().get_camera_3d()).is_same(main.get_node("Camera"))
#@ 3+
	assert_that(main.get_viewport().get_camera_3d()).is_same(main.get_node("OrbitCamera/Arm/Camera"))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
#@ all
#@ 3+


func test_le_heros_court_par_rapport_a_la_camera_qui_le_suit() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	assert_that((main.get_node("Hero") as Hero).camera).is_same(main.get_node("OrbitCamera"))
	assert_that((main.get_node("OrbitCamera") as OrbitCamera).target).is_same(main.get_node("Hero"))
#@ 3-6
	assert_bool(main.get_node("Target").is_in_group(LockOn.GROUP)).is_true()
#@ 7+
	assert_bool(main.get_node("Golem/LockPoint").is_in_group(LockOn.GROUP)).is_true()
#@ 3+
#@ all
#@ 5+


func test_le_heros_a_sa_reserve_et_sa_camera_de_visee() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var hero: Hero = main.get_node("Hero") as Hero
	var pool: ProjectilePool = main.get_node("Projectiles") as ProjectilePool
	assert_that(hero.projectiles).is_same(pool)
	assert_that(hero.gun.pool).is_same(pool)
	assert_int(pool.available()).is_equal(pool.size)
	assert_that(hero.aim_camera).is_same(main.get_node("OrbitCamera/Arm/Camera"))
#@ 5-6
	assert_that((main.get_node("Target/Hurtbox") as Hurtbox).health).is_same(main.get_node("Target/Health"))
#@ 7+
	assert_that((main.get_node("Golem/Hurtbox") as Hurtbox).health).is_same(main.get_node("Golem/Health"))
#@ 5+


#@ 5-6
func test_tirer_sur_la_cible_lui_retire_de_la_vie() -> void:
#@ 7+
func test_tirer_sur_le_golem_lui_retire_de_la_vie() -> void:
#@ 5+
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var hero: Hero = main.get_node("Hero") as Hero
	var orbit: OrbitCamera = main.get_node("OrbitCamera") as OrbitCamera
	hero.get_node("Input").free()
	orbit.get_node("Input").free()
	orbit.pitch = 0.0
	orbit.apply_rotation()
	for _i: int in 10:
		await get_tree().physics_frame
	hero.trigger = true
	for _i: int in 30:
		await get_tree().physics_frame
	hero.trigger = false
#@ 5-6
	var health: HealthComponent = main.get_node("Target/Health") as HealthComponent
#@ 7+
	var health: HealthComponent = main.get_node("Golem/Health") as HealthComponent
#@ 5+
	assert_float(health.health).is_less(health.settings.max_health)
#@ all
#@ 6+


func test_quand_le_heros_tombe_le_niveau_recommence_apres_un_delai() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var timer: Timer = main.get_node("RestartTimer") as Timer
	assert_bool(timer.is_stopped()).is_true()
	(main.get_node("Hero") as Hero).take_hit(1000.0, Vector3.ZERO)
	assert_bool(timer.is_stopped()).is_false()
	assert_float(timer.wait_time).is_equal(3.0)
	timer.stop()
#@ all
#@ 9+


func test_l_interface_suit_le_heros_et_le_golem() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var hud: Hud = main.get_node("Hud") as Hud
	var hero: Hero = main.get_node("Hero") as Hero
	hero.take_hit(20.0, Vector3.ZERO)
	assert_float(hud.health_bar.ratio).is_less(1.0)
	hero.gun.heat.add(30.0)
	assert_float(hud.heat_bar.ratio).is_greater(0.0)
	hero.flasks.use()
	assert_int(hud.flasks.charges).is_equal(hero.settings.flask_count - 1)
#@ 9-11
	assert_bool(hud.boss_bar.visible).is_true()
#@ 12+
	assert_bool(hud.boss_bar.visible).is_false()
#@ 9+
	(main.get_node("Golem/Hurtbox") as Hurtbox).receive(150.0)
#@ 12+
	assert_bool(hud.boss_bar.visible).is_true()
#@ 9+
	assert_float(hud.boss_bar.bar.ratio).is_less(1.0)


func test_la_chute_montre_l_ecran_de_chute() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	(main.get_node("Hero") as Hero).take_hit(1000.0, Vector3.ZERO)
	assert_bool((main.get_node("Hud") as Hud).defeat.visible).is_true()
	(main.get_node("RestartTimer") as Timer).stop()
#@ all
#@ 10+


func test_la_carboglace_est_une_nappe_basse_en_volutes() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var mist: FogVolume = main.get_node("GroundMist") as FogVolume
	var material: ShaderMaterial = mist.material as ShaderMaterial
	assert_str(material.shader.resource_path).is_equal("res://6_assets/Shader/Environment/ground_mist.gdshader")
	assert_float(mist.global_position.y - mist.size.y / 2.0).is_equal_approx(0.0, 0.01)
	var layer: float = material.get_shader_parameter(&"layer_height")
	assert_float(layer).is_less_equal(mist.size.y)
	assert_float(layer).is_less(1.8)
	assert_object(material.get_shader_parameter(&"noise") as NoiseTexture3D).is_not_null()
	var drift: Vector3 = material.get_shader_parameter(&"drift")
	assert_float(drift.length()).is_greater(0.0)
#@ all
#@ 11+


#@ 11
func test_sous_le_seuil_du_golem_les_spectres_sortent_et_chassent_le_heros() -> void:
#@ 12+
func test_a_la_seconde_phase_du_golem_les_spectres_sortent_et_chassent_le_heros() -> void:
#@ 11+
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var spectres: Array[Node] = main.get_node("Spectres").get_children()
	assert_int(spectres.size()).is_equal(3)
	for s: Node in spectres:
		assert_bool((s as Spectre).is_active()).is_false()
	(main.get_node("Golem/Hurtbox") as Hurtbox).receive(600.0)
	var appel: SpectreCall = main.get_node("SpectreCall") as SpectreCall
	appel.tick(appel.settings.stagger * 2.0)
	for s: Node in spectres:
		assert_bool((s as Spectre).is_active()).is_true()
		assert_that((s as Spectre).target).is_same(main.get_node("Hero"))
		assert_that((s as Spectre).target_health).is_same(main.get_node("Hero/Health"))
#@ all
#@ 13+


func test_les_effets_ont_la_camera_du_heros_et_ses_tirs() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	assert_that((main.get_node("Golem/Effects") as GolemEffects).camera).is_same(main.get_node("OrbitCamera"))
	assert_that((main.get_node("ImpactSparks") as ImpactSparks).pool).is_same(main.get_node("Projectiles"))
#@ all
#@ 16+


func test_le_tir_part_droit_devant_ou_vers_la_cible_verrouillee_et_le_canon_suit() -> void:
	var main: Node3D = _main()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var hero: Hero = main.get_node("Hero") as Hero
	var orbit: OrbitCamera = main.get_node("OrbitCamera") as OrbitCamera
	hero.get_node("Input").free()
	orbit.get_node("Input").free()
	await get_tree().physics_frame
	assert_float(hero.aim_point().y).is_equal_approx(hero.gun.global_position.y, 0.001)
	var golem: Golem = main.get_node("Golem") as Golem
	orbit.lock(golem.lock_point)
	assert_vector(hero.aim_point()).is_equal(golem.lock_point.global_position)
	hero.trigger = true
	var view: HeroView = hero.get_node("View") as HeroView
	for _i: int in 30:
		await get_tree().physics_frame
	var vers: Vector3 = hero.gun.global_position.direction_to(golem.lock_point.global_position)
	assert_float(view.aim_pitch.pitch).is_equal_approx(asin(vers.y), 0.05)
	var canon: Vector3 = -(view.muzzle.get_parent() as Node3D).global_basis.z.normalized()
	assert_float(rad_to_deg(canon.angle_to(vers))).is_less(12.0)
	hero.trigger = false
#@ all
