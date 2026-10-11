extends GdUnitTestSuite
## Arme : cadence, projectile lancé dans la bonne direction et dans le bon parent.

const BLASTER := preload("res://5_data/weapons/blaster.tres")


func test_cadence_et_projectile() -> void:
	var parent: Node3D = auto_free(Node3D.new())
	add_child(parent)
	var weapon := WeaponComponent.new()
	weapon.stats = BLASTER
	weapon.projectile_parent = parent
	parent.add_child(weapon)
	var tir := weapon.fire(Vector3.FORWARD)
	assert_object(tir).is_not_null()
	assert_object(tir.get_parent()).is_same(parent)
	assert_vector((tir as Bullet).velocity).is_equal(Vector3.FORWARD * BLASTER.projectile_speed)
	assert_object(weapon.fire(Vector3.FORWARD)).is_null()
	weapon._physics_process(1.0 / BLASTER.fire_rate + 0.001)
	assert_object(weapon.fire(Vector3.FORWARD)).is_not_null()
