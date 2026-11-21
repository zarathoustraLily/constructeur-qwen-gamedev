extends GdUnitTestSuite
## La source du hasard (SIM-09) : la même graine redonne la même suite, une autre graine en donne une autre, et la
## source rend toujours le même générateur.

const GRAINE: int = 2002
const AUTRE_GRAINE: int = 7
const TIRAGES: int = 8


func _suite(source: RngSource) -> Array[int]:
	var tirages: Array[int] = []
	for _i: int in TIRAGES:
		tirages.append(source.instance().randi())
	return tirages


func test_meme_graine_meme_suite() -> void:
	assert_array(_suite(RngSource.new(GRAINE))).is_equal(_suite(RngSource.new(GRAINE)))


func test_autre_graine_autre_suite() -> void:
	assert_array(_suite(RngSource.new(GRAINE))).is_not_equal(_suite(RngSource.new(AUTRE_GRAINE)))


func test_toujours_le_meme_generateur() -> void:
	var source := RngSource.new(GRAINE)
	assert_object(source.instance()).is_same(source.instance())
