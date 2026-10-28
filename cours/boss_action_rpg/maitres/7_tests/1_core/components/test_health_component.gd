extends GdUnitTestSuite
## Règles de la santé : pleine au départ ; un coup retire des points et ouvre un répit où les coups suivants ne font
## rien ; le répit passe avec le temps ; on ne descend jamais sous zéro ; la mort n'est annoncée qu'une fois ; un
## soin ne dépasse pas le maximum et ne relève pas un mort ; la part qui reste se lit de 0 à 1.

var _settings: HealthSettings


func before_test() -> void:
	_settings = HealthSettings.new()
	_settings.max_health = 30.0
	_settings.invincibility_time = 0.4


func _health() -> HealthComponent:
	var health: HealthComponent = auto_free(HealthComponent.new())
	health.settings = _settings
	add_child(health)
	return health


func test_pleine_au_depart() -> void:
	var health: HealthComponent = _health()
	assert_float(health.health).is_equal(_settings.max_health)
	assert_float(health.ratio()).is_equal(1.0)


func test_un_coup_retire_des_points_et_ouvre_le_repit() -> void:
	var health: HealthComponent = _health()
	assert_float(health.take_damage(10.0)).is_equal(10.0)
	assert_float(health.health).is_equal(_settings.max_health - 10.0)
	assert_bool(health.is_invincible()).is_true()
	assert_float(health.take_damage(10.0)).is_equal(0.0)
	assert_float(health.health).is_equal(_settings.max_health - 10.0)


func test_le_repit_passe_avec_le_temps() -> void:
	var health: HealthComponent = _health()
	health.take_damage(5.0)
	health.tick(_settings.invincibility_time + 0.01)
	assert_bool(health.is_invincible()).is_false()
	assert_float(health.take_damage(5.0)).is_equal(5.0)


func test_un_coup_nul_ou_negatif_ne_fait_rien() -> void:
	var health: HealthComponent = _health()
	assert_float(health.take_damage(0.0)).is_equal(0.0)
	assert_float(health.take_damage(-5.0)).is_equal(0.0)
	assert_bool(health.is_invincible()).is_false()


func test_jamais_sous_zero_et_la_mort_une_seule_fois() -> void:
	var health: HealthComponent = _health()
	var deaths: Array[bool] = []
	health.died.connect(func() -> void: deaths.append(true))
	assert_float(health.take_damage(1000.0)).is_equal(_settings.max_health)
	assert_float(health.health).is_equal(0.0)
	assert_bool(health.is_dead()).is_true()
	health.tick(10.0)
	assert_float(health.take_damage(10.0)).is_equal(0.0)
	assert_array(deaths).has_size(1)


func test_les_degats_sont_annonces() -> void:
	var health: HealthComponent = _health()
	var received: Array = []
	health.damaged.connect(func(amount: float, remaining: float) -> void: received.append([amount, remaining]))
	health.take_damage(12.0)
	assert_array(received).is_equal([[12.0, _settings.max_health - 12.0]])


func test_un_soin_ne_depasse_pas_le_maximum() -> void:
	var health: HealthComponent = _health()
	health.take_damage(10.0)
	assert_float(health.heal(25.0)).is_equal(10.0)
	assert_float(health.health).is_equal(_settings.max_health)
	assert_float(health.heal(5.0)).is_equal(0.0)


func test_un_soin_ne_releve_pas_un_mort() -> void:
	var health: HealthComponent = _health()
	health.take_damage(1000.0)
	assert_float(health.heal(10.0)).is_equal(0.0)
	assert_bool(health.is_dead()).is_true()


func test_la_part_qui_reste() -> void:
	var health: HealthComponent = _health()
	health.take_damage(_settings.max_health / 4.0)
	assert_float(health.ratio()).is_equal_approx(0.75, 0.0001)
