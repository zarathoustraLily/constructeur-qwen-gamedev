extends GdUnitTestSuite
## Règles de la galaxie : les bras partent à intervalles égaux et s'enroulent avec la distance ; les étoiles sont en
## nombre voulu, dans un disque mince ; la couleur va du cœur au bord ; la même graine redonne la même galaxie ; le
## MultiMesh porte une étoile colorée par position.

const SETTINGS := preload("res://5_data/DECORS/NATURE/galaxy.tres")


func test_les_bras_partent_a_intervalles_egaux_et_s_enroulent() -> void:
	assert_float(Galaxy.arm_angle(1, 0.0, SETTINGS)).is_equal_approx(TAU / float(SETTINGS.arms), 0.0001)
	assert_float(Galaxy.arm_angle(0, 1.0, SETTINGS)).is_equal_approx(TAU * SETTINGS.winding, 0.0001)


func test_les_etoiles_sont_dans_un_disque_mince() -> void:
	var points: PackedVector3Array = Galaxy.star_positions(SETTINGS)
	assert_int(points.size()).is_equal(SETTINGS.star_count)
	for point: Vector3 in points:
		assert_float(absf(point.y)).is_less_equal(SETTINGS.thickness)


func test_la_couleur_va_du_coeur_au_bord() -> void:
	assert_that(Galaxy.star_color(0.0, SETTINGS)).is_equal(SETTINGS.core_color)
	assert_that(Galaxy.star_color(SETTINGS.radius, SETTINGS)).is_equal(SETTINGS.edge_color)
	assert_that(Galaxy.star_color(SETTINGS.radius * 5.0, SETTINGS)).is_equal(SETTINGS.edge_color)


func test_la_meme_graine_redonne_la_meme_galaxie() -> void:
	assert_bool(Galaxy.star_positions(SETTINGS) == Galaxy.star_positions(SETTINGS)).is_true()


## Sans fenêtre, un MultiMesh ne rend pas ses transformations (serveur de rendu factice) : on vérifie son nombre
## d'étoiles, ses couleurs activées et son maillage d'étoile.
func test_le_multimesh_porte_une_etoile_coloree_par_position() -> void:
	var batch: MultiMesh = Galaxy.build(SETTINGS)
	assert_int(batch.instance_count).is_equal(SETTINGS.star_count)
	assert_bool(batch.use_colors).is_true()
	assert_object(batch.mesh as SphereMesh).is_not_null()
