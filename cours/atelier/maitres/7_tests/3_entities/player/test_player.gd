extends GdUnitTestSuite
## Règles du joueur, sur un vrai sol simulé par le moteur physique : il tombe et se pose ; il est sur la couche du
## joueur et regarde le monde ; il avance vers la direction voulue ; un saut le fait décoller puis retomber ; un
## appui un peu avant de toucher le sol fait sauter à l'atterrissage.

const PLAYER := preload("res://3_entities/player/player.tscn")

var _world: Node3D


func before_test() -> void:
	_world = auto_free(Node3D.new())
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = Layers.bit(Layers.WORLD)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(shape)
	_world.add_child(floor_body)
	add_child(_world)


func _player(height: float) -> Player:
	var player: Player = PLAYER.instantiate() as Player
	player.position = Vector3(0.0, height, 0.0)
	# Pas d'entrée : le test pilote le joueur lui-même.
	player.get_node("Input").queue_free()
	_world.add_child(player)
	return player


func _frames(count: int) -> void:
	for _i: int in count:
		await get_tree().physics_frame


func test_il_tombe_et_se_pose() -> void:
	var player: Player = _player(2.0)
	await _frames(90)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.position.y).is_equal_approx(0.0, 0.05)


func test_il_est_sur_sa_couche_et_regarde_le_monde() -> void:
	var player: Player = _player(0.1)
	assert_bool(Layers.has(player.collision_layer, Layers.PLAYER)).is_true()
	assert_bool(Layers.has(player.collision_mask, Layers.WORLD)).is_true()
	assert_bool(Layers.has(player.collision_mask, Layers.PLAYER)).is_false()


func test_il_avance_vers_la_direction_voulue() -> void:
	var player: Player = _player(0.1)
	await _frames(20)
	player.wish = Vector2.RIGHT
	await _frames(60)
	assert_float(player.position.x).is_greater(3.0)
	assert_float(player.velocity.x).is_equal_approx(player.settings.max_speed, 0.01)


func test_un_saut_le_fait_decoller_puis_retomber() -> void:
	var player: Player = _player(0.1)
	await _frames(20)
	var jumps: Array[bool] = []
	player.jumped.connect(func() -> void: jumps.append(true))
	player.press_jump()
	await _frames(10)
	assert_bool(player.is_on_floor()).is_false()
	assert_float(player.position.y).is_greater(0.5)
	await _frames(90)
	assert_bool(player.is_on_floor()).is_true()
	assert_array(jumps).has_size(1)


func test_un_appui_juste_avant_le_sol_fait_sauter_a_l_atterrissage() -> void:
	var player: Player = _player(0.6)
	await _frames(10)
	assert_bool(player.is_on_floor()).is_false()
	var jumps: Array[bool] = []
	player.jumped.connect(func() -> void: jumps.append(true))
	player.press_jump()
	await _frames(30)
	assert_array(jumps).has_size(1)
