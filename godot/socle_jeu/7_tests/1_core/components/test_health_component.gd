extends GdUnitTestSuite
## Composant de vie : dégâts bornés, mort unique, invincibilités (tenue et après un coup).


func _vie(max_health: int, hit_invulnerability: float) -> HealthComponent:
	var h: HealthComponent = auto_free(HealthComponent.new())
	add_child(h)
	h.setup(max_health, hit_invulnerability)
	return h


func test_degats_et_mort_unique() -> void:
	var h := _vie(2, 0.0)
	var morts: Array[int] = [0]
	h.died.connect(func() -> void: morts[0] += 1)
	assert_bool(h.take_damage(5)).is_true()
	assert_bool(h.take_damage(1)).is_false()
	assert_int(h.current_health).is_equal(0)
	assert_int(morts[0]).is_equal(1)


func test_invincible_ignore() -> void:
	var h := _vie(3, 0.0)
	h.set_invulnerable(true)
	assert_bool(h.take_damage(1)).is_false()
	h.set_invulnerable(false)
	assert_bool(h.take_damage(1)).is_true()


func test_invincibilite_apres_coup_au_pas_fixe() -> void:
	var h := _vie(3, 0.05)
	h.take_damage(1)
	assert_bool(h.take_damage(1)).is_false()
	for i in 6:
		await get_tree().physics_frame
	assert_bool(h.take_damage(1)).is_true()
