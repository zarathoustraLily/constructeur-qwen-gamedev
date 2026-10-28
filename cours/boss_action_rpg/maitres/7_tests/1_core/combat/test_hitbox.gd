extends GdUnitTestSuite
## Règles d'une zone de coup, dans un vrai monde physique : elle est sur la couche des coups du boss et regarde le
## héros ; éteinte, elle ne frappe pas ; allumée, elle frappe une fois ce qui la touche déjà ; rallumée, elle frappe
## de nouveau ; ce qui entre pendant qu'elle est allumée est frappé ; un corps qui ne sait pas recevoir de coup est
## ignoré.


## Un corps de test sur la couche du héros, un CharacterBody3D comme le héros, qui note les coups reçus.
class Victim extends CharacterBody3D:
	var hits: Array[float] = []

	func take_hit(amount: float, _from: Vector3) -> float:
		hits.append(amount)
		return amount


var _world: Node3D
var _hitbox: Hitbox
var _landed: int = 0


func before_test() -> void:
	_world = auto_free(Node3D.new())
	add_child(_world)
	_hitbox = Hitbox.new()
	_hitbox.add_child(_shape())
	_world.add_child(_hitbox)
	_hitbox.landed.connect(_on_landed)
	_landed = 0


func _on_landed(_body: Node3D, _dealt: float) -> void:
	_landed += 1


func _shape() -> CollisionShape3D:
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	shape.shape = box
	return shape


func _place(body: CharacterBody3D, at: Vector3) -> void:
	body.collision_layer = Layers.bit(Layers.HERO)
	body.add_child(_shape())
	body.position = at
	_world.add_child(body)


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_sur_la_couche_des_coups_du_boss_elle_regarde_le_heros() -> void:
	assert_int(_hitbox.collision_layer).is_equal(Layers.bit(Layers.BOSS_HITS))
	assert_int(_hitbox.collision_mask).is_equal(Layers.bit(Layers.HERO))
	assert_bool(_hitbox.monitorable).is_false()


func test_eteinte_elle_ne_frappe_pas() -> void:
	var victim: Victim = Victim.new()
	_place(victim, Vector3.ZERO)
	await _frames(5)
	assert_array(victim.hits).is_empty()


func test_allumee_elle_frappe_une_fois_ce_qui_la_touche() -> void:
	var victim: Victim = Victim.new()
	_place(victim, Vector3.ZERO)
	await _frames(3)
	_hitbox.activate(15.0)
	await _frames(10)
	assert_array(victim.hits).is_equal([15.0])
	assert_int(_landed).is_equal(1)


func test_rallumee_elle_frappe_de_nouveau() -> void:
	var victim: Victim = Victim.new()
	_place(victim, Vector3.ZERO)
	await _frames(3)
	_hitbox.activate(15.0)
	_hitbox.deactivate()
	_hitbox.activate(20.0)
	assert_array(victim.hits).is_equal([15.0, 20.0])


func test_ce_qui_entre_allumee_est_frappe() -> void:
	_hitbox.activate(15.0)
	var victim: Victim = Victim.new()
	_place(victim, Vector3(0.0, 0.0, 10.0))
	await _frames(3)
	assert_array(victim.hits).is_empty()
	victim.position = Vector3.ZERO
	await _frames(3)
	assert_array(victim.hits).is_equal([15.0])


func test_un_corps_qui_ne_sait_pas_recevoir_de_coup_est_ignore() -> void:
	_place(CharacterBody3D.new(), Vector3.ZERO)
	await _frames(3)
	_hitbox.activate(15.0)
	await _frames(3)
	assert_int(_landed).is_equal(0)
