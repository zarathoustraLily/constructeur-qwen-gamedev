extends GdUnitTestSuite
## Règles d'assemblage de la scène principale.


func before_test() -> void:
	GameState.reset()


func _nouvelle_partie() -> Node2D:
	var main: Node2D = auto_free(load("res://scenes/main.tscn").instantiate())
	add_child(main)
	return main


func test_premiere_vague_lancee() -> void:
	var main := _nouvelle_partie()
	var spawner: WaveSpawner = main.get_node("WaveSpawner")
	assert_int(spawner.current_wave).is_equal(1)
	assert_str(main.get_node("Hud/VagueLabel").text).is_equal("Vague 1")


func test_hud_affiche_la_vie_du_heros() -> void:
	var main := _nouvelle_partie()
	assert_str(main.get_node("Hud/VieLabel").text).is_equal("Vie : 5/5")
	main.get_node("Hero").health.take_damage(2)
	assert_str(main.get_node("Hud/VieLabel").text).is_equal("Vie : 3/5")


func test_hud_affiche_les_pieces() -> void:
	var main := _nouvelle_partie()
	main.get_node("Coins/Coin1").collect()
	assert_str(main.get_node("Hud/PiecesLabel").text).is_equal("Pièces : 1")


func test_connexions_de_la_scene() -> void:
	var main := _nouvelle_partie()
	var spawner: WaveSpawner = main.get_node("WaveSpawner")
	var hud: Hud = main.get_node("Hud")
	assert_bool(spawner.wave_started.is_connected(hud._on_wave_started)).is_true()
	assert_bool(spawner.wave_cleared.is_connected(main._on_wave_cleared)).is_true()


func test_vague_suivante_apres_nettoyage() -> void:
	var main := _nouvelle_partie()
	var spawner: WaveSpawner = main.get_node("WaveSpawner")
	for child in spawner.get_children():
		if child is Ghost:
			child.health.take_damage(2)
	assert_int(spawner.current_wave).is_equal(2)
	assert_str(main.get_node("Hud/VagueLabel").text).is_equal("Vague 2")
