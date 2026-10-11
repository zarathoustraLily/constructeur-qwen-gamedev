extends GdUnitTestSuite
## Pause : la surcouche arrête l'arbre et le relance, sans faire avancer l'étape.


func test_pause_et_reprise() -> void:
	var menu: PauseMenu = auto_free(load("res://4_ui/overlays/pause/pause_menu.tscn").instantiate())
	add_child(menu)
	menu.toggle()
	var en_pause := get_tree().paused
	menu.toggle()
	assert_bool(en_pause).is_true()
	assert_bool(get_tree().paused).is_false()
	assert_bool(menu.visible).is_false()
