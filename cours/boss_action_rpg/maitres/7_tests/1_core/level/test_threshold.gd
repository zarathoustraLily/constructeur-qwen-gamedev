extends GdUnitTestSuite
## Règles du seuil : il ne regarde que le héros, ne se montre à personne ; un corps qui entre le fait parler, avec la salle
## qui suit.


func _threshold() -> Threshold:
	var threshold: Threshold = auto_free(Threshold.new())
	threshold.next = "res://suite.tscn"
	add_child(threshold)
	return threshold


func test_il_ne_regarde_que_le_heros() -> void:
	var threshold: Threshold = _threshold()
	assert_int(threshold.collision_mask).is_equal(Layers.bit(Layers.HERO))
	assert_int(threshold.collision_layer).is_equal(0)
	assert_bool(threshold.monitorable).is_false()


func test_un_corps_qui_entre_le_fait_parler_avec_la_salle_qui_suit() -> void:
	var threshold: Threshold = _threshold()
	var said: Array[String] = []
	threshold.crossed.connect(func(path: String) -> void: said.append(path))
	threshold._on_body_entered(auto_free(Node3D.new()))
	assert_array(said).contains_exactly(["res://suite.tscn"])
