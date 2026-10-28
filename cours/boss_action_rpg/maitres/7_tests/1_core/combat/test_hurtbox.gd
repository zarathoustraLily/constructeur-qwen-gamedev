extends GdUnitTestSuite
## Règles de la zone qui reçoit les tirs : elle est sur la couche des cibles et ne surveille rien ; elle passe les
## dégâts à sa santé, multipliés ; un multiplicateur nul ou l'absence de santé bloque ; chaque tir s'annonce.

var _health: HealthComponent
var _hurtbox: Hurtbox
var _received: Array[Vector2] = []


func before_test() -> void:
	var settings: HealthSettings = HealthSettings.new()
	settings.max_health = 100.0
	settings.invincibility_time = 0.0
	_health = auto_free(HealthComponent.new())
	_health.settings = settings
	add_child(_health)
	_hurtbox = auto_free(Hurtbox.new())
	_hurtbox.health = _health
	add_child(_hurtbox)
	_received.clear()


func _on_received(amount: float, dealt: float) -> void:
	_received.append(Vector2(amount, dealt))


func test_sur_la_couche_des_cibles_sans_surveiller() -> void:
	assert_int(_hurtbox.collision_layer).is_equal(Layers.bit(Layers.TARGETS))
	assert_int(_hurtbox.collision_mask).is_equal(0)
	assert_bool(_hurtbox.monitoring).is_false()


func test_les_degats_passent_a_la_sante_multiplies() -> void:
	_hurtbox.multiplier = 1.5
	assert_float(_hurtbox.receive(10.0)).is_equal(15.0)
	assert_float(_health.health).is_equal(85.0)


func test_un_multiplicateur_nul_ou_sans_sante_bloque() -> void:
	_hurtbox.multiplier = 0.0
	assert_float(_hurtbox.receive(10.0)).is_equal(0.0)
	_hurtbox.multiplier = 1.0
	_hurtbox.health = null
	assert_float(_hurtbox.receive(10.0)).is_equal(0.0)
	assert_float(_health.health).is_equal(100.0)


func test_chaque_tir_s_annonce() -> void:
	_hurtbox.received.connect(_on_received)
	_hurtbox.receive(10.0)
	_hurtbox.multiplier = 0.0
	_hurtbox.receive(10.0)
	assert_array(_received).is_equal([Vector2(10.0, 10.0), Vector2(10.0, 0.0)])
