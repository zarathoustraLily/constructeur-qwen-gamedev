extends GdUnitTestSuite
## Drone : attente → poursuite → attaque selon la distance, mort qui rapporte des points.

const DRONE := "res://3_entities/enemies/drone/drone.tscn"


func _scene(distance: float) -> Array:
	var root: Node3D = auto_free(Node3D.new())
	add_child(root)
	var cible := Node3D.new()
	cible.add_to_group(&"player")
	root.add_child(cible)
	cible.position = Vector3(0, 0, distance)
	var drone: Drone = load(DRONE).instantiate()
	root.add_child(drone)
	drone.weapon.projectile_parent = root
	return [drone, cible]


func _pas(drone: Drone, n: int = 1) -> void:
	for i in n:
		drone.state_machine._physics_process(1.0 / 60.0)


func test_attend_hors_detection() -> void:
	var drone: Drone = _scene(30.0)[0]
	_pas(drone, 3)
	assert_str(drone.state_machine.current_name()).is_equal("idle")


func test_poursuit_puis_attaque() -> void:
	var r := _scene(12.0)
	var drone: Drone = r[0]
	_pas(drone)
	assert_str(drone.state_machine.current_name()).is_equal("chase")
	(r[1] as Node3D).position = Vector3(0, 0, 5)
	_pas(drone)
	assert_str(drone.state_machine.current_name()).is_equal("attack")


func test_mort_rapporte_les_points() -> void:
	var drone: Drone = _scene(30.0)[0]
	var points := [0]
	var ecoute := func(_e: Node3D, p: int) -> void: points[0] += p
	EventBus.enemy_killed.connect(ecoute)
	drone.health.take_damage(drone.stats.max_health)
	EventBus.enemy_killed.disconnect(ecoute)
	assert_str(drone.state_machine.current_name()).is_equal("dead")
	assert_int(points[0]).is_equal(drone.stats.score_value)
	assert_bool(drone.is_in_group(&"enemies")).is_false()
