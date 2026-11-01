extends GdUnitTestSuite
## Règles de l'outil de maillage d'un pantin : chaque sommet porte quatre os et quatre poids, le premier os est celui
## posé à son ajout, de poids 1 ; une pièce tournée a un anneau par point de son profil, ses deux bouts fermés, ses
## normales qui s'écartent de son axe ; ouverte, elle n'a que ses anneaux ; un sommet partagé garde des poids dont la somme vaut 1 ; le fil du bois suit la pièce, quelle que soit
## sa direction ; le maillage garde ses os, sauf pour une pièce qui ne suit aucun squelette.


const STRAIGHT: PackedVector2Array = [Vector2(0.0, 0.2), Vector2(0.5, 0.3), Vector2(1.0, 0.2)]
const WHITE: PackedColorArray = [Color.WHITE]


func test_chaque_sommet_porte_quatre_os_et_quatre_poids() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.turned(Vector3.ZERO, Vector3.UP, STRAIGHT, WHITE, 6)
	assert_int(b.bones.size()).is_equal(b.vertices.size() * 4)
	assert_int(b.weights.size()).is_equal(b.vertices.size() * 4)


func test_un_sommet_suit_l_os_pose_a_son_ajout_de_tout_son_poids() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.bone = 3
	var first: int = b.add_vertex(Vector3.ZERO, Color.WHITE)
	b.bone = 7
	var second: int = b.add_vertex(Vector3.ONE, Color.WHITE)
	assert_int(b.bones[first * 4]).is_equal(3)
	assert_int(b.bones[second * 4]).is_equal(7)
	assert_float(b.weights[second * 4]).is_equal(1.0)
	assert_float(b.weights[second * 4 + 1]).is_equal(0.0)


func test_une_piece_tournee_a_un_anneau_par_point_et_ses_bouts_fermes() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.turned(Vector3.ZERO, Vector3.UP, STRAIGHT, WHITE, 6)
	assert_int(b.vertices.size()).is_equal(3 * 6 + 2)
	assert_int(b.indices.size()).is_equal(2 * 6 * 6 + 2 * 6 * 3)


func test_ouverte_elle_n_a_que_ses_anneaux() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.turned(Vector3.ZERO, Vector3.UP, STRAIGHT, WHITE, 6, false)
	assert_int(b.vertices.size()).is_equal(3 * 6)
	assert_int(b.indices.size()).is_equal(2 * 6 * 6)


func test_ses_normales_s_ecartent_de_son_axe() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.turned(Vector3.ZERO, Vector3.UP, STRAIGHT, WHITE, 8, false)
	for i: int in range(8, 16):
		var outward: Vector3 = Vector3(b.vertices[i].x, 0.0, b.vertices[i].z).normalized()
		assert_float(b.normals[i].dot(outward)).is_greater(0.9)


func test_les_tons_se_posent_anneau_par_anneau_et_le_dernier_vaut_pour_la_suite() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.turned(Vector3.ZERO, Vector3.UP, STRAIGHT, PackedColorArray([Color.RED, Color.BLUE]), 6, false)
	assert_that(b.colors[0]).is_equal(Color.RED)
	assert_that(b.colors[6]).is_equal(Color.BLUE)
	assert_that(b.colors[12]).is_equal(Color.BLUE)


func test_un_sommet_partage_garde_des_poids_dont_la_somme_vaut_un() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.bone = 2
	var vertex: int = b.add_vertex(Vector3.ZERO, Color.WHITE)
	b.share(vertex, 5, 0.3)
	b.share(vertex, 6, 0.2)
	assert_int(b.bones[vertex * 4 + 1]).is_equal(5)
	assert_int(b.bones[vertex * 4 + 2]).is_equal(6)
	assert_float(b.weights[vertex * 4] + b.weights[vertex * 4 + 1] + b.weights[vertex * 4 + 2]).is_equal_approx(1.0, 0.0001)


func test_le_fil_du_bois_suit_la_piece_quelle_que_soit_sa_direction() -> void:
	for to: Vector3 in [Vector3.UP * 2.0, Vector3.RIGHT * 2.0, Vector3(1.0, 1.0, 1.0).normalized() * 2.0]:
		var b: PuppetBuilder = PuppetBuilder.new()
		b.turned(Vector3.ZERO, to, PackedVector2Array([Vector2(0.0, 0.2), Vector2(1.0, 0.2)]), WHITE, 6, false)
		assert_float(absf(b.uvs[6].y - b.uvs[0].y)).is_equal_approx(2.0 * PuppetBuilder.UV_PER_METER, 0.001)


func test_le_maillage_garde_ses_os_sauf_pour_une_piece_sans_squelette() -> void:
	var b: PuppetBuilder = PuppetBuilder.new()
	b.turned(Vector3.ZERO, Vector3.UP, STRAIGHT, WHITE, 6)
	var arrays: Array = b.to_mesh().surface_get_arrays(0)
	assert_int((arrays[Mesh.ARRAY_BONES] as PackedInt32Array).size()).is_equal(b.vertices.size() * 4)
	b.skinned = false
	assert_object(b.to_mesh().surface_get_arrays(0)[Mesh.ARRAY_BONES]).is_null()
