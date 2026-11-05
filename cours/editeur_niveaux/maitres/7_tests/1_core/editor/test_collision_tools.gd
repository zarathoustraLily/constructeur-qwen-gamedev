extends GdUnitTestSuite
## La géométrie des collisions : un carré est simple, un nœud papillon (deux côtés croisés) ne l'est pas ; on trouve le
## sommet et le côté les plus proches d'un point, dans un rayon ; ajouter, déplacer et retirer un sommet rendent de
## nouveaux polygones sans toucher à l'original, et une forme garde au moins trois sommets ; le polygone le plus haut
## sous un point est le dernier de la liste.

const SQUARE: PackedVector2Array = [Vector2(0, 0), Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)]
const BOW_TIE: PackedVector2Array = [Vector2(0, 0), Vector2(2, 2), Vector2(2, 0), Vector2(0, 2)]


func test_un_carre_est_simple_un_noeud_papillon_non() -> void:
	assert_bool(CollisionTools.is_simple(SQUARE)).is_true()
	assert_bool(CollisionTools.is_simple(BOW_TIE)).is_false()
	assert_bool(CollisionTools.is_simple(PackedVector2Array([Vector2.ZERO, Vector2.ONE]))).is_false()


func test_le_sommet_et_le_cote_les_plus_proches() -> void:
	assert_int(CollisionTools.nearest_point(SQUARE, Vector2(2.1, 1.9), 0.5)).is_equal(2)
	assert_int(CollisionTools.nearest_point(SQUARE, Vector2(1, 1), 0.5)).is_equal(-1)
	assert_int(CollisionTools.nearest_edge(SQUARE, Vector2(1, -0.1), 0.5)).is_equal(0)
	assert_int(CollisionTools.nearest_edge(SQUARE, Vector2(-0.2, 1), 0.5)).is_equal(3)


func test_les_modifications_rendent_un_nouveau_polygone() -> void:
	var inserted: PackedVector2Array = CollisionTools.inserted_point(SQUARE, 0, Vector2(1, -0.5))
	assert_int(inserted.size()).is_equal(5)
	assert_vector(inserted[1]).is_equal(Vector2(1, -0.5))
	assert_vector(CollisionTools.moved_point(SQUARE, 2, Vector2(3, 3))[2]).is_equal(Vector2(3, 3))
	assert_int(CollisionTools.removed_point(inserted, 1).size()).is_equal(4)
	assert_int(CollisionTools.removed_point(PackedVector2Array(SQUARE.slice(0, 3)), 0).size()).is_equal(3)
	assert_vector(SQUARE[2]).is_equal(Vector2(2, 2))


func test_le_polygone_le_plus_haut_est_le_dernier() -> void:
	var polygons: Array[PackedVector2Array] = [CollisionTools.square(Vector2(1, 1), 10.0), SQUARE]
	assert_int(CollisionTools.polygon_at(polygons, Vector2(1, 1))).is_equal(1)
	assert_int(CollisionTools.polygon_at(polygons, Vector2(4, 4))).is_equal(0)
	assert_int(CollisionTools.polygon_at(polygons, Vector2(40, 40))).is_equal(-1)
