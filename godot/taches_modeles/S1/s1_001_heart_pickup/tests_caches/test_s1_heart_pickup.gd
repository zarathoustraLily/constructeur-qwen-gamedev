extends GdUnitTestSuite
## Juge S1 : structure et comportement de res://scenes/heart_pickup.tscn.

const SCENE := "res://scenes/heart_pickup.tscn"


func _instance() -> Node:
	var scene: PackedScene = load(SCENE)
	assert_object(scene).is_not_null()
	var noeud: Node = auto_free(scene.instantiate())
	add_child(noeud)
	return noeud


func test_racine() -> void:
	var racine := _instance()
	assert_str(racine.name).is_equal("HeartPickup")
	assert_bool(racine is Area2D).is_true()
	assert_bool(racine is HeartPickup).is_true()


func test_forme_de_collision() -> void:
	var racine := _instance()
	var forme := racine.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert_object(forme).is_not_null()
	assert_bool(forme.shape is CircleShape2D).is_true()
	assert_float((forme.shape as CircleShape2D).radius).is_equal_approx(5.0, 0.001)


func test_rend_deux_points_de_vie() -> void:
	var coeur := _instance() as HeartPickup
	assert_int(coeur.heal_amount).is_equal(2)
	var hero: Hero = auto_free(load("res://scenes/hero.tscn").instantiate())
	add_child(hero)
	hero.health.take_damage(3)
	coeur.apply_to(hero)
	assert_int(hero.health.current_health).is_equal(4)
