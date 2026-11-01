extends GdUnitTestSuite
## Règles de SPH. La grille de voisinage trouve les mêmes voisines qu'une recherche complète. Au milieu d'un bloc à l'écart de départ, la
## densité est celle de repos. La pression reste à zéro sous cette densité. Deux particules trop proches se repoussent, par des forces
## opposées ; la viscosité rapproche leurs vitesses. Un bloc s'étale sous la gravité, personne ne sort de la cuve, et un mur renvoie.

const DELTA := 1.0 / 60.0


func _settings() -> SphSettings:
	var settings: SphSettings = SphSettings.new()
	settings.width = 16.0
	settings.height = 12.0
	settings.radius = 1.0
	settings.spacing = 0.5
	settings.rest_density = 1.0
	settings.stiffness = 60.0
	settings.viscosity = 0.2
	settings.gravity = 20.0
	settings.substeps = 4
	settings.bounce = 0.3
	return settings


## Un bloc de liquide au repos, loin des parois.
func _block() -> SphSolver:
	var solver: SphSolver = SphSolver.new(_settings())
	solver.add_block(Vector2(4.0, 4.0), Vector2(9.0, 9.0))
	solver.rebuild_neighbours()
	return solver


func _pair(gap: float) -> SphSolver:
	var solver: SphSolver = SphSolver.new(_settings())
	solver.add_block(Vector2(6.0, 6.0), Vector2(6.0, 6.0))
	solver.add_block(Vector2(6.0 + gap, 6.0), Vector2(6.0 + gap, 6.0))
	solver.rebuild_neighbours()
	return solver


func test_un_bloc_pose_une_particule_a_chaque_ecart() -> void:
	assert_int(_block().positions.size()).is_equal(121)


func test_une_particule_tombe_dans_la_bonne_case() -> void:
	var solver: SphSolver = SphSolver.new(_settings())
	assert_bool(solver.cell_of(Vector2(3.5, 2.5)) == Vector2i(3, 2)).is_true()
	assert_bool(solver.cell_of(Vector2(16.0, -1.0)) == Vector2i(15, 0)).is_true()


func test_la_grille_trouve_les_memes_voisines_qu_une_recherche_complete() -> void:
	var solver: SphSolver = _block()
	var place: Vector2 = solver.positions[60]
	var attendues: Array[int] = []
	for j: int in solver.positions.size():
		if place.distance_squared_to(solver.positions[j]) < 1.0:
			attendues.append(j)
	var trouvees: Array = Array(solver.neighbours_of(place))
	trouvees.sort()
	assert_array(trouvees).is_equal(attendues)


func test_au_milieu_du_bloc_la_densite_est_celle_de_repos() -> void:
	var solver: SphSolver = _block()
	solver.update_densities()
	assert_float(solver.densities[60]).is_equal_approx(1.0, 0.2)


func test_au_bord_du_bloc_la_densite_est_plus_faible() -> void:
	var solver: SphSolver = _block()
	solver.update_densities()
	assert_float(solver.densities[0]).is_less(solver.densities[60])


func test_sous_la_densite_de_repos_la_pression_reste_a_zero() -> void:
	var solver: SphSolver = _pair(0.9)
	solver.update_densities()
	assert_float(solver.densities[0]).is_less(1.0)
	assert_float(solver.pressures[0]).is_equal(0.0)


func test_deux_particules_trop_proches_se_repoussent_par_des_forces_opposees() -> void:
	var solver: SphSolver = _pair(0.05)
	solver.densities[0] = 2.0
	solver.densities[1] = 2.0
	solver.pressures[0] = 10.0
	solver.pressures[1] = 10.0
	var sur_la_premiere: Vector2 = solver.call("_force_between", 0, 1)
	var sur_la_seconde: Vector2 = solver.call("_force_between", 1, 0)
	assert_float(sur_la_premiere.x).is_less(0.0)
	assert_float(sur_la_seconde.x).is_equal_approx(-sur_la_premiere.x, 0.0001)


func test_la_viscosite_rapproche_les_vitesses() -> void:
	var solver: SphSolver = _pair(0.5)
	solver.densities[0] = 1.0
	solver.densities[1] = 1.0
	solver.velocities[0] = Vector2(0.0, 0.0)
	solver.velocities[1] = Vector2(4.0, 0.0)
	var force: Vector2 = solver.call("_force_between", 0, 1)
	assert_float(force.x).is_greater(0.0)


func test_un_bloc_s_etale_sous_la_gravite() -> void:
	var solver: SphSolver = SphSolver.new(_settings())
	solver.add_block(Vector2(0.25, 6.0), Vector2(4.0, 11.75))
	var large: float = 0.0
	for _pas: int in 40:
		solver.step(DELTA)
	for place: Vector2 in solver.positions:
		large = maxf(large, place.x)
	assert_float(large).is_greater(5.0)


func test_personne_ne_sort_de_la_cuve() -> void:
	var solver: SphSolver = SphSolver.new(_settings())
	solver.add_block(Vector2(0.25, 6.0), Vector2(4.0, 11.75))
	for _pas: int in 30:
		solver.step(DELTA)
	for place: Vector2 in solver.positions:
		assert_bool(place.x >= 0.0 and place.y >= 0.0 and place.x <= 16.0 and place.y <= 12.0).is_true()


func test_un_mur_renvoie_ce_qui_le_touche() -> void:
	var solver: SphSolver = _pair(5.0)
	solver.positions[0] = Vector2(0.01, 6.0)
	solver.velocities[0] = Vector2(-10.0, 0.0)
	solver.call("_integrate", 0.1)
	assert_float(solver.positions[0].x).is_equal(0.0)
	assert_float(solver.velocities[0].x).is_equal_approx(3.0, 0.0001)
