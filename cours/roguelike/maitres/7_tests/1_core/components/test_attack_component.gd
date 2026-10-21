extends GdUnitTestSuite
## Règles du composant d'attaque, dans un vrai espace physique : un coup touche chaque cible de sa zone une seule
## fois (dégâts, recul, signal struck) jusqu'à reset_exceptions() ; une zone désactivée ne touche rien.

var _zone: ShapeCast3D
var _attack: AttackComponent
var _target: CharacterBody3D
var _health: HealthComponent
var _knockback: KnockbackComponent


## Une cible (corps, santé, recul) au centre d'une zone de coup sphérique de 1 m.
func _prepare() -> void:
	var world: Node3D = auto_free(Node3D.new())
	_target = CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	_target.add_child(shape)
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_target.add_child(_health)
	_knockback = KnockbackComponent.new()
	_knockback.name = "KnockbackComponent"
	_target.add_child(_knockback)
	world.add_child(_target)
	_zone = ShapeCast3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	_zone.shape = sphere
	_zone.target_position = Vector3.ZERO
	_attack = AttackComponent.new()
	_zone.add_child(_attack)
	world.add_child(_zone)
	add_child(world)
	# Le corps entre dans l'espace physique aux images physiques suivantes.
	await get_tree().physics_frame
	await get_tree().physics_frame


func test_un_coup_touche_chaque_cible_une_seule_fois() -> void:
	await _prepare()
	var struck: Array[Object] = []
	_attack.struck.connect(func(target: Object) -> void: struck.append(target))
	_attack.deal_damage(10.0, Vector3(5.0, 0.0, 0.0))
	_attack.deal_damage(10.0, Vector3(5.0, 0.0, 0.0))
	assert_float(_health.current_health).is_equal(90.0)
	assert_vector(_knockback.magnitude).is_equal(Vector3(5.0, 0.0, 0.0))
	assert_array(struck).is_equal([_target])


func test_apres_reset_exceptions_la_cible_peut_etre_retouchee() -> void:
	await _prepare()
	_attack.deal_damage(10.0, Vector3.ZERO)
	_attack.reset_exceptions()
	_attack.deal_damage(10.0, Vector3.ZERO)
	assert_float(_health.current_health).is_equal(80.0)


func test_une_zone_desactivee_ne_touche_rien() -> void:
	await _prepare()
	_zone.enabled = false
	_attack.deal_damage(10.0, Vector3.ZERO)
	assert_float(_health.current_health).is_equal(100.0)
