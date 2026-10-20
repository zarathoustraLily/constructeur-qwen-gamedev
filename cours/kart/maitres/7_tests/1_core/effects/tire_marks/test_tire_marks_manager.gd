extends GdUnitTestSuite
## Règles des traces de pneus : une marque en un point du monde devient un pixel de la texture centrée sur le
## joueur, avec sa force et son rayon ; quatre marques au plus partent à chaque image, et l'attente se vide.

var _marks: TireMarksManager


func before_test() -> void:
	_marks = auto_free(TireMarksManager.new())
	_marks.texture_resolution = Vector2i(512, 512)
	_marks.texture_size = Vector2(64.0, 64.0)
	add_child(_marks)


func test_le_centre_de_la_texture_tombe_au_milieu() -> void:
	_marks.add_tire(Vector3.ZERO, 1.0, 9.0)
	assert_that(_marks.take_marks()[0]).is_equal(Vector4(256.0, 256.0, 1.0, 9.0))


func test_un_metre_vaut_huit_pixels() -> void:
	_marks.add_tire(Vector3(2.0, 0.0, -1.0), 1.0, 9.0)
	var mark := _marks.take_marks()[0]
	assert_float(mark.x).is_equal(272.0)
	assert_float(mark.y).is_equal(248.0)


func test_quatre_marques_au_plus_partent_et_l_attente_se_vide() -> void:
	for wheel: int in 6:
		_marks.add_tire(Vector3(wheel, 0.0, 0.0), 1.0, 9.0)
	assert_int(_marks.take_marks().size()).is_equal(TireMarksManager.MAX_MARKS_PER_FRAME)
	assert_int(_marks.take_marks().size()).is_equal(0)
