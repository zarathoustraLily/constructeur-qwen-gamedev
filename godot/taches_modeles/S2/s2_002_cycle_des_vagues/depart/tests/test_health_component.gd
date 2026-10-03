extends GdUnitTestSuite
## Règles du composant de vie.


func _nouveau(max_health: int = 3) -> HealthComponent:
	var h: HealthComponent = auto_free(HealthComponent.new())
	h.max_health = max_health
	add_child(h)
	return h


func test_demarre_au_maximum() -> void:
	var h := _nouveau(4)
	assert_int(h.current_health).is_equal(4)
	assert_bool(h.is_dead()).is_false()


func test_degats_retirent_des_points() -> void:
	var h := _nouveau(3)
	assert_bool(h.take_damage(1)).is_true()
	assert_int(h.current_health).is_equal(2)


func test_degats_bornes_a_zero_et_mort_unique() -> void:
	var h := _nouveau(3)
	var morts := [0]
	h.died.connect(func() -> void: morts[0] += 1)
	h.take_damage(10)
	h.take_damage(1)
	assert_int(h.current_health).is_equal(0)
	assert_bool(h.is_dead()).is_true()
	assert_int(morts[0]).is_equal(1)


func test_invulnerable_ignore_les_degats() -> void:
	var h := _nouveau(3)
	h.invulnerable = true
	assert_bool(h.take_damage(2)).is_false()
	assert_int(h.current_health).is_equal(3)


func test_degats_negatifs_ignores() -> void:
	var h := _nouveau(3)
	assert_bool(h.take_damage(-2)).is_false()
	assert_int(h.current_health).is_equal(3)


func test_signal_health_changed() -> void:
	var h := _nouveau(5)
	var recus: Array = []
	h.health_changed.connect(func(c: int, m: int) -> void: recus.append([c, m]))
	h.take_damage(2)
	h.heal(1)
	assert_array(recus).is_equal([[3, 5], [4, 5]])


func test_soin_borne_au_maximum() -> void:
	var h := _nouveau(3)
	h.take_damage(1)
	h.heal(5)
	assert_int(h.current_health).is_equal(3)


func test_pas_de_soin_apres_la_mort() -> void:
	var h := _nouveau(2)
	h.take_damage(2)
	h.heal(1)
	assert_int(h.current_health).is_equal(0)
