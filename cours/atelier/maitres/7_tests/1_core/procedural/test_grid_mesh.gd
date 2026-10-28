extends GdUnitTestSuite
## Règles de la grille : (colonnes + 1) × (lignes + 1) sommets, centrés sur l'origine, y nul ; deux triangles par
## case ; le maillage garde ses sommets, ses coordonnées de texture vont de 0 à 1 et ses faces regardent vers le haut.


func test_le_nombre_de_sommets() -> void:
	assert_int(GridMesh.vertex_count(Vector2i(4, 2))).is_equal(15)
	assert_int(GridMesh.positions(Vector2(4.0, 2.0), Vector2i(4, 2)).size()).is_equal(15)


func test_les_sommets_sont_centres_et_a_plat() -> void:
	var points: PackedVector3Array = GridMesh.positions(Vector2(4.0, 2.0), Vector2i(4, 2))
	assert_vector(points[0]).is_equal(Vector3(-2.0, 0.0, -1.0))
	assert_vector(points[points.size() - 1]).is_equal(Vector3(2.0, 0.0, 1.0))
	assert_vector(points[7]).is_equal(Vector3(0.0, 0.0, 0.0))


func test_deux_triangles_par_case() -> void:
	var indices: PackedInt32Array = GridMesh.indices(Vector2i(4, 2))
	assert_int(indices.size()).is_equal(4 * 2 * 6)
	assert_array(Array(indices.slice(0, 6))).is_equal([0, 1, 5, 1, 6, 5])


func test_le_maillage_garde_ses_sommets_et_regarde_vers_le_haut() -> void:
	var cells: Vector2i = Vector2i(3, 3)
	var mesh: ArrayMesh = GridMesh.build(GridMesh.positions(Vector2(3.0, 3.0), cells), cells)
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	assert_int(vertices.size()).is_equal(16)
	assert_int((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()).is_equal(54)
	assert_vector(uvs[0]).is_equal(Vector2.ZERO)
	assert_vector(uvs[15]).is_equal(Vector2.ONE)
	for normal: Vector3 in normals:
		assert_float(normal.y).is_greater(0.99)
