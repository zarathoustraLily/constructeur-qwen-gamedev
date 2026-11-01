extends GdUnitTestSuite
## Règles du solveur : un fluide au repos ne bouge pas ; une poussée emporte la matière ; il ne reste presque pas de divergence
## après un pas ; la matière se perd au rythme voulu ; un pas ne crée aucun objet.
#@ 6+
## La matière ne passe pas un mur.
#@ 7+
## Le transport fin garde la matière plus nette.
#@ 8+
## Le confinement garde plus de rotation.
#@ 9+
## Un feu allumé brûle son carburant, et sa chaleur monte.
#@ all


func _reglages(taille: int = 32) -> FluidSettings:
	var reglages: FluidSettings = FluidSettings.new()
	reglages.width = taille
	reglages.height = taille
	reglages.iterations = 30
	reglages.dissipation = 0.0
#@ 7+
	reglages.sharp_transport = false
#@ 8+
	reglages.vortex_strength = 0.0
#@ all
	return reglages


func _centre(champ: FluidField) -> Vector2:
	var somme: Vector2 = Vector2.ZERO
	for y: int in champ.height:
		for x: int in champ.width:
			somme += Vector2(x, y) * champ.at(x, y)
	return somme / champ.total()


func test_un_fluide_au_repos_ne_bouge_pas() -> void:
	var fluide: FluidSolver = FluidSolver.new(_reglages())
	fluide.density.add_disc(16.0, 16.0, 5.0, 1.0)
	var avant: float = fluide.density.at(16, 16)
	fluide.step(0.1)
	assert_float(fluide.density.at(16, 16)).is_equal_approx(avant, 0.001)


func test_une_poussee_emporte_la_matiere() -> void:
	var fluide: FluidSolver = FluidSolver.new(_reglages())
	fluide.density.add_disc(10.0, 16.0, 5.0, 1.0)
	var avant: float = _centre(fluide.density).x
	for _i: int in 8:
		fluide.add_force(10.0, 16.0, 6.0, 10.0, 0.0)
		fluide.step(0.1)
	assert_float(_centre(fluide.density).x).is_greater(avant + 1.0)


func test_il_ne_reste_presque_pas_de_divergence() -> void:
	var fluide: FluidSolver = FluidSolver.new(_reglages())
	fluide.add_force(16.0, 16.0, 8.0, 12.0, 4.0)
	var sortie: FluidField = FluidField.new(32, 32)
#@ 5
	FluidProjection.divergence(sortie, fluide.u, fluide.v)
#@ 6+
	FluidProjection.divergence(sortie, fluide.u, fluide.v, fluide.walls)
#@ all
	var avant: float = sortie.peak()
	fluide.step(0.05)
#@ 5
	FluidProjection.divergence(sortie, fluide.u, fluide.v)
#@ 6+
	FluidProjection.divergence(sortie, fluide.u, fluide.v, fluide.walls)
#@ all
	assert_float(sortie.peak()).is_less(avant)


func test_la_matiere_se_perd_au_rythme_voulu() -> void:
	var reglages: FluidSettings = _reglages()
	reglages.dissipation = 1.0
	var fluide: FluidSolver = FluidSolver.new(reglages)
	fluide.density.add_disc(16.0, 16.0, 5.0, 1.0)
	var avant: float = fluide.density.total()
	fluide.step(0.5)
	assert_float(fluide.density.total()).is_equal_approx(avant * exp(-0.5), 0.01 * avant)


func test_un_pas_ne_cree_aucun_objet() -> void:
	var fluide: FluidSolver = FluidSolver.new(_reglages(16))
	fluide.step(0.05)
	var avant: float = Performance.get_monitor(Performance.OBJECT_COUNT)
	for _i: int in 5:
		fluide.step(0.05)
	assert_float(Performance.get_monitor(Performance.OBJECT_COUNT)).is_equal(avant)
#@ 6+


func test_la_matiere_ne_passe_pas_un_mur() -> void:
	var fluide: FluidSolver = FluidSolver.new(_reglages())
	fluide.walls.add_box(20, 0, 22, 31)
	fluide.density.add_disc(14.0, 16.0, 5.0, 1.0)
	for _i: int in 12:
		fluide.add_force(14.0, 16.0, 6.0, 12.0, 0.0)
		fluide.step(0.1)
	var derriere: float = 0.0
	for y: int in 32:
		for x: int in range(23, 32):
			derriere += fluide.density.at(x, y)
	assert_float(derriere).is_less(0.01)
#@ 7+


## Le plus haut de la matière après un transport sous une vitesse uniforme.
func _net(fin: bool) -> float:
	var reglages: FluidSettings = _reglages(48)
	reglages.sharp_transport = fin
	var fluide: FluidSolver = FluidSolver.new(reglages)
	fluide.density.add_disc(12.0, 24.0, 5.0, 1.0)
	for _i: int in 6:
		fluide.add_force(12.0, 24.0, 14.0, 6.0, 0.0)
		fluide.step(0.2)
	return fluide.density.peak()


func test_le_transport_fin_garde_la_matiere_plus_nette() -> void:
	assert_float(_net(true)).is_greater(_net(false))
#@ 8+


## La plus forte rotation qui reste d'un tourbillon, après quelques pas.
func _rotation(force: float) -> float:
	var reglages: FluidSettings = _reglages()
	reglages.vortex_strength = force
	var fluide: FluidSolver = FluidSolver.new(reglages)
	fluide.add_force(16.0, 12.0, 5.0, 8.0, 0.0)
	fluide.add_force(16.0, 20.0, 5.0, -8.0, 0.0)
	for _i: int in 10:
		fluide.step(0.1)
	var spin: FluidField = FluidField.new(32, 32)
	Vorticity.curl(spin, fluide.u, fluide.v)
	return spin.peak()


func test_le_confinement_garde_plus_de_rotation() -> void:
	assert_float(_rotation(6.0)).is_greater(_rotation(0.0))
#@ 9+


func _feu() -> FluidSolver:
	var fluide: FluidSolver = FluidSolver.new(_reglages())
	var feu: FireSettings = FireSettings.new()
	feu.ignition = 0.2
	feu.burn_rate = 2.0
	fluide.fire = feu
	fluide.fuel.add_disc(16.0, 24.0, 5.0, 1.0)
	fluide.temperature.add_disc(16.0, 24.0, 5.0, 1.0)
	return fluide


func test_un_feu_allume_brule_son_carburant() -> void:
	var fluide: FluidSolver = _feu()
	var avant: float = fluide.fuel.total()
	for _i: int in 5:
		fluide.step(0.05)
	assert_float(fluide.fuel.total()).is_less(avant * 0.9)
	assert_float(fluide.soot.total()).is_greater(0.0)


func test_sa_chaleur_monte() -> void:
	var fluide: FluidSolver = _feu()
	var avant: float = _centre(fluide.temperature).y
	for _i: int in 10:
		fluide.step(0.05)
	assert_float(_centre(fluide.temperature).y).is_less(avant - 0.5)


func test_sans_feu_le_carburant_ne_bouge_pas() -> void:
	var fluide: FluidSolver = FluidSolver.new(_reglages())
	fluide.step(0.05)
	assert_float(fluide.fuel.total()).is_equal(0.0)
#@ all
