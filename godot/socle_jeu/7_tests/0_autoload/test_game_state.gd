extends GdUnitTestSuite
## État de la partie : remise à zéro, score, vies, et les signaux que l'interface écoute.


func test_score_et_vies() -> void:
	var scores: Array[int] = []
	var ecoute := func(score: int) -> void: scores.append(score)
	GameState.score_changed.connect(ecoute)
	GameState.reset(2)
	GameState.add_score(100)
	GameState.score_changed.disconnect(ecoute)
	assert_array(scores).contains_exactly([0, 100])
	assert_bool(GameState.lose_life()).is_true()
	assert_bool(GameState.lose_life()).is_false()
	assert_int(GameState.lives).is_equal(0)
