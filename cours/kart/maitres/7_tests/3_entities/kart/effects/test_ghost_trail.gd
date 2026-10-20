extends GdUnitTestSuite
## Règles de la traînée fantôme : un turbo la lance ; le kart en mouvement y laisse des copies de lui-même ;
## après sa pleine durée et son fondu, elle s'arrête et les copies disparaissent.

const KART := preload("res://3_entities/kart/kart.tscn")

var _kart: Kart
var _ghosts: GhostTrail


func before_test() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 8
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1000.0, 1.0, 1000.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child(auto_free(ground))
	_kart = auto_free(KART.instantiate())
	_kart.input = null
	_kart.position = Vector3(0.0, 0.6, 0.0)
	add_child(_kart)
	_ghosts = _kart.get_node("GhostTrail") as GhostTrail


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame
		await get_tree().process_frame


func test_un_turbo_lance_la_trainee() -> void:
	await _frames(30)
	assert_bool(_ghosts.is_running()).is_false()
	_kart.set_boost(0.5)
	assert_bool(_ghosts.is_running()).is_true()


func test_en_mouvement_le_kart_laisse_des_fantomes() -> void:
	await _frames(30)
	_kart.commands.throttle = 1.0
	await _frames(30)
	_kart.set_boost(0.5)
	await _frames(20)
	assert_int(_ghosts.ghost_count()).is_greater(2)


func test_apres_son_fondu_la_trainee_s_arrete() -> void:
	await _frames(30)
	_kart.commands.throttle = 1.0
	await _frames(30)
	_kart.set_boost(0.5)
	var seconds := _ghosts.full_duration + _ghosts.fade_out_duration + _ghosts.ghost_lifetime + 0.2
	await _frames(int(seconds * 60.0))
	assert_bool(_ghosts.is_running()).is_false()
	assert_int(_ghosts.ghost_count()).is_equal(0)
