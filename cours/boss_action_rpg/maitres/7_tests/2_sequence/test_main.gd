extends GdUnitTestSuite
## Règles de la scène principale : elle se charge ; elle a un sol avec sa collision, une lumière qui fait des ombres,
## un ciel, et sa caméra est la caméra active.
#@ 5+
## Le héros a sa réserve de projectiles et sa caméra de visée ; la cible reçoit les tirs ; tirer sur elle lui retire
## de la vie.
#@ 6+
## Quand le héros tombe, le niveau recommence après le délai de la rencontre.
#@ all

const MAIN := preload("res://2_sequence/main.tscn")


func _main() -> Node3D:
	var main: Node3D = auto_free(MAIN.instantiate())
	add_child(main)
	return main


func test_un_sol_avec_sa_collision() -> void:
	var main: Node3D = _main()
	var floor_body: StaticBody3D = main.get_node("Floor") as StaticBody3D
	assert_object(floor_body).is_not_null()
	assert_object((floor_body.get_node("Shape") as CollisionShape3D).shape).is_not_null()


func test_une_lumiere_qui_fait_des_ombres_et_un_ciel() -> void:
	var main: Node3D = _main()
	assert_bool((main.get_node("Sun") as DirectionalLight3D).shadow_enabled).is_true()
	assert_int((main.get_node("World") as WorldEnvironment).environment.background_mode).is_equal(Environment.BG_SKY)


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
	assert_bool(main.get_node("Target").is_in_group(LockOn.GROUP)).is_true()
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
	assert_that((main.get_node("Target/Hurtbox") as Hurtbox).health).is_same(main.get_node("Target/Health"))


func test_tirer_sur_la_cible_lui_retire_de_la_vie() -> void:
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
	var health: HealthComponent = main.get_node("Target/Health") as HealthComponent
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
