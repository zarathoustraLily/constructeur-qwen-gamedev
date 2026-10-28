extends GdUnitTestSuite
## Règles du point visé : le rayon s'arrête sur le premier obstacle de ses couches ; rien touché, le bout du rayon ;
## un corps d'une autre couche (le héros) ne l'arrête pas ; une zone de la couche des cibles l'arrête.

var _world: Node3D


func before_test() -> void:
	_world = auto_free(Node3D.new())
	add_child(_world)


func _box(body: CollisionObject3D, z: float, layer: int) -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(10.0, 10.0, 0.2)
	shape.shape = box
	body.add_child(shape)
	body.collision_layer = Layers.bit(layer)
	body.position = Vector3(0.0, 0.0, z)
	_world.add_child(body)


func _point() -> Vector3:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = _world.get_world_3d().direct_space_state
	return Aim.point(space, Vector3.ZERO, Vector3.FORWARD, 60.0, Projectile.hit_mask())


func test_le_rayon_s_arrete_sur_le_premier_obstacle() -> void:
	_box(StaticBody3D.new(), -10.0, Layers.WORLD)
	_box(StaticBody3D.new(), -20.0, Layers.WORLD)
	var touched: Vector3 = await _point()
	assert_vector(touched).is_equal_approx(Vector3(0.0, 0.0, -9.9), Vector3.ONE * 0.001)


func test_rien_touche_le_bout_du_rayon() -> void:
	var touched: Vector3 = await _point()
	assert_vector(touched).is_equal_approx(Vector3(0.0, 0.0, -60.0), Vector3.ONE * 0.001)


func test_le_heros_ne_l_arrete_pas() -> void:
	_box(StaticBody3D.new(), -5.0, Layers.HERO)
	_box(StaticBody3D.new(), -10.0, Layers.WORLD)
	var touched: Vector3 = await _point()
	assert_float(touched.z).is_equal_approx(-9.9, 0.001)


func test_une_zone_des_cibles_l_arrete() -> void:
	_box(Area3D.new(), -7.0, Layers.TARGETS)
	var touched: Vector3 = await _point()
	assert_float(touched.z).is_equal_approx(-6.9, 0.001)
