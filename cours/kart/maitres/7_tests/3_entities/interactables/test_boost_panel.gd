extends GdUnitTestSuite
## Règles de la plaque d'accélération : un kart qui passe dessus reçoit 2 s de boost et sa
## traînée fantôme ; un boost plus long n'est pas raccourci ; les autres corps sont ignorés.

const SCENE_PLAQUE := "res://3_entities/interactables/boost_panel/boost_panel.tscn"
const SCENE_KART := "res://3_entities/kart/kart.tscn"

var _plaque: Node3D
var _kart: Kart


func before_test() -> void:
	_plaque = auto_free(load(SCENE_PLAQUE).instantiate())
	_kart = auto_free(load(SCENE_KART).instantiate())
	_kart.position = Vector3(0, 50, 0)
	add_child(_plaque)
	add_child(_kart)
	_kart.set_process(false)
	_kart.set_physics_process(false)


func test_un_kart_sur_la_plaque_recoit_deux_secondes_de_boost() -> void:
	_plaque._on_area_3d_body_entered(_kart)
	assert_float(_kart.boost_timer).is_equal(2.0)


func test_la_traine_fantome_demarre() -> void:
	var traine: GhostTrail = _kart.get_node("GhostTrail")
	assert_bool(traine._running).is_false()
	_plaque._on_area_3d_body_entered(_kart)
	assert_bool(traine._running).is_true()


func test_un_boost_plus_long_n_est_pas_raccourci() -> void:
	_kart.boost_timer = 3.0
	_plaque._on_area_3d_body_entered(_kart)
	assert_float(_kart.boost_timer).is_equal(3.0)


func test_un_autre_corps_est_ignore() -> void:
	var corps: StaticBody3D = auto_free(StaticBody3D.new())
	add_child(corps)
	_plaque._on_area_3d_body_entered(corps)
	assert_float(_kart.boost_timer).is_equal(0.0)
