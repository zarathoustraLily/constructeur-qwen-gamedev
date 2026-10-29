extends GdUnitTestSuite
## Règles de l'outil de maillage : ses triangles tournent comme Godot le veut (ses normales sont celles que Godot
## calcule lui-même sur les mêmes triangles) ; un tube a un anneau par point et ses deux bouts fermés, et ses normales
## s'écartent de son axe ; une nappe a deux faces aux normales opposées.


func test_ses_triangles_tournent_comme_godot_le_veut() -> void:
	var b: MeshBuilder = MeshBuilder.new()
	b.begin_part()
	b.ellipsoid(Vector3.ZERO, Vector3(1.0, 0.6, 0.8), 8, 12, Color.WHITE)
	b.tube(PackedVector3Array([Vector3(2.0, 0.0, 0.0), Vector3(2.0, 1.0, 0.3), Vector3(2.2, 2.0, 0.5)]),
			PackedFloat32Array([0.2, 0.15, 0.1]), 6, Color.WHITE)
	b.end_part()
	var mesh: ArrayMesh = b.to_mesh()
	var nos_normales: Dictionary[Vector3, Vector3] = {}
	for i: int in b.vertices.size():
		nos_normales[b.vertices[i]] = b.normals[i]
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(mesh, 0)
	st.generate_normals()
	var arrays: Array = st.commit_to_arrays()
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normales: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_int(positions.size()).is_greater(0)
	for i: int in positions.size():
		assert_float(normales[i].dot(nos_normales[positions[i]])).is_greater(0.8)


func test_un_tube_a_un_anneau_par_point_et_ses_bouts_fermes() -> void:
	var b: MeshBuilder = MeshBuilder.new()
	b.begin_part()
	b.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.0, 1.0, 0.0), Vector3(0.0, 2.0, 0.0)]),
			PackedFloat32Array([0.3, 0.3, 0.3]), 6, Color.WHITE)
	b.end_part()
	assert_int(b.vertices.size()).is_equal(3 * 6 + 2)
	assert_int(b.indices.size()).is_equal(3 * (2 * 6 * 2 + 2 * 6))
	for k: int in 6:
		var i: int = 6 + k
		var axe: Vector3 = Vector3(b.vertices[i].x, 0.0, b.vertices[i].z).normalized()
		assert_float(b.normals[i].dot(axe)).is_greater(0.99)


func test_une_nappe_a_deux_faces_aux_normales_opposees() -> void:
	var b: MeshBuilder = MeshBuilder.new()
	var rangees: Array[PackedVector3Array] = []
	var teintes: Array[PackedColorArray] = []
	for r: int in 3:
		var rangee: PackedVector3Array = PackedVector3Array()
		var teinte: PackedColorArray = PackedColorArray()
		for k: int in 4:
			rangee.append(Vector3(k, -r, 0.0))
			teinte.append(Color.WHITE)
		rangees.append(rangee)
		teintes.append(teinte)
	b.begin_part()
	b.sheet(rangees, teintes)
	b.end_part()
	assert_int(b.vertices.size()).is_equal(2 * 12)
	for i: int in 12:
		assert_float(absf(b.normals[i].z)).is_equal_approx(1.0, 0.0001)
		assert_float(b.normals[i].dot(b.normals[i + 12])).is_equal_approx(-1.0, 0.0001)
