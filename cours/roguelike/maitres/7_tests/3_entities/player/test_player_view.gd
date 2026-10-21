extends GdUnitTestSuite
## Règles de la vue du joueur : une esquive tourne la traînée vers sa direction, la fait apparaître puis
## s'effacer, et joue le son de l'esquive ; sans esquive, la traînée est effacée.

const PLAYER := preload("res://3_entities/player/player.tscn")

var _player: Player


func before_test() -> void:
	_player = auto_free(PLAYER.instantiate())
	_player.input = null
	add_child(_player)


func _threshold() -> float:
	var trail := _player.get_node("DashRoot/VerticalTrail") as MeshInstance3D
	return (trail.material_override as ShaderMaterial).get_shader_parameter(&"threshold")


func test_sans_esquive_la_trainee_est_effacee() -> void:
	await get_tree().process_frame
	assert_float(_threshold()).is_equal(1.0)


func test_une_esquive_tourne_la_trainee_et_joue_l_effet_et_le_son() -> void:
	var direction := Vector3.LEFT
	_player.dashed.emit(direction)
	var dash_root := _player.get_node("DashRoot") as Node3D
	assert_vector(-dash_root.global_basis.z).is_equal_approx(direction, Vector3.ONE * 0.001)
	assert_str(str((_player.get_node("DashRoot/AnimationPlayer") as AnimationPlayer).current_animation)).is_equal("dash")
	assert_bool((_player.get_node("DashAudio") as AudioStreamPlayer3D).playing).is_true()
	# Au début, la traînée est entière ; une demi-seconde plus tard, effacée.
	await get_tree().process_frame
	assert_float(_threshold()).is_less(0.5)
	for _frame: int in 40:
		await get_tree().process_frame
	assert_float(_threshold()).is_equal_approx(1.0, 0.001)
