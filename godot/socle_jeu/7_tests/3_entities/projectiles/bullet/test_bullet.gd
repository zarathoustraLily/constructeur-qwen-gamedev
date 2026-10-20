extends GdUnitTestSuite
## Projectile : avance au pas fixe, puis disparaît en fin de vie.

const BULLET := "res://3_entities/projectiles/bullet/bullet_player.tscn"


func test_avance_puis_disparait() -> void:
	var bullet: Bullet = load(BULLET).instantiate()
	add_child(bullet)
	bullet.launch(Vector3.FORWARD * 6.0, 1, 0.1)
	# physics_frame arrive juste avant le pas physique : deux attentes pour un pas joué.
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_float(bullet.global_position.z).is_less(0.0)
	assert_int(bullet.damage).is_equal(1)
	for i in 10:
		await get_tree().physics_frame
	assert_bool(is_instance_valid(bullet)).is_false()
