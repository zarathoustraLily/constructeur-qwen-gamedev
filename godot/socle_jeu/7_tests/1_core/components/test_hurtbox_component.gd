extends GdUnitTestSuite
## Zone de coups reçus : transmet les dégâts à la vie et signale le coup.


func test_coup_transmis() -> void:
	var health: HealthComponent = auto_free(HealthComponent.new())
	add_child(health)
	health.setup(3, 0.0)
	var hurtbox: HurtboxComponent = auto_free(HurtboxComponent.new())
	hurtbox.health = health
	add_child(hurtbox)
	var recus: Array[int] = []
	hurtbox.hurt.connect(func(damage: int) -> void: recus.append(damage))
	assert_bool(hurtbox.take_hit(2)).is_true()
	assert_int(health.current_health).is_equal(1)
	assert_array(recus).contains_exactly([2])
