extends GdUnitTestSuite
## Règles de l'appel des spectres : au-dessus du seuil, rien ; sous le seuil, ils sortent un par un, à `stagger` secondes
## d'écart, chacun à sa place sur le cercle ; l'appel n'a lieu qu'une fois.

const SPECTRE := preload("res://3_entities/enemies/spectre/spectre.tscn")
const SETTINGS := preload("res://5_data/enemies/spectre.tres")

var _health: HealthComponent
var _call: SpectreCall
var _prey: Node3D


func before_test() -> void:
	var world: Node3D = auto_free(Node3D.new())
	add_child(world)
	_prey = Node3D.new()
	world.add_child(_prey)
	var health_settings: HealthSettings = HealthSettings.new()
	health_settings.max_health = 1500.0
	health_settings.invincibility_time = 0.0
	_health = HealthComponent.new()
	_health.settings = health_settings
	world.add_child(_health)
	_call = SpectreCall.new()
	_call.settings = SETTINGS
	_call.health = _health
	_call.prey = _prey
	for _i: int in 3:
		var spectre: Spectre = SPECTRE.instantiate() as Spectre
		world.add_child(spectre)
		_call.spectres.append(spectre)
	world.add_child(_call)


func _actifs() -> int:
	var n: int = 0
	for s: Spectre in _call.spectres:
		if s.is_active():
			n += 1
	return n


func test_au_dessus_du_seuil_rien() -> void:
	_health.take_damage(400.0)
	_call.tick(10.0)
	assert_bool(_call.has_called).is_false()
	assert_int(_actifs()).is_equal(0)


func test_sous_le_seuil_ils_sortent_un_par_un() -> void:
	_health.take_damage(600.0)
	assert_bool(_call.has_called).is_true()
	assert_int(_actifs()).is_equal(1)
	_call.tick(SETTINGS.stagger)
	assert_int(_actifs()).is_equal(2)
	_call.tick(SETTINGS.stagger)
	assert_int(_actifs()).is_equal(3)
	assert_float(_call.spectres[1].orbit_angle).is_equal_approx(TAU / 3.0, 0.0001)


func test_l_appel_n_a_lieu_qu_une_fois() -> void:
	var appels: Array[int] = [0]
	_call.called.connect(func() -> void: appels[0] += 1)
	_health.take_damage(600.0)
	_health.take_damage(100.0)
	assert_int(appels[0]).is_equal(1)
