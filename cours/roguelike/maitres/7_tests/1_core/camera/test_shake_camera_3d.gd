extends GdUnitTestSuite
## Règles de la caméra qui tremble : immobile sans trauma ; quick_shake() la fait trembler, puis elle revient
## au calme en shake_duration ; deux caméras au même bruit tremblent à l'identique.

var _camera: ShakeCamera3D


func _shake_camera() -> ShakeCamera3D:
	var camera: ShakeCamera3D = auto_free(ShakeCamera3D.new())
	var noise := FastNoiseLite.new()
	noise.seed = 3
	camera.noise = noise
	camera.offset_scale = 3.0
	add_child(camera)
	return camera


func before_test() -> void:
	_camera = _shake_camera()


func _frames(count: int) -> void:
	for _frame: int in count:
		await get_tree().physics_frame


func test_sans_trauma_elle_reste_immobile() -> void:
	await _frames(5)
	assert_float(_camera.h_offset).is_equal(0.0)
	assert_float(_camera.v_offset).is_equal(0.0)


func test_quick_shake_la_fait_trembler_puis_revenir_au_calme() -> void:
	_camera.quick_shake(1.0)
	await _frames(3)
	assert_float(_camera.trauma).is_greater(0.0)
	assert_float(absf(_camera.h_offset) + absf(_camera.v_offset)).is_greater(0.0)
	await _frames(int(_camera.shake_duration * 60.0) + 3)
	assert_float(_camera.trauma).is_equal(0.0)
	assert_float(_camera.h_offset).is_equal(0.0)


func test_deux_cameras_au_meme_bruit_tremblent_pareil() -> void:
	# Deux caméras posées à la même image : leur temps de jeu est le même.
	var first := _shake_camera()
	var second := _shake_camera()
	first.quick_shake(1.0)
	second.quick_shake(1.0)
	await _frames(5)
	assert_float(first.h_offset).is_not_equal(0.0)
	assert_float(second.h_offset).is_equal_approx(first.h_offset, 0.0001)
	assert_float(second.v_offset).is_equal_approx(first.v_offset, 0.0001)
