extends GdUnitTestSuite
## Arme : cadence, projectile lancé dans la bonne direction et dans le parent fourni.

const BLASTER := preload("res://5_data/weapons/blaster.tres")
const BULLET := preload("res://3_entities/projectiles/bullet/bullet_player.tscn")


func _arme(parent: Node3D) -> WeaponComponent:
	var weapon := WeaponComponent.new()
	weapon.stats = BLASTER
	parent.add_child(weapon)
	weapon.setup(BULLET, parent)
	return weapon


func test_cadence_et_projectile() -> void:
	var parent: Node3D = auto_free(Node3D.new())
	add_child(parent)
	var weapon := _arme(parent)
	var tir := weapon.fire(Vector3.FORWARD)
	assert_object(tir).is_not_null()
	assert_object(tir.get_parent()).is_same(parent)
	assert_vector((tir as Bullet).velocity).is_equal(Vector3.FORWARD * BLASTER.projectile_speed)
	assert_object(weapon.fire(Vector3.FORWARD)).is_null()
	for i in ceili(60.0 / BLASTER.fire_rate) + 1:
		await get_tree().physics_frame
	assert_object(weapon.fire(Vector3.FORWARD)).is_not_null()


func test_sans_projectile_pas_de_tir() -> void:
	var weapon: WeaponComponent = auto_free(WeaponComponent.new())
	weapon.stats = BLASTER
	add_child(weapon)
	assert_bool(weapon.can_fire()).is_false()
