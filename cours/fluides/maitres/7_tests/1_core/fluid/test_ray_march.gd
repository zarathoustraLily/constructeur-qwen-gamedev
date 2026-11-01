extends GdUnitTestSuite
## Règles d'un rayon : il entre et sort là où passent les plans de la boîte ; il part de zéro s'il naît dedans ; une boîte derrière lui
## ou à côté ne compte pas ; la lumière suit une exponentielle, et deux longueurs de fumée se multiplient.

const HALF := Vector3(0.5, 0.5, 0.5)


func test_un_rayon_droit_traverse_toute_la_boite() -> void:
	var hits: Vector2 = RayMarch.box_hits(Vector3(0.0, 0.0, 3.0), Vector3(0.0, 0.0, -1.0), HALF)
	assert_vector(hits).is_equal_approx(Vector2(2.5, 3.5), Vector2(0.0001, 0.0001))


func test_un_rayon_en_diagonale_traverse_la_diagonale() -> void:
	var direction: Vector3 = Vector3(1.0, 1.0, 1.0).normalized()
	var hits: Vector2 = RayMarch.box_hits(-direction * 2.0, direction, HALF)
	assert_float(hits.y - hits.x).is_equal_approx(sqrt(3.0), 0.0001)


func test_un_rayon_ne_dans_la_boite_part_de_zero() -> void:
	var hits: Vector2 = RayMarch.box_hits(Vector3(0.0, 0.0, 0.25), Vector3(0.0, 0.0, -1.0), HALF)
	assert_vector(hits).is_equal_approx(Vector2(0.0, 0.75), Vector2(0.0001, 0.0001))


func test_une_boite_manquee_rend_moins_un() -> void:
	var hits: Vector2 = RayMarch.box_hits(Vector3(2.0, 0.0, 3.0), Vector3(0.0, 0.0, -1.0), HALF)
	assert_vector(hits).is_equal(Vector2(-1.0, -1.0))


func test_une_boite_derriere_le_rayon_ne_compte_pas() -> void:
	var hits: Vector2 = RayMarch.box_hits(Vector3(0.0, 0.0, 3.0), Vector3(0.0, 0.0, 1.0), HALF)
	assert_vector(hits).is_equal(Vector2(-1.0, -1.0))


func test_sans_matiere_toute_la_lumiere_passe() -> void:
	assert_float(RayMarch.transmittance(PackedFloat32Array([0.0, 0.0]), 0.5, 8.0)).is_equal(1.0)


func test_la_lumiere_suit_une_exponentielle() -> void:
	var passe: float = RayMarch.transmittance(PackedFloat32Array([0.5, 0.5, 0.5, 0.5]), 0.25, 2.0)
	assert_float(passe).is_equal_approx(exp(-1.0), 0.0001)


func test_deux_longueurs_de_fumee_se_multiplient() -> void:
	var une: float = RayMarch.transmittance(PackedFloat32Array([1.0]), 0.5, 3.0)
	var deux: float = RayMarch.transmittance(PackedFloat32Array([1.0, 1.0]), 0.5, 3.0)
	assert_float(deux).is_equal_approx(une * une, 0.0001)
