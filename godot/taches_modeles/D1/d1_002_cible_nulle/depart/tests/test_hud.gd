extends GdUnitTestSuite
## Règles du HUD : chaque signal met à jour son libellé.


func _nouveau_hud() -> Hud:
	var hud: Hud = auto_free(load("res://scenes/hud.tscn").instantiate())
	add_child(hud)
	return hud


func test_libelle_vie() -> void:
	var hud := _nouveau_hud()
	hud._on_health_changed(3, 5)
	assert_str(hud.health_label.text).is_equal("Vie : 3/5")


func test_libelle_pieces() -> void:
	var hud := _nouveau_hud()
	hud._on_coins_changed(12)
	assert_str(hud.coins_label.text).is_equal("Pièces : 12")


func test_libelle_vague() -> void:
	var hud := _nouveau_hud()
	hud._on_wave_started(4, 5)
	assert_str(hud.wave_label.text).is_equal("Vague 4")
