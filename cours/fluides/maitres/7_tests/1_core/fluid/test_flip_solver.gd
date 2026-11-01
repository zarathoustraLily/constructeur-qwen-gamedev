extends GdUnitTestSuite
## Règles de FLIP. Une particule dépose sa vitesse sur les faces autour d'elle, et une vitesse uniforme passe sur la grille et revient
## intacte. Une case avec une particule est pleine. La gravité tire vers le bas ; personne ne sort de la cuve. Un barrage qui cède
## s'étale ; une eau au repos reste au repos ; FLIP garde plus de mouvement que PIC.

const DELTA := 1.0 / 60.0


func _settings(flip: float) -> FlipSettings:
	var settings: FlipSettings = FlipSettings.new()
	settings.width = 24
	settings.height = 18
	settings.gravity = 60.0
	settings.iterations = 30
	settings.relaxation = 1.6
	settings.flip_ratio = flip
	return settings


## Un barrage : une colonne d'eau contre le mur de gauche.
func _dam(flip: float) -> FlipSolver:
	var solver: FlipSolver = FlipSolver.new(_settings(flip))
	solver.add_block(Vector2(0.0, 6.0), Vector2(8.0, 17.0), 0.5)
	return solver


func _center(solver: FlipSolver) -> Vector2:
	var sum: Vector2 = Vector2.ZERO
	for place: Vector2 in solver.positions:
		sum += place
	return sum / solver.positions.size()


func _energy(solver: FlipSolver) -> float:
	var sum: float = 0.0
	for speed: Vector2 in solver.velocities:
		sum += speed.length_squared()
	return sum / solver.velocities.size()


func test_un_bloc_pose_une_particule_tous_les_pas_d_espacement() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(0.95))
	solver.add_block(Vector2(1.0, 2.0), Vector2(2.0, 3.0), 0.5)
	assert_int(solver.positions.size()).is_equal(9)
	assert_bool(solver.positions[8].is_equal_approx(Vector2(2.0, 3.0))).is_true()
	assert_bool(solver.velocities[0].is_zero_approx()).is_true()


func test_une_particule_depose_sa_vitesse_sur_les_faces_autour_d_elle() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(0.95))
	solver.positions.append(Vector2(5.0, 5.0))
	solver.velocities.append(Vector2(3.0, -2.0))
	solver.call("_to_grid")
	assert_float(solver.grid.u.at(5, 5)).is_equal_approx(3.0, 0.0001)
	assert_float(solver.grid.u.at(6, 5)).is_equal_approx(3.0, 0.0001)
	assert_float(solver.grid.v.at(5, 5)).is_equal_approx(-2.0, 0.0001)
	assert_float(solver.grid.v.at(5, 6)).is_equal_approx(-2.0, 0.0001)
	assert_float(solver.grid.u.at(9, 5)).is_equal(0.0)


func test_deux_particules_font_la_moyenne_sur_leur_face() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(0.95))
	solver.positions.append(Vector2(5.0, 5.0))
	solver.velocities.append(Vector2(2.0, 0.0))
	solver.positions.append(Vector2(5.0, 5.0))
	solver.velocities.append(Vector2(6.0, 0.0))
	solver.call("_to_grid")
	assert_float(solver.grid.u.at(5, 5)).is_equal_approx(4.0, 0.0001)


func test_une_vitesse_uniforme_passe_sur_la_grille_et_revient_intacte() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(0.0))
	solver.add_block(Vector2(4.0, 4.0), Vector2(10.0, 10.0), 0.5)
	for i: int in solver.velocities.size():
		solver.velocities[i] = Vector2(3.0, -1.0)
	solver.call("_to_grid")
	solver.call("_to_particles")
	assert_float(solver.velocities[20].x).is_equal_approx(3.0, 0.001)
	assert_float(solver.velocities[20].y).is_equal_approx(-1.0, 0.001)


func test_flip_ne_reprend_que_ce_qui_a_change_sur_la_grille() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(1.0))
	solver.add_block(Vector2(4.0, 4.0), Vector2(10.0, 10.0), 0.5)
	solver.velocities[20] = Vector2(7.0, 0.0)
	solver.call("_to_grid")
	var before_u: FluidField = solver.get("_before_u")
	before_u.copy_from(solver.grid.u)
	var before_v: FluidField = solver.get("_before_v")
	before_v.copy_from(solver.grid.v)
	solver.call("_to_particles")
	assert_float(solver.velocities[20].x).is_equal_approx(7.0, 0.001)


func test_une_case_avec_une_particule_est_pleine() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(0.95))
	solver.positions.append(Vector2(3.2, 7.8))
	solver.velocities.append(Vector2.ZERO)
	solver.call("_mark_water")
	assert_bool(solver.is_full(3, 8)).is_true()
	assert_bool(solver.is_full(4, 8)).is_false()
	assert_bool(solver.is_full(3, 7)).is_false()


func test_la_gravite_tire_vers_le_bas() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(0.95))
	solver.add_block(Vector2(10.0, 4.0), Vector2(12.0, 6.0), 0.5)
	var depart: Vector2 = _center(solver)
	for _pas: int in 6:
		solver.step(DELTA)
	assert_float(_center(solver).y).is_greater(depart.y)
	assert_float(solver.velocities[0].y).is_greater(0.0)


func test_personne_ne_sort_de_la_cuve() -> void:
	var solver: FlipSolver = _dam(0.95)
	for _pas: int in 30:
		solver.step(DELTA)
	for place: Vector2 in solver.positions:
		assert_bool(place.x >= -0.5 and place.y >= -0.5 and place.x <= 23.5 and place.y <= 17.5).is_true()


func test_un_barrage_qui_cede_s_etale() -> void:
	var solver: FlipSolver = _dam(0.95)
	var depart: Vector2 = _center(solver)
	for _pas: int in 40:
		solver.step(DELTA)
	assert_float(_center(solver).x).is_greater(depart.x + 1.0)
	assert_float(_center(solver).y).is_greater(depart.y)


func test_une_eau_au_repos_reste_au_repos() -> void:
	var solver: FlipSolver = FlipSolver.new(_settings(0.95))
	solver.add_block(Vector2(-0.25, 11.0), Vector2(23.25, 17.25), 0.5)
	for _pas: int in 20:
		solver.step(DELTA)
	assert_float(sqrt(_energy(solver))).is_less(6.0)


func test_flip_garde_plus_de_mouvement_que_pic() -> void:
	var flip: FlipSolver = _dam(0.97)
	var pic: FlipSolver = _dam(0.0)
	for _pas: int in 30:
		flip.step(DELTA)
		pic.step(DELTA)
	assert_float(_energy(flip)).is_greater(_energy(pic))
