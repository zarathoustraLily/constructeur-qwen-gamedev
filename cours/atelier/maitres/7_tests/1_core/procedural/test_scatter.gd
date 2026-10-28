extends GdUnitTestSuite
## Règles de la répartition : les points restent dans le disque et ne s'entassent pas au centre ; la même graine
## redonne les mêmes points ; un MultiMesh porte une copie par transformation, et une couleur par copie si on lui en
## donne ; les bouffées de nuages restent dans leurs bornes de hauteur et de taille.


func test_les_points_restent_dans_le_disque() -> void:
	for point: Vector2 in Scatter.points_in_disc(500, 10.0, 1):
		assert_float(point.length()).is_less_equal(10.0)


func test_les_points_ne_s_entassent_pas_au_centre() -> void:
	var inside: int = 0
	var points: PackedVector2Array = Scatter.points_in_disc(4000, 10.0, 2)
	for point: Vector2 in points:
		if point.length() < 10.0 / sqrt(2.0):
			inside += 1
	# Le disque intérieur de rayon R/√2 a la moitié de l'aire : environ la moitié des points.
	assert_float(float(inside) / float(points.size())).is_between(0.45, 0.55)


func test_la_meme_graine_redonne_les_memes_points() -> void:
	assert_array(Array(Scatter.points_in_disc(20, 5.0, 3))).is_equal(Array(Scatter.points_in_disc(20, 5.0, 3)))
	assert_bool(Scatter.points_in_disc(20, 5.0, 3) == Scatter.points_in_disc(20, 5.0, 4)).is_false()


## Sans fenêtre, le serveur de rendu est factice : un MultiMesh ne rend pas ses transformations ni ses couleurs
## (get_instance_transform rend l'identité). On vérifie ce qu'il garde lui-même : son maillage, son format, son nombre
## de copies, l'usage des couleurs.
func test_un_multimesh_porte_une_copie_par_transformation() -> void:
	var box: BoxMesh = BoxMesh.new()
	var transforms: Array[Transform3D] = [Transform3D(Basis.IDENTITY, Vector3(1, 2, 3)), Transform3D.IDENTITY]
	var batch: MultiMesh = Scatter.multimesh(box, transforms)
	assert_int(batch.instance_count).is_equal(2)
	assert_int(batch.transform_format).is_equal(MultiMesh.TRANSFORM_3D)
	assert_that(batch.mesh).is_same(box)
	assert_bool(batch.use_colors).is_false()


func test_une_couleur_par_copie() -> void:
	var transforms: Array[Transform3D] = [Transform3D.IDENTITY, Transform3D.IDENTITY]
	var batch: MultiMesh = Scatter.multimesh(BoxMesh.new(), transforms, PackedColorArray([Color.RED, Color.BLUE]))
	assert_bool(batch.use_colors).is_true()
	assert_int(batch.instance_count).is_equal(2)


func test_les_bouffees_restent_dans_leurs_bornes() -> void:
	for t: Transform3D in Scatter.cloud_puffs(200, 50.0, Vector2(30.0, 40.0), Vector2(4.0, 10.0), 5):
		assert_float(t.origin.y).is_between(30.0, 40.0)
		assert_float(t.basis.get_scale().x).is_between(4.0, 10.0)
		assert_float(Vector2(t.origin.x, t.origin.z).length()).is_less_equal(50.0)
