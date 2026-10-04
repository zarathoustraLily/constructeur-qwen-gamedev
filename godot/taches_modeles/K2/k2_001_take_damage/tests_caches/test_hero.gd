extends GdUnitTestSuite
## Règles du héros : déplacement, dash, i-frames.

const SCENE_HERO := "res://scenes/hero.tscn"


func _nouveau_hero() -> Hero:
	var hero: Hero = auto_free(load(SCENE_HERO).instantiate())
	add_child(hero)
	hero.set_physics_process(false)
	return hero


func test_vitesse_de_marche() -> void:
	var hero := _nouveau_hero()
	assert_vector(hero.compute_velocity(Vector2.RIGHT)).is_equal(Vector2(200, 0))


func test_diagonale_normalisee() -> void:
	var hero := _nouveau_hero()
	var v := hero.compute_velocity(Vector2(1, 1))
	assert_float(v.length()).is_equal_approx(200.0, 0.001)


func test_dash_donne_les_iframes() -> void:
	var hero := _nouveau_hero()
	assert_bool(hero.try_dash(Vector2.UP)).is_true()
	assert_bool(hero.is_dashing()).is_true()
	assert_bool(hero.health.invulnerable).is_true()
	assert_bool(hero.health.take_damage(1)).is_false()
	assert_int(hero.health.current_health).is_equal(5)


func test_vitesse_pendant_le_dash() -> void:
	var hero := _nouveau_hero()
	hero.try_dash(Vector2.LEFT)
	assert_vector(hero.compute_velocity(Vector2.RIGHT)).is_equal(Vector2(-600, 0))


func test_iframes_finissent_avec_le_dash() -> void:
	var hero := _nouveau_hero()
	hero.try_dash(Vector2.UP)
	hero.advance_dash(0.1)
	assert_bool(hero.health.invulnerable).is_true()
	hero.advance_dash(0.1)
	assert_bool(hero.is_dashing()).is_false()
	assert_bool(hero.health.invulnerable).is_false()
	assert_bool(hero.health.take_damage(1)).is_true()


func test_recharge_empeche_un_second_dash() -> void:
	var hero := _nouveau_hero()
	hero.try_dash(Vector2.UP)
	hero.advance_dash(0.2)
	assert_bool(hero.try_dash(Vector2.UP)).is_false()
	for i in 6:
		hero.advance_dash(0.1)
	assert_bool(hero.try_dash(Vector2.UP)).is_true()


func test_dash_sans_direction_suit_le_regard() -> void:
	var hero := _nouveau_hero()
	hero.facing = Vector2.DOWN
	var directions: Array = []
	hero.dashed.connect(func(d: Vector2) -> void: directions.append(d))
	hero.try_dash(Vector2.ZERO)
	assert_array(directions).is_equal([Vector2.DOWN])
