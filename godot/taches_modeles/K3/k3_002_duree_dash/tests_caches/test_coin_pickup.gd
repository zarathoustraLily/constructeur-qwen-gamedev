extends GdUnitTestSuite
## Règles des pièces et du compteur global.


func before_test() -> void:
	GameState.reset()


func _nouvelle_piece(valeur: int = 1) -> CoinPickup:
	var piece: CoinPickup = auto_free(load("res://scenes/coin.tscn").instantiate())
	piece.value = valeur
	add_child(piece)
	return piece


func test_ramassage_ajoute_la_valeur() -> void:
	var piece := _nouvelle_piece(3)
	piece.collect()
	assert_int(GameState.coins).is_equal(3)


func test_ramassage_unique() -> void:
	var piece := _nouvelle_piece(2)
	var valeurs: Array = []
	piece.collected.connect(func(v: int) -> void: valeurs.append(v))
	piece.collect()
	piece.collect()
	assert_int(GameState.coins).is_equal(2)
	assert_array(valeurs).is_equal([2])


func test_seul_le_heros_ramasse() -> void:
	var piece := _nouvelle_piece(1)
	var autre: Node2D = auto_free(StaticBody2D.new())
	piece._on_body_entered(autre)
	assert_int(GameState.coins).is_equal(0)
	var hero: Hero = auto_free(load("res://scenes/hero.tscn").instantiate())
	piece._on_body_entered(hero)
	assert_int(GameState.coins).is_equal(1)


func test_signal_coins_changed() -> void:
	var totaux: Array = []
	GameState.coins_changed.connect(func(t: int) -> void: totaux.append(t))
	GameState.add_coins(1)
	GameState.add_coins(0)
	GameState.add_coins(2)
	assert_array(totaux).is_equal([1, 3])
