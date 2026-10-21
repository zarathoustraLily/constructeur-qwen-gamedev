extends GdUnitTestSuite
## Règles de la sortie : cachée et fermée au départ ; unlock() l'ouvre et la montre ; le joueur (groupe
## « player ») qui entre dans la sortie ouverte la signale une fois ; un autre corps, ou une sortie fermée, rien.

const EXIT := preload("res://3_entities/interactables/exit_point/exit_point.tscn")

var _exit: ExitPoint
var _reached: Array[int] = [0]


func before_test() -> void:
	_exit = auto_free(EXIT.instantiate())
	add_child(_exit)
	_reached = [0]
	_exit.reached.connect(func() -> void: _reached[0] += 1)


func _body(in_player_group: bool) -> CharacterBody3D:
	var body: CharacterBody3D = auto_free(CharacterBody3D.new())
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	body.add_child(shape)
	if in_player_group:
		body.add_to_group(&"player")
	add_child(body)
	body.global_position = Vector3(10.0, 0.0, 0.0)
	return body


func _enter(body: CharacterBody3D) -> void:
	body.global_position = _exit.global_position
	for _frame: int in 3:
		await get_tree().physics_frame


func test_cachee_et_fermee_au_depart() -> void:
	assert_bool(_exit.visible).is_false()
	assert_bool(_exit.locked).is_true()


func test_unlock_l_ouvre_et_la_montre() -> void:
	_exit.unlock()
	assert_bool(_exit.visible).is_true()
	assert_bool(_exit.locked).is_false()


func test_le_joueur_qui_entre_dans_la_sortie_ouverte_la_signale_une_fois() -> void:
	var player := _body(true)
	_exit.unlock()
	await _enter(player)
	assert_int(_reached[0]).is_equal(1)
	player.global_position = Vector3(10.0, 0.0, 0.0)
	await get_tree().physics_frame
	await _enter(player)
	assert_int(_reached[0]).is_equal(1)
	player.remove_from_group(&"player")


func test_un_autre_corps_ou_une_sortie_fermee_rien() -> void:
	var other := _body(false)
	_exit.unlock()
	await _enter(other)
	assert_int(_reached[0]).is_equal(0)
	_exit.locked = true
	var player := _body(true)
	await _enter(player)
	assert_int(_reached[0]).is_equal(0)
	player.remove_from_group(&"player")
