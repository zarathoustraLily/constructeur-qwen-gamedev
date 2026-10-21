extends GdUnitTestSuite
## Règles de la vue d'un ennemi : un coup reçu joue le son du coup ; vaincu, l'écho recouvre chaque maillage du
## modèle d'une copie du matériau, monte de 0 à 1, puis le modèle disparaît.

const MELEE := preload("res://3_entities/enemy/melee_enemy.tscn")

var _enemy: Enemy
var _target: CharacterBody3D


## Un sol, une cible dans le groupe « player » (sur la couche du joueur, avec une santé), puis l'ennemi, à
## `distance` m de la cible.
func _arena(distance: float) -> void:
	var ground: StaticBody3D = auto_free(StaticBody3D.new())
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 100.0)
	ground_shape.shape = box
	ground_shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(ground_shape)
	add_child(ground)
	_target = auto_free(CharacterBody3D.new())
	_target.collision_layer = 16
	_target.add_to_group(&"player")
	var target_shape := CollisionShape3D.new()
	target_shape.shape = CapsuleShape3D.new()
	_target.add_child(target_shape)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	_target.add_child(health)
	add_child(_target)
	_target.global_position = Vector3(0.0, 1.0, 0.0)
	_enemy = auto_free(MELEE.instantiate())
	_enemy.position = Vector3(distance, 1.0, 0.0)
	add_child(_enemy)


func after_test() -> void:
	if is_instance_valid(_target):
		_target.remove_from_group(&"player")


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func _state() -> String:
	return str(_enemy.state_machine.state.name)


func _view() -> EnemyView:
	return _enemy.get_node("View") as EnemyView


func test_un_coup_recu_joue_le_son_du_coup() -> void:
	_arena(10.0)
	await _frames(2)
	_enemy.health_component.take_damage(5.0)
	assert_bool((_enemy.get_node("HitAudio") as AudioStreamPlayer3D).playing).is_true()


func test_vaincu_l_echo_le_recouvre_puis_le_modele_disparait() -> void:
	_arena(10.0)
	await _frames(2)
	var view := _view()
	_enemy.health_component.take_damage(_enemy.health_component.max_health)
	var meshes := view.model.find_children("*", "MeshInstance3D", true, false)
	assert_array(meshes).is_not_empty()
	var overlay := (meshes[0] as MeshInstance3D).material_overlay
	assert_object(overlay).is_not_null()
	assert_object(overlay).is_not_same(view.echo_material)
	await _frames(20)
	assert_float(view.echo_amount()).is_between(0.1, 0.9)
	await _frames(40)
	assert_float(view.echo_amount()).is_equal_approx(1.0, 0.001)
	assert_bool(view.model.visible).is_false()
