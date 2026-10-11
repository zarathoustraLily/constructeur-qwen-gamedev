extends GdUnitTestSuite
## L'interface suit le bus d'événements.


func test_score_et_vie() -> void:
	var hud: Hud = auto_free(load("res://4_ui/hud/hud.tscn").instantiate())
	add_child(hud)
	EventBus.score_changed.emit(300)
	EventBus.player_damaged.emit(2)
	assert_str(hud.score_label.text).is_equal("Score 300")
	assert_str(hud.health_label.text).is_equal("Vie 2")
