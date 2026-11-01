extends GdUnitTestSuite
## Règles de la surface : une eau plate reste plate ; une onde ne crée pas d'eau ; elle va à sa vitesse, de façon égale dans les deux axes ;
## un grand pas se découpe et n'explose pas ; le bord renvoie l'onde ; l'amortissement calme l'eau.

const SIZE := 48
const MIDDLE := 24.0


func _solver(speed: float, damping: float) -> WaveSolver:
	var settings: WaveSettings = WaveSettings.new()
	settings.width = SIZE
	settings.height = SIZE
	settings.speed = speed
	settings.damping = damping
	return WaveSolver.new(settings)


## La case de droite où l'onde est la plus haute, au-delà de `from`, sur la ligne du milieu.
func _crest(solver: WaveSolver, from: int) -> int:
	var best: int = from
	for x: int in range(from, SIZE):
		if solver.surface.at(x, int(MIDDLE)) > solver.surface.at(best, int(MIDDLE)):
			best = x
	return best


func test_une_eau_plate_reste_plate() -> void:
	var solver: WaveSolver = _solver(20.0, 1.0)
	solver.step(0.1)
	assert_float(solver.surface.peak()).is_equal(0.0)


func test_les_sous_pas_gardent_l_onde_sous_la_limite() -> void:
	assert_int(WaveSolver.substeps(1.0 / 60.0, 60.0)).is_equal(2)
	assert_int(WaveSolver.substeps(0.001, 60.0)).is_equal(1)
	assert_float(1.0 / WaveSolver.substeps(1.0, 300.0) * 300.0).is_less_equal(WaveSolver.MAX_COURANT)


func test_une_onde_ne_cree_pas_d_eau() -> void:
	var solver: WaveSolver = _solver(20.0, 1.0)
	solver.drop(MIDDLE, MIDDLE, 5.0, 1.0)
	var depart: float = solver.surface.total()
	for _pas: int in 20:
		solver.step(1.0 / 60.0)
	assert_float(solver.surface.total()).is_equal_approx(depart, 0.01)


func test_une_onde_va_a_sa_vitesse() -> void:
	var solver: WaveSolver = _solver(20.0, 1.0)
	solver.drop(MIDDLE, MIDDLE, 3.0, 1.0)
	for _pas: int in 30:
		solver.step(1.0 / 60.0)
	assert_int(_crest(solver, int(MIDDLE) + 4)).is_between(int(MIDDLE) + 7, int(MIDDLE) + 11)


func test_une_onde_est_la_meme_dans_les_deux_axes() -> void:
	var solver: WaveSolver = _solver(20.0, 1.0)
	solver.drop(MIDDLE, MIDDLE, 4.0, 1.0)
	for _pas: int in 12:
		solver.step(1.0 / 60.0)
	for k: int in range(1, 12):
		var droite: float = solver.surface.at(int(MIDDLE) + k, int(MIDDLE))
		assert_float(solver.surface.at(int(MIDDLE) - k, int(MIDDLE))).is_equal_approx(droite, 0.001)
		assert_float(solver.surface.at(int(MIDDLE), int(MIDDLE) + k)).is_equal_approx(droite, 0.001)


func test_un_grand_pas_n_explose_pas() -> void:
	var solver: WaveSolver = _solver(60.0, 1.0)
	solver.drop(MIDDLE, MIDDLE, 5.0, 1.0)
	solver.step(0.5)
	assert_float(solver.surface.peak()).is_less_equal(1.0)


func test_le_bord_renvoie_l_onde() -> void:
	var solver: WaveSolver = _solver(20.0, 1.0)
	solver.drop(6.0, MIDDLE, 3.0, 1.0)
	for _pas: int in 40:
		solver.step(1.0 / 60.0)
	assert_float(solver.surface.at(0, int(MIDDLE))).is_not_equal(0.0)
	assert_float(solver.surface.at(18, int(MIDDLE))).is_not_equal(0.0)
	assert_float(solver.surface.total()).is_equal_approx(_disc_total(), 0.01)


func test_l_amortissement_calme_l_eau() -> void:
	var libre: WaveSolver = _solver(20.0, 1.0)
	var freinee: WaveSolver = _solver(20.0, 0.9)
	for solver: WaveSolver in [libre, freinee]:
		solver.drop(MIDDLE, MIDDLE, 5.0, 1.0)
		for _pas: int in 30:
			solver.step(1.0 / 60.0)
	assert_float(freinee.surface.peak()).is_less(libre.surface.peak())


## La quantité d'eau d'une goutte de rayon 3 posée à gauche.
func _disc_total() -> float:
	var solver: WaveSolver = _solver(20.0, 1.0)
	solver.drop(6.0, MIDDLE, 3.0, 1.0)
	return solver.surface.total()
