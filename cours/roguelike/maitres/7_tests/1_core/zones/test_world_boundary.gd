extends GdUnitTestSuite
## Règles de la limite du monde : un corps qui passe sous elle est signalé ; un corps au-dessus ne l'est pas.
#@ 6+
## Un personnage qui y tombe perd toute sa santé (il est vaincu) et disparaît ; un corps sans santé reste visible.
#@ all

var _boundary: WorldBoundary
var _fallen: Array[Node3D] = []


func before_test() -> void:
	_boundary = auto_free(WorldBoundary.new())
	var shape := CollisionShape3D.new()
	shape.shape = WorldBoundaryShape3D.new()
	_boundary.add_child(shape)
	_boundary.position = Vector3(0.0, -4.0, 0.0)
	add_child(_boundary)
	_fallen.clear()
	_boundary.body_fell.connect(func(body: Node3D) -> void: _fallen.append(body))


func _body(height: float) -> CharacterBody3D:
	var body: CharacterBody3D = auto_free(CharacterBody3D.new())
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	body.add_child(shape)
	body.position = Vector3(0.0, height, 0.0)
	add_child(body)
	return body


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func test_un_corps_sous_la_limite_est_signale() -> void:
	var body := _body(-6.0)
	await _frames(3)
	assert_array(_fallen).is_equal([body])


func test_un_corps_au_dessus_ne_l_est_pas() -> void:
	_body(2.0)
	await _frames(3)
	assert_array(_fallen).is_empty()
#@ 6+


func test_un_personnage_qui_tombe_perd_toute_sa_sante_et_disparait() -> void:
	var body := _body(-6.0)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	health.max_health = 60.0
	body.add_child(health)
	var defeats: Array[int] = [0]
	health.defeated.connect(func() -> void: defeats[0] += 1)
	await _frames(3)
	assert_float(health.current_health).is_less_equal(0.0)
	assert_int(defeats[0]).is_equal(1)
	assert_bool(body.visible).is_false()


func test_un_corps_sans_sante_reste_visible() -> void:
	var body := _body(-6.0)
	await _frames(3)
	assert_array(_fallen).is_equal([body])
	assert_bool(body.visible).is_true()
#@ all
