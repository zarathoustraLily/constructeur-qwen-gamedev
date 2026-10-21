extends GdUnitTestSuite
## Règles de l'ennemi à distance : quand l'animation de tir émet ranged_attack, une boule de feu part de son arme,
## vers où il regarde ; il n'est jamais touché par sa propre boule ; à portée, il cesse d'errer et tire ; une même
## graine tire le même but d'errance.

const RANGED := preload("res://3_entities/enemy/ranged_enemy.tscn")

var _enemy: RangedEnemy
var _target: Node3D


func before_test() -> void:
	var ground: StaticBody3D = auto_free(StaticBody3D.new())
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(ground)
	_target = auto_free(Node3D.new())
	_target.add_to_group(&"player")
	add_child(_target)
	_target.global_position = Vector3(0.0, 1.0, 10.0)
	_enemy = auto_free(RANGED.instantiate())
	_enemy.position = Vector3(0.0, 1.0, 0.0)
	add_child(_enemy)


func after_test() -> void:
	if is_instance_valid(_target):
		_target.remove_from_group(&"player")


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func _fireballs() -> Array[Fireball]:
	var found: Array[Fireball] = []
	for child: Node in _enemy.get_children():
		if child is Fireball:
			found.append(child as Fireball)
	return found


func test_le_tir_lance_une_boule_de_feu_depuis_son_arme_vers_ou_il_regarde() -> void:
	await _frames(2)
	_enemy.mesh_mount.look_at(_enemy.mesh_mount.global_position + Vector3.RIGHT, Vector3.UP, true)
	_enemy.attack_bone.ranged_attack.emit()
	var fireballs := _fireballs()
	assert_int(fireballs.size()).is_equal(1)
	assert_vector(fireballs[0].global_position).is_equal_approx(_enemy.attack_bone.global_position, Vector3.ONE * 0.01)
	assert_vector(fireballs[0].global_basis.z.normalized()).is_equal_approx(Vector3.RIGHT, Vector3.ONE * 0.01)
	await _frames(10)
	assert_float(_enemy.health_component.current_health).is_equal(_enemy.health_component.max_health)
	for fireball: Fireball in _fireballs():
		fireball.free()


func test_a_portee_il_cesse_d_errer_et_tire() -> void:
	_target.global_position = _enemy.global_position + Vector3(2.0, 0.0, 0.0)
	await _frames(5)
	assert_str(str(_enemy.state_machine.state.name)).is_equal("EnemyAttack")


func test_une_meme_graine_tire_le_meme_but_d_errance() -> void:
	await _frames(2)
	var meander := _enemy.get_node("StateMachine/EnemyMeander")
	_enemy.rng.seed = 7
	var first: Vector3 = meander.call(&"random_destination")
	_enemy.rng.seed = 7
	assert_vector(meander.call(&"random_destination") as Vector3).is_equal_approx(first, Vector3.ONE * 0.0001)
