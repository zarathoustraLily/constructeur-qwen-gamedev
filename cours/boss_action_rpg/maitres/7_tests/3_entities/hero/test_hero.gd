extends GdUnitTestSuite
## Règles du héros, sur un vrai sol simulé par le moteur physique : il se pose ; il court vers l'avant de la caméra,
## et vers sa gauche quand elle a tourné d'un quart de tour ; il tourne son corps vers sa marche ; il court moins vite
## en visant ; stick lâché, il s'arrête ; il est sur sa couche et regarde le monde et le boss.

const HERO := preload("res://3_entities/hero/hero.tscn")

var _world: Node3D
var _camera: Node3D


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
	_camera = Node3D.new()
	_world.add_child(_camera)
	add_child(_world)


func _hero() -> Hero:
	var hero: Hero = HERO.instantiate() as Hero
	hero.get_node("Input").free()
	hero.camera = _camera
	hero.position = Vector3(0.0, 0.05, 0.0)
	_world.add_child(hero)
	return hero


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_il_se_pose_sur_le_sol() -> void:
	var hero: Hero = _hero()
	await _frames(10)
	assert_bool(hero.is_on_floor()).is_true()


func test_il_court_vers_l_avant_de_la_camera() -> void:
	var hero: Hero = _hero()
	await _frames(5)
	hero.stick = Vector2(0.0, -1.0)
	await _frames(60)
	assert_float(hero.position.z).is_less(-3.0)
	assert_float(absf(hero.position.x)).is_less(0.05)
	assert_float(hero.velocity.length()).is_equal_approx(hero.settings.run_speed, 0.05)


func test_camera_tournee_il_court_vers_sa_gauche() -> void:
	_camera.rotation.y = PI / 2.0
	var hero: Hero = _hero()
	await _frames(5)
	hero.stick = Vector2(0.0, -1.0)
	await _frames(60)
	assert_float(hero.position.x).is_less(-3.0)


func test_il_tourne_son_corps_vers_sa_marche() -> void:
	var hero: Hero = _hero()
	hero.stick = Vector2(1.0, 0.0)
	await _frames(60)
	assert_float(absf(angle_difference(hero.rotation.y, -PI / 2.0))).is_less(0.01)


func test_il_court_moins_vite_en_visant() -> void:
	var hero: Hero = _hero()
	hero.aiming = true
	hero.stick = Vector2(0.0, -1.0)
	await _frames(60)
	assert_float(hero.velocity.length()).is_equal_approx(hero.settings.aim_speed, 0.05)


func test_stick_lache_il_s_arrete() -> void:
	var hero: Hero = _hero()
	hero.stick = Vector2(0.0, -1.0)
	await _frames(40)
	hero.stick = Vector2.ZERO
	await _frames(20)
	assert_float(Vector2(hero.velocity.x, hero.velocity.z).length()).is_less(0.01)


func test_il_est_sur_sa_couche_et_regarde_le_monde_et_le_boss() -> void:
	var hero: Hero = _hero()
	assert_bool(Layers.has(hero.collision_layer, Layers.HERO)).is_true()
	assert_bool(Layers.has(hero.collision_mask, Layers.WORLD)).is_true()
	assert_bool(Layers.has(hero.collision_mask, Layers.BOSS)).is_true()
	assert_bool(Layers.has(hero.collision_mask, Layers.PROJECTILES)).is_false()
