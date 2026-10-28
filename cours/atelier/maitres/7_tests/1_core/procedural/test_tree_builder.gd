extends GdUnitTestSuite
## Règles de l'arbre : autant de branches que 1 + k + k² + … ; le tronc monte du sol ; chaque niveau est plus court
## et plus fin ; une branche fille part du bout de son parent, penchée de l'angle voulu ; la même graine donne le
## même arbre, une autre graine un autre ; le bois a six sommets par face ; les feuilles sont au bout des rameaux.

const SETTINGS := preload("res://5_data/DECORS/NATURE/tree.tres")


func test_le_nombre_de_branches() -> void:
	assert_int(TreeBuilder.segment_count(SETTINGS)).is_equal(1 + 3 + 9 + 27)
	assert_int(TreeBuilder.grow(SETTINGS).size()).is_equal(TreeBuilder.segment_count(SETTINGS))


func test_le_tronc_monte_du_sol() -> void:
	var trunk: TreeBuilder.Segment = TreeBuilder.grow(SETTINGS)[0]
	assert_vector(trunk.start).is_equal(Vector3.ZERO)
	assert_vector(trunk.end).is_equal_approx(Vector3.UP * SETTINGS.trunk_length, Vector3.ONE * 0.0001)
	assert_int(trunk.level).is_equal(0)


func test_chaque_niveau_est_plus_court_et_plus_fin() -> void:
	var segments: Array[TreeBuilder.Segment] = TreeBuilder.grow(SETTINGS)
	var child: TreeBuilder.Segment = segments[1]
	assert_int(child.level).is_equal(1)
	assert_float((child.end - child.start).length()).is_equal_approx(SETTINGS.trunk_length * SETTINGS.length_ratio, 0.0001)
	assert_float(child.radius).is_equal_approx(SETTINGS.trunk_radius * SETTINGS.radius_ratio, 0.0001)


func test_une_branche_fille_part_du_bout_de_son_parent() -> void:
	var segments: Array[TreeBuilder.Segment] = TreeBuilder.grow(SETTINGS)
	assert_vector(segments[1].start).is_equal_approx(segments[0].end, Vector3.ONE * 0.0001)


func test_la_direction_fille_est_penchee_de_l_angle_voulu() -> void:
	var direction: Vector3 = TreeBuilder.child_direction(Vector3.UP, deg_to_rad(30.0), 1.0)
	assert_float(rad_to_deg(direction.angle_to(Vector3.UP))).is_equal_approx(30.0, 0.01)
	assert_float(direction.length()).is_equal_approx(1.0, 0.0001)


func test_la_meme_graine_donne_le_meme_arbre() -> void:
	var a: Array[TreeBuilder.Segment] = TreeBuilder.grow(SETTINGS)
	var b: Array[TreeBuilder.Segment] = TreeBuilder.grow(SETTINGS)
	assert_vector(a[a.size() - 1].end).is_equal(b[b.size() - 1].end)
	var other: TreeSettings = SETTINGS.duplicate() as TreeSettings
	other.random_seed = 99
	var c: Array[TreeBuilder.Segment] = TreeBuilder.grow(other)
	assert_bool(a[a.size() - 1].end.is_equal_approx(c[c.size() - 1].end)).is_false()


func test_le_bois_a_six_sommets_par_face() -> void:
	var segments: Array[TreeBuilder.Segment] = TreeBuilder.grow(SETTINGS)
	var mesh: ArrayMesh = TreeBuilder.wood_mesh(segments)
	assert_int(mesh.surface_get_array_len(0)).is_equal(segments.size() * 4 * 6)


func test_les_feuilles_sont_au_bout_des_rameaux() -> void:
	var segments: Array[TreeBuilder.Segment] = TreeBuilder.grow(SETTINGS)
	var tips: Array[TreeBuilder.Segment] = TreeBuilder.tips(segments, SETTINGS)
	assert_int(tips.size()).is_equal(27)
	var leaves: PackedVector3Array = TreeBuilder.leaf_positions(segments, SETTINGS)
	assert_int(leaves.size()).is_equal(27 * SETTINGS.leaves_per_tip)
	var nearest: float = INF
	for tip: TreeBuilder.Segment in tips:
		nearest = minf(nearest, leaves[0].distance_to(tip.end))
	assert_float(nearest).is_less(SETTINGS.trunk_length)
