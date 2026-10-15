extends GdUnitTestSuite
## Drone : attente → poursuite → attaque selon la distance à la cible fournie, mort puis disparition.

const DRONE := "res://3_entities/enemies/drone/drone.tscn"
const BULLET := preload("res://3_entities/projectiles/bullet/bullet_enemy.tscn")


func _drone(distance: float) -> Drone:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var cible := Node3D.new()
	cible.name = "Cible"
	root.add_child(cible)
	cible.position = Vector3(0, 0, distance)
	var drone: Drone = load(DRONE).instantiate()
	root.add_child(drone)
	drone.setup(cible, BULLET, root, root, null)
	return drone


func _pas(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func test_attend_hors_detection() -> void:
	var drone := _drone(30.0)
	await _pas(3)
	assert_str(drone.state_machine.current_name()).is_equal("idle")


func test_poursuit_puis_attaque() -> void:
	var drone := _drone(12.0)
	await _pas(2)
	assert_str(drone.state_machine.current_name()).is_equal("chase")
	(drone.target()).position = Vector3(0, 0, 5)
	await _pas(2)
	assert_str(drone.state_machine.current_name()).is_equal("attack")


func test_mort_puis_disparition() -> void:
	var drone := _drone(30.0)
	drone.health.take_damage(drone.stats.max_health)
	assert_str(drone.state_machine.current_name()).is_equal("dead")
	assert_bool(drone.is_in_group(&"enemies")).is_false()
	await _pas(ceili(drone.stats.death_duration * 60.0) + 3)
	assert_bool(is_instance_valid(drone)).is_false()
