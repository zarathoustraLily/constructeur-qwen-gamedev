extends GdUnitTestSuite
## Règles des vagues d'ennemis.


func _nouveau_spawner() -> WaveSpawner:
	var spawner: WaveSpawner = auto_free(WaveSpawner.new())
	spawner.enemy_scene = load("res://scenes/ghost.tscn")
	add_child(spawner)
	return spawner


func _ennemis(spawner: WaveSpawner) -> Array[Ghost]:
	var result: Array[Ghost] = []
	for child in spawner.get_children():
		if child is Ghost and not child.is_queued_for_deletion():
			result.append(child)
	return result


func test_taille_des_vagues() -> void:
	var spawner := _nouveau_spawner()
	assert_int(spawner.enemies_for_wave(1)).is_equal(2)
	assert_int(spawner.enemies_for_wave(2)).is_equal(3)
	assert_int(spawner.enemies_for_wave(5)).is_equal(6)


func test_positions_sur_le_cercle() -> void:
	var spawner := _nouveau_spawner()
	var positions := spawner.spawn_positions(4)
	assert_int(positions.size()).is_equal(4)
	for p in positions:
		assert_float(p.length()).is_equal_approx(160.0, 0.001)
	assert_vector(positions[0]).is_equal_approx(Vector2(160, 0), Vector2(0.001, 0.001))


func test_premiere_vague() -> void:
	var spawner := _nouveau_spawner()
	var debuts: Array = []
	spawner.wave_started.connect(func(n: int, c: int) -> void: debuts.append([n, c]))
	spawner.start_next_wave()
	assert_array(debuts).is_equal([[1, 2]])
	assert_int(_ennemis(spawner).size()).is_equal(2)
	assert_int(spawner.alive).is_equal(2)


func test_vague_terminee_quand_tous_vaincus() -> void:
	var spawner := _nouveau_spawner()
	var finies: Array = []
	spawner.wave_cleared.connect(func(n: int) -> void: finies.append(n))
	spawner.start_next_wave()
	var ennemis := _ennemis(spawner)
	ennemis[0].health.take_damage(2)
	assert_array(finies).is_empty()
	ennemis[1].health.take_damage(2)
	assert_array(finies).is_equal([1])
