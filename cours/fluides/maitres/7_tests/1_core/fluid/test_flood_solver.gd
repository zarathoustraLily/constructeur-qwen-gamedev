extends GdUnitTestSuite
## Règles de l'eau peu profonde : l'eau ne se perd jamais ; une profondeur n'est jamais négative ; un lac au repos sur un fond bosselé reste
## au repos, parce que l'eau suit son niveau et non le sol ; elle descend la pente ; un barrage qui cède égalise les niveaux ; un mur la
## retient ; une terre sèche ne donne rien.

const SIZE := 32


func _settings() -> FloodSettings:
	var settings: FloodSettings = FloodSettings.new()
	settings.width = SIZE
	settings.height = SIZE
	settings.pull = 100.0
	settings.friction = 0.98
	return settings


func _flat() -> FluidField:
	return FluidField.new(SIZE, SIZE)


func _run(solver: FloodSolver, steps: int) -> void:
	for _pas: int in steps:
		solver.step(1.0 / 30.0)


## Le centre de l'eau sur l'axe x.
func _center_x(field: FluidField) -> float:
	var weighted: float = 0.0
	for y: int in field.height:
		for x: int in field.width:
			weighted += field.at(x, y) * x
	return weighted / field.total()


func test_l_eau_ne_se_perd_jamais() -> void:
	var solver: FloodSolver = FloodSolver.new(_settings(), _flat())
	solver.add_water(16.0, 16.0, 8.0, 2.0)
	var depart: float = solver.depth.total()
	_run(solver, 30)
	assert_float(solver.depth.total()).is_equal_approx(depart, 0.01)


func test_une_profondeur_n_est_jamais_negative() -> void:
	var pente: FluidField = _flat()
	for y: int in SIZE:
		for x: int in SIZE:
			pente.put(x, y, (SIZE - x) * 0.3)
	var solver: FloodSolver = FloodSolver.new(_settings(), pente)
	solver.add_water(24.0, 16.0, 6.0, 0.05)
	_run(solver, 30)
	for profondeur: float in solver.depth.data:
		assert_float(profondeur).is_greater_equal(-0.0001)


func test_un_lac_au_repos_reste_au_repos() -> void:
	var fond: FluidField = _flat()
	for y: int in SIZE:
		for x: int in SIZE:
			fond.put(x, y, 0.5 + 0.4 * sin(x * 0.7) * cos(y * 0.5))
	var solver: FloodSolver = FloodSolver.new(_settings(), fond)
	for y: int in SIZE:
		for x: int in SIZE:
			solver.depth.put(x, y, 2.0 - fond.at(x, y))
	_run(solver, 20)
	for y: int in SIZE:
		for x: int in SIZE:
			assert_float(solver.level(x, y)).is_equal_approx(2.0, 0.0001)


## Un arrondi peut laisser une case à -0,000000001. Sans débit à réduire, la division donnerait l'infini, et zéro fois l'infini un NaN qui gagne toute la grille.
func test_une_profondeur_a_peine_negative_ne_casse_rien() -> void:
	var solver: FloodSolver = FloodSolver.new(_settings(), _flat())
	solver.depth.put(8, 8, -0.000000001)
	solver.step(1.0 / 30.0)
	assert_bool(is_nan(solver.depth.total())).is_false()


## Quand le courant s'inverse, la poussée compte double. Sans en tenir compte, à 300 et en un seul pas, la surface bout en damier : 259 au lieu de 7.
func test_une_forte_poussee_garde_une_surface_lisse() -> void:
	var settings: FloodSettings = _settings()
	settings.pull = 300.0
	var solver: FloodSolver = FloodSolver.new(settings, _flat())
	solver.add_water(16.0, 16.0, 8.0, 2.0)
	_run(solver, 60)
	var rough: float = 0.0
	for y: int in SIZE:
		for x: int in SIZE - 1:
			rough += absf(solver.depth.at(x + 1, y) - solver.depth.at(x, y))
	assert_float(rough).is_less(30.0)


func test_l_eau_descend_la_pente() -> void:
	var pente: FluidField = _flat()
	for y: int in SIZE:
		for x: int in SIZE:
			pente.put(x, y, x * 0.1)
	var solver: FloodSolver = FloodSolver.new(_settings(), pente)
	solver.add_water(20.0, 16.0, 6.0, 1.0)
	var depart: float = _center_x(solver.depth)
	_run(solver, 15)
	assert_float(_center_x(solver.depth)).is_less(depart - 1.0)


func test_un_barrage_qui_cede_egalise_les_niveaux() -> void:
	var solver: FloodSolver = FloodSolver.new(_settings(), _flat())
	for y: int in SIZE:
		for x: int in range(0, 16):
			solver.depth.put(x, y, 1.0)
	_run(solver, 150)
	assert_float(solver.depth.at(4, 16)).is_equal_approx(solver.depth.at(28, 16), 0.1)
	assert_float(solver.depth.at(28, 16)).is_greater(0.3)


func test_un_mur_retient_l_eau() -> void:
	var sol: FluidField = _flat()
	for y: int in SIZE:
		sol.put(16, y, 10.0)
	var solver: FloodSolver = FloodSolver.new(_settings(), sol)
	solver.add_water(8.0, 16.0, 6.0, 2.0)
	_run(solver, 40)
	for y: int in SIZE:
		for x: int in range(17, SIZE):
			assert_float(solver.depth.at(x, y)).is_equal(0.0)


func test_une_terre_seche_ne_donne_rien() -> void:
	var pente: FluidField = _flat()
	for y: int in SIZE:
		for x: int in SIZE:
			pente.put(x, y, x * 0.1)
	var solver: FloodSolver = FloodSolver.new(_settings(), pente)
	_run(solver, 5)
	assert_float(solver.depth.total()).is_equal(0.0)


func test_le_bord_est_un_mur() -> void:
	var solver: FloodSolver = FloodSolver.new(_settings(), _flat())
	solver.add_water(2.0, 2.0, 4.0, 2.0)
	var depart: float = solver.depth.total()
	_run(solver, 20)
	assert_float(solver.depth.total()).is_equal_approx(depart, 0.01)
