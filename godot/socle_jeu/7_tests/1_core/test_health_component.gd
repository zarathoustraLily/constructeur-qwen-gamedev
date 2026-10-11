extends GdUnitTestSuite
## Composant de vie : dégâts bornés, mort unique, invincibilité.


func _vie(max_health: int = 3) -> HealthComponent:
	var h: HealthComponent = auto_free(HealthComponent.new())
	h.max_health = max_health
	add_child(h)
	return h


func test_degats_et_mort_unique() -> void:
	var h := _vie(2)
	var morts := [0]
	h.died.connect(func() -> void: morts[0] += 1)
	assert_bool(h.take_damage(5)).is_true()
	assert_bool(h.take_damage(1)).is_false()
	assert_int(h.current_health).is_equal(0)
	assert_int(morts[0]).is_equal(1)


func test_invincible_ignore() -> void:
	var h := _vie()
	h.invulnerable = true
	assert_bool(h.take_damage(1)).is_false()
	assert_int(h.current_health).is_equal(3)


func test_invincibilite_apres_coup() -> void:
	var h := _vie()
	h.hit_invulnerability = 0.5
	h.take_damage(1)
	assert_bool(h.take_damage(1)).is_false()
	h._process(0.6)
	assert_bool(h.take_damage(1)).is_true()
