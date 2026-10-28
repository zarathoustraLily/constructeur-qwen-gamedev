extends GdUnitTestSuite
## Règles de la grille spatiale : un point tombe dans sa case, négatifs compris ; une recherche rend exactement ce
## qu'une comparaison à tous rendrait ; un objet déplacé n'est plus trouvé à son ancienne place ; un objet retiré
## disparaît, et sa case vide avec lui.


func test_un_point_tombe_dans_sa_case() -> void:
	var grid: SpatialGrid = SpatialGrid.new(4.0)
	assert_that(grid.cell_of(Vector2(5.0, 1.0))).is_equal(Vector2i(1, 0))
	assert_that(grid.cell_of(Vector2(-0.5, -4.5))).is_equal(Vector2i(-1, -2))


func test_une_recherche_rend_ce_que_la_force_brute_rendrait() -> void:
	var grid: SpatialGrid = SpatialGrid.new(3.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12
	var points: Array[Vector2] = []
	for id: int in 300:
		var point: Vector2 = Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-30.0, 30.0))
		points.append(point)
		grid.insert(id, point)
	for _q: int in 20:
		var center: Vector2 = Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-30.0, 30.0))
		var expected: Array[int] = []
		for id: int in points.size():
			if points[id].distance_to(center) <= 5.0:
				expected.append(id)
		assert_array(grid.query(center, 5.0)).is_equal(expected)


func test_un_objet_deplace_n_est_plus_a_son_ancienne_place() -> void:
	var grid: SpatialGrid = SpatialGrid.new(4.0)
	grid.insert(7, Vector2(1.0, 1.0))
	grid.insert(7, Vector2(20.0, 20.0))
	assert_array(grid.query(Vector2(1.0, 1.0), 2.0)).is_empty()
	assert_array(grid.query(Vector2(20.0, 20.0), 1.0)).is_equal([7])


func test_un_objet_retire_disparait_avec_sa_case_vide() -> void:
	var grid: SpatialGrid = SpatialGrid.new(4.0)
	grid.insert(1, Vector2(1.0, 1.0))
	grid.insert(2, Vector2(9.0, 9.0))
	assert_int(grid.cell_count()).is_equal(2)
	grid.remove(1)
	grid.remove(99)
	assert_int(grid.cell_count()).is_equal(1)
	assert_array(grid.query(Vector2(1.0, 1.0), 3.0)).is_empty()
