extends GdUnitTestSuite
## Règles du joueur : sans commande il reste sur place ; il marche dans la direction voulue, tournée comme sa
## caméra, à la vitesse de ses réglages, et un stick à moitié le fait marcher à moitié vitesse ; son modèle
## se tourne vers sa marche ; sans sol il tombe, puis reprend sa course en touchant le sol.

const PLAYER := preload("res://3_entities/player/player.tscn")

var _player: Player


func before_test() -> void:
	var ground: StaticBody3D = auto_free(StaticBody3D.new())
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(ground)
	_player = auto_free(PLAYER.instantiate())
	# Pas d'adaptateur : le test écrit lui-même les commandes.
	_player.input = null
	_player.position = Vector3(0.0, 1.0, 0.0)
	add_child(_player)


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func _state() -> String:
	return str((_player.get_node("StateMachine") as StateMachine).state.name)


func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


func test_sans_commande_le_joueur_reste_sur_place() -> void:
	await _frames(30)
	assert_vector(_flat(_player.global_position)).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.01)
	assert_str(_state()).is_equal("PlayerRun")


func test_il_marche_dans_la_direction_voulue_tournee_comme_la_camera() -> void:
	await _frames(10)
	var start := _player.global_position
	_player.commands.move = Vector2.RIGHT
	await _frames(60)
	var moved := _flat(_player.global_position - start)
	var expected := Vector3.RIGHT.rotated(Vector3.UP, _player.camera.global_rotation.y)
	assert_vector(moved.normalized()).is_equal_approx(expected, Vector3.ONE * 0.01)
	# Une seconde de marche : la vitesse des réglages, à une image près.
	assert_float(moved.length()).is_equal_approx(_player.settings.movement_speed, _player.settings.movement_speed / 30.0)


func test_un_stick_a_moitie_fait_marcher_a_moitie_vitesse() -> void:
	await _frames(10)
	var start := _player.global_position
	_player.commands.move = Vector2(0.0, -0.5)
	await _frames(60)
	var speed := _player.settings.movement_speed
	assert_float(_flat(_player.global_position - start).length()).is_equal_approx(speed * 0.5, speed / 30.0)


func test_le_modele_se_tourne_vers_la_marche() -> void:
	_player.commands.move = Vector2.LEFT
	await _frames(60)
	var expected := Vector3.LEFT.rotated(Vector3.UP, _player.camera.global_rotation.y)
	# Le modèle regarde vers son +Z (look_at avec use_model_front).
	assert_vector(_player.model.global_basis.z.normalized()).is_equal_approx(expected, Vector3.ONE * 0.02)


func test_sans_sol_il_tombe_puis_reprend_sa_course_au_sol() -> void:
	_player.global_position = Vector3(0.0, 4.0, 0.0)
	await _frames(3)
	assert_str(_state()).is_equal("PlayerFall")
	await _frames(60)
	assert_str(_state()).is_equal("PlayerRun")
	assert_bool(_player.is_on_floor()).is_true()
	assert_float(_player.global_position.y).is_equal_approx(1.0, 0.05)


func test_les_reglages_sont_poses() -> void:
	assert_object(_player.settings).is_not_null()
	assert_float(_player.settings.movement_speed).is_greater(0.0)
	assert_float(_player.settings.turn_rate).is_greater(0.0)
