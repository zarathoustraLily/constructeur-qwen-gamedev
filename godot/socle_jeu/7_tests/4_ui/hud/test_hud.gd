extends GdUnitTestSuite
## L'interface suit le score de la partie et la vie que le niveau lui donne.


func test_score_et_vie() -> void:
	var hud: Hud = auto_free(load("res://4_ui/hud/hud.tscn").instantiate())
	add_child(hud)
	GameState.reset(1)
	GameState.add_score(300)
	hud.show_health(2)
	assert_str(hud.score_label.text).is_equal("Score 300")
	assert_str(hud.health_label.text).is_equal("Vie 2")
