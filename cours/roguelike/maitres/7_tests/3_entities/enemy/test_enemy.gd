extends GdUnitTestSuite
## Règles d'un ennemi au corps à corps : il vise le nœud du groupe « player » ; à portée, il attaque et sa massue
## blesse la cible ; touché, il est étourdi puis reprend la poursuite ; vaincu, il le signale, ne bloque plus
## personne et ne bouge plus ; ses réglages et sa graine viennent de 5_data.

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


func test_il_vise_le_noeud_du_groupe_player() -> void:
	_arena(10.0)
	assert_object(_enemy.target).is_same(_target)
	assert_float(_enemy.distance_to_target()).is_equal_approx(10.0, 0.01)


func test_a_portee_il_attaque_et_sa_massue_blesse_la_cible() -> void:
	_arena(1.5)
	var health := _target.get_node("HealthComponent") as HealthComponent
	await _frames(3)
	assert_str(_state()).is_equal("EnemyAttack")
	await _frames(100)
	assert_float(health.current_health).is_less(health.max_health)


func test_touche_il_est_etourdi_puis_reprend_la_poursuite() -> void:
	_arena(10.0)
	await _frames(5)
	_enemy.health_component.take_damage(5.0)
	assert_str(_state()).is_equal("EnemyStun")
	# L'arbre d'animation passe à l'état demandé à sa prochaine image ; process_frame part avant que les nœuds la
	# jouent : deux images.
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(str(_enemy.animation_tree.current_state())).is_equal("Stun")
	# L'animation du coup reçu dure 0,667 s : 40 images.
	await _frames(50)
	assert_str(_state()).is_equal("EnemyPursue")


func test_vaincu_il_le_signale_ne_bloque_plus_et_ne_bouge_plus() -> void:
	_arena(10.0)
	await _frames(5)
	var defeats: Array[int] = [0]
	_enemy.defeated.connect(func() -> void: defeats[0] += 1)
	_enemy.health_component.take_damage(_enemy.health_component.max_health)
	assert_int(defeats[0]).is_equal(1)
	assert_str(_state()).is_equal("EnemyDefeat")
	await _frames(2)
	assert_bool((_enemy.get_node("CollisionShape3D") as CollisionShape3D).disabled).is_true()
	var position := _enemy.global_position
	await _frames(30)
	assert_vector(_enemy.global_position).is_equal_approx(position, Vector3.ONE * 0.01)


func test_ses_reglages_et_sa_graine_viennent_des_donnees() -> void:
	_arena(10.0)
	assert_float(_enemy.settings.speed).is_greater(0.0)
	assert_float(_enemy.settings.attack_range).is_greater(0.0)
	assert_int(_enemy.rng.seed).is_equal(_enemy.settings.random_seed)
