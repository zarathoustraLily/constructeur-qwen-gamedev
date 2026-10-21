extends GdUnitTestSuite
## Règles de la boule de feu : elle file vers son +Z à la vitesse de ses réglages ; elle blesse une cible et laisse
## un impact, puis disparaît ; elle ne touche pas son lanceur ; sans rien toucher, elle s'éteint au bout de sa durée
## de vie.

const FIREBALL := preload("res://3_entities/enemy/fireball/fireball.tscn")


## Un corps sur les couches du joueur (1, corps, et 5, joueur : 1 + 16), avec une santé, en `position`.
func _target(position: Vector3) -> CharacterBody3D:
	var target: CharacterBody3D = auto_free(CharacterBody3D.new())
	target.collision_layer = 17
	var shape := CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	target.add_child(shape)
	var health := HealthComponent.new()
	health.name = "HealthComponent"
	target.add_child(health)
	add_child(target)
	target.global_position = position
	return target


func _fireball() -> Fireball:
	var fireball := FIREBALL.instantiate() as Fireball
	add_child(fireball)
	return fireball


func after_test() -> void:
	for child: Node in get_children():
		if str(child.name).begins_with("FireballImpact"):
			child.free()


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func _impacts() -> int:
	var count := 0
	for child: Node in get_children():
		if str(child.name).begins_with("FireballImpact"):
			count += 1
	return count


func test_elle_file_vers_son_avant_a_la_vitesse_de_ses_reglages() -> void:
	var fireball := _fireball()
	fireball.global_position = Vector3(0.0, 1.0, 0.0)
	await _frames(1)
	var start := fireball.global_position
	await _frames(30)
	var moved := fireball.global_position - start
	assert_vector(moved.normalized()).is_equal_approx(Vector3.BACK, Vector3.ONE * 0.001)
	assert_float(moved.length()).is_equal_approx(fireball.settings.speed * 0.5, fireball.settings.speed / 30.0)
	fireball.free()


func test_elle_blesse_une_cible_laisse_un_impact_et_disparait() -> void:
	var target := _target(Vector3(0.0, 1.0, 3.0))
	var health := target.get_node("HealthComponent") as HealthComponent
	var fireball := _fireball()
	var damage := fireball.settings.damage
	fireball.global_position = Vector3(0.0, 1.0, 0.0)
	await _frames(40)
	assert_float(health.current_health).is_equal(health.max_health - damage)
	assert_bool(is_instance_valid(fireball)).is_false()
	assert_int(_impacts()).is_equal(1)


func test_elle_ne_touche_pas_son_lanceur() -> void:
	var shooter := _target(Vector3(0.0, 1.0, 0.0))
	var health := shooter.get_node("HealthComponent") as HealthComponent
	var fireball := _fireball()
	fireball.ignore(shooter)
	fireball.global_position = Vector3(0.0, 1.0, 0.0)
	await _frames(5)
	assert_float(health.current_health).is_equal(health.max_health)
	fireball.free()


func test_sans_rien_toucher_elle_s_eteint_au_bout_de_sa_duree_de_vie() -> void:
	var fireball := _fireball()
	fireball.global_position = Vector3(0.0, 50.0, 0.0)
	var lifetime := fireball.get_node("Lifetime") as Timer
	assert_float(lifetime.time_left).is_equal_approx(fireball.settings.lifetime, 0.1)
	lifetime.start(0.05)
	await _frames(10)
	assert_bool(is_instance_valid(fireball)).is_false()
	assert_int(_impacts()).is_equal(0)
