extends GdUnitTestSuite
## Règles du composant de santé : il part de sa santé maximale ; un coup retire ses dégâts et prévient dans
## l'ordre (damage_taken, puis health_changed) ; la défaite arrive à 0, pas avant ; restore() rend toute la santé.


func _health(maximum: float) -> HealthComponent:
	var health: HealthComponent = auto_free(HealthComponent.new())
	health.max_health = maximum
	add_child(health)
	return health


func test_au_depart_la_sante_est_maximale() -> void:
	assert_float(_health(40.0).current_health).is_equal(40.0)


func test_un_coup_retire_ses_degats_et_previent_dans_l_ordre() -> void:
	var health := _health(40.0)
	var received: Array[String] = []
	health.damage_taken.connect(func(amount: float) -> void: received.append("damage_taken %.1f" % amount))
	health.health_changed.connect(func(value: float) -> void: received.append("health_changed %.1f" % value))
	health.take_damage(15.0)
	assert_float(health.current_health).is_equal(25.0)
	assert_array(received).is_equal(["damage_taken 15.0", "health_changed 25.0"])


func test_la_defaite_arrive_a_zero_et_pas_avant() -> void:
	var health := _health(40.0)
	var defeats: Array[int] = [0]
	health.defeated.connect(func() -> void: defeats[0] += 1)
	health.take_damage(39.0)
	assert_int(defeats[0]).is_equal(0)
	health.take_damage(1.0)
	assert_int(defeats[0]).is_equal(1)


func test_restore_rend_toute_la_sante() -> void:
	var health := _health(40.0)
	health.take_damage(30.0)
	health.restore()
	assert_float(health.current_health).is_equal(40.0)
