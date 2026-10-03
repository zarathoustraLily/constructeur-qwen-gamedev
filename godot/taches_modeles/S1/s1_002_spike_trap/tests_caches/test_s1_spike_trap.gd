extends GdUnitTestSuite
## Juge S1 : structure et comportement de res://scenes/spike_trap.tscn.

const SCENE := "res://scenes/spike_trap.tscn"


func _instance() -> Node:
	var scene: PackedScene = load(SCENE)
	assert_object(scene).is_not_null()
	var noeud: Node = auto_free(scene.instantiate())
	add_child(noeud)
	return noeud


func test_racine() -> void:
	var racine := _instance()
	assert_str(racine.name).is_equal("SpikeTrap")
	assert_bool(racine is SpikeTrap).is_true()
	assert_int((racine as SpikeTrap).damage).is_equal(2)


func test_forme_de_collision() -> void:
	var racine := _instance()
	var forme := racine.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert_object(forme).is_not_null()
	assert_bool(forme.shape is RectangleShape2D).is_true()
	assert_vector((forme.shape as RectangleShape2D).size).is_equal(Vector2(16, 16))


func test_minuteur_de_recharge() -> void:
	var racine := _instance()
	var minuteur := racine.get_node_or_null("Cooldown") as Timer
	assert_object(minuteur).is_not_null()
	assert_float(minuteur.wait_time).is_equal_approx(1.5, 0.001)
	assert_bool(minuteur.one_shot).is_true()
	assert_bool(minuteur.autostart).is_false()


func test_blesse_puis_se_recharge() -> void:
	var piege := _instance() as SpikeTrap
	var hero: Hero = auto_free(load("res://scenes/hero.tscn").instantiate())
	add_child(hero)
	assert_bool(piege.hit(hero)).is_true()
	assert_int(hero.health.current_health).is_equal(3)
	assert_bool(piege.hit(hero)).is_false()
	assert_int(hero.health.current_health).is_equal(3)
