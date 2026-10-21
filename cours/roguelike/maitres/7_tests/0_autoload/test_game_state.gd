extends GdUnitTestSuite
## Règles de l'état qui dure : le rang part de 1 ; un niveau fini le monte ; une défaite le ramène à 1.

var _saved: int


func before_test() -> void:
	_saved = GameState.level


func after_test() -> void:
	GameState.level = _saved


func test_un_niveau_fini_monte_le_rang_une_defaite_le_ramene_a_un() -> void:
	GameState.reset()
	assert_int(GameState.level).is_equal(1)
	GameState.finish_level()
	GameState.finish_level()
	assert_int(GameState.level).is_equal(3)
	GameState.reset()
	assert_int(GameState.level).is_equal(1)
