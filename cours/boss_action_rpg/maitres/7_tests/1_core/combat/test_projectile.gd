extends GdUnitTestSuite
## Règles des projectiles et de leur réserve, dans un vrai monde physique : la réserve prépare tous ses projectiles au
## chargement, éteints ; un tir en prend un, qui vole droit à sa vitesse ; un mur l'arrête et il revient à la
## réserve ; il fait ses dégâts, multipliés, à une zone mince qu'il ne traverse pas malgré sa vitesse ; une zone à
## multiplicateur nul l'arrête sans dégâts ; sa durée passée, il revient ; réserve vide, aucun tir ; tirer ne crée
## aucun nœud.

const PROJECTILE := preload("res://1_core/combat/projectile.tscn")
const SPEED: float = 60.0

var _world: Node3D
var _pool: ProjectilePool


func before_test() -> void:
	_world = auto_free(Node3D.new())
	add_child(_world)
	_pool = ProjectilePool.new()
	_pool.scene = PROJECTILE
	_pool.size = 4
	_world.add_child(_pool)


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func _shape(size: Vector3) -> CollisionShape3D:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	return shape


func _wall(z: float) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.add_child(_shape(Vector3(10.0, 10.0, 0.2)))
	wall.position = Vector3(0.0, 0.0, z)
	_world.add_child(wall)


## Une zone mince (5 cm) à `z` : à 60 m/s, un projectile fait 1 m par image ; seul son rayon la voit.
func _target(z: float, multiplier: float) -> HealthComponent:
	var settings: HealthSettings = HealthSettings.new()
	settings.max_health = 100.0
	settings.invincibility_time = 0.0
	var health: HealthComponent = HealthComponent.new()
	health.settings = settings
	_world.add_child(health)
	var hurtbox: Hurtbox = Hurtbox.new()
	hurtbox.health = health
	hurtbox.multiplier = multiplier
	hurtbox.add_child(_shape(Vector3(2.0, 2.0, 0.05)))
	hurtbox.position = Vector3(0.0, 0.0, z)
	_world.add_child(hurtbox)
	return health


func _fire(damage: float, lifetime: float) -> Projectile:
	return _pool.fire(Vector3.ZERO, Vector3.FORWARD, SPEED, damage, lifetime)


func test_la_reserve_prepare_tous_ses_projectiles_eteints() -> void:
	assert_int(_pool.get_child_count()).is_equal(4)
	assert_int(_pool.available()).is_equal(4)
	for child: Node in _pool.get_children():
		var projectile: Projectile = child as Projectile
		assert_bool(projectile.active).is_false()
		assert_bool(projectile.visible).is_false()


func test_un_tir_vole_droit_a_sa_vitesse() -> void:
	var projectile: Projectile = _fire(10.0, 2.0)
	assert_int(_pool.available()).is_equal(3)
	assert_bool(projectile.visible).is_true()
	await _frames(5)
	var start_z: float = projectile.global_position.z
	await _frames(5)
	assert_float(start_z - projectile.global_position.z).is_equal_approx(5.0 * SPEED / 60.0, 0.001)
	assert_float(projectile.global_position.x).is_equal_approx(0.0, 0.0001)
	assert_float(projectile.global_position.y).is_equal_approx(0.0, 0.0001)


func test_un_mur_l_arrete_et_il_revient_a_la_reserve() -> void:
	_wall(-5.0)
	await _frames(2)
	var projectile: Projectile = _fire(10.0, 2.0)
	await _frames(15)
	assert_bool(projectile.active).is_false()
	assert_bool(projectile.visible).is_false()
	assert_int(_pool.available()).is_equal(4)
	assert_float(projectile.global_position.z).is_equal_approx(-4.9, 0.01)


func test_il_fait_ses_degats_multiplies_a_une_zone_mince() -> void:
	var health: HealthComponent = _target(-5.0, 2.0)
	await _frames(2)
	_fire(10.0, 2.0)
	await _frames(15)
	assert_float(health.health).is_equal(80.0)
	assert_int(_pool.available()).is_equal(4)


func test_une_zone_a_multiplicateur_nul_l_arrete_sans_degats() -> void:
	var health: HealthComponent = _target(-5.0, 0.0)
	await _frames(2)
	var projectile: Projectile = _fire(10.0, 2.0)
	await _frames(15)
	assert_float(health.health).is_equal(100.0)
	assert_bool(projectile.active).is_false()
	assert_float(projectile.global_position.z).is_greater(-5.1)


func test_sa_duree_passee_il_revient() -> void:
	var projectile: Projectile = _fire(10.0, 0.1)
	await _frames(12)
	assert_bool(projectile.active).is_false()
	assert_int(_pool.available()).is_equal(4)


func test_reserve_vide_aucun_tir() -> void:
	for _i: int in 4:
		assert_object(_fire(10.0, 2.0)).is_not_null()
	assert_object(_fire(10.0, 2.0)).is_null()


func test_tirer_ne_cree_aucun_noeud() -> void:
	await _frames(2)
	var nodes: float = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for _i: int in 6:
		_fire(10.0, 0.05)
		await _frames(5)
	assert_float(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)).is_equal(nodes)
	assert_int(_pool.get_child_count()).is_equal(4)
