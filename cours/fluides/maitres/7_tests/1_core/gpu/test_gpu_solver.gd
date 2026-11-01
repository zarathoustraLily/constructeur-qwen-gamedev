extends GdUnitTestSuite
## Règles du solveur sur la carte : pas après pas, sources et murs compris, il suit le solveur du processeur, transport simple
## comme corrigé, avec tourbillons, et avec un fluide épais ; un fluide au repos sans source reste au repos ; rien n'entre dans
## un mur.
#@ 15+
## Avec un feu, il suit aussi le processeur, et la flamme monte.
#@ all

const WIDTH := 40
const HEIGHT := 30
const CLOSE := 0.002

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	_device.release()


func _settings(sharp: bool, vortex: float) -> FluidSettings:
	var settings: FluidSettings = FluidSettings.new()
	settings.width = WIDTH
	settings.height = HEIGHT
	settings.iterations = 12
	settings.relaxation = 1.7
	settings.dissipation = 0.3
	settings.sharp_transport = sharp
	settings.vortex_strength = vortex
	return settings


## Une même source, un même mur, `steps` pas : (solveur du processeur, solveur de la carte).
func _both(settings: FluidSettings, steps: int) -> Array[RefCounted]:
	var cpu: FluidSolver = FluidSolver.new(settings)
	var gpu: GpuSolver = GpuSolver.new(_device, settings)
	cpu.walls.add_box(18, 12, 24, 14)
	gpu.walls.add_box(18, 12, 24, 14)
	gpu.update_walls()
	for _step: int in steps:
		cpu.density.add_disc(20.0, 24.0, 5.0, 1.0)
		gpu.add_matter(gpu.density, 20.0, 24.0, 5.0, 1.0)
		cpu.add_force(20.0, 24.0, 5.0, 0.0, -6.0)
		gpu.add_force(20.0, 24.0, 5.0, 0.0, -6.0)
		cpu.step(0.1)
		gpu.step(0.1)
	return [cpu, gpu]


func _gap(cpu: FluidField, texture: RID) -> float:
	return GridCheck.largest_gap(GridCheck.read(_device, texture, WIDTH, HEIGHT), cpu)


func test_il_suit_le_processeur_avec_le_transport_simple() -> void:
	var pair: Array[RefCounted] = _both(_settings(false, 0.0), 6)
	var cpu: FluidSolver = pair[0]
	var gpu: GpuSolver = pair[1]
	assert_float(_gap(cpu.density, gpu.density)).is_less(CLOSE)
	assert_float(_gap(cpu.u, gpu.u)).is_less(CLOSE)
	assert_float(_gap(cpu.v, gpu.v)).is_less(CLOSE)


func test_il_suit_le_processeur_avec_mac_cormack() -> void:
	var pair: Array[RefCounted] = _both(_settings(true, 0.0), 6)
	var cpu: FluidSolver = pair[0]
	var gpu: GpuSolver = pair[1]
	assert_float(_gap(cpu.density, gpu.density)).is_less(CLOSE)
	assert_float(_gap(cpu.v, gpu.v)).is_less(CLOSE)


func test_il_suit_le_processeur_avec_les_tourbillons() -> void:
	var pair: Array[RefCounted] = _both(_settings(true, 4.0), 6)
	var cpu: FluidSolver = pair[0]
	var gpu: GpuSolver = pair[1]
	assert_float(_gap(cpu.density, gpu.density)).is_less(CLOSE)
	assert_float(_gap(cpu.u, gpu.u)).is_less(CLOSE)


func test_un_fluide_au_repos_reste_au_repos() -> void:
	var gpu: GpuSolver = GpuSolver.new(_device, _settings(true, 4.0))
	gpu.step(0.1)
	var vitesse: FluidField = GridCheck.read(_device, gpu.u, WIDTH, HEIGHT)
	assert_float(vitesse.peak()).is_equal(0.0)


func test_la_source_nourrit_le_fluide_et_il_monte() -> void:
	var pair: Array[RefCounted] = _both(_settings(true, 0.0), 8)
	var gpu: GpuSolver = pair[1]
	var matiere: FluidField = GridCheck.read(_device, gpu.density, WIDTH, HEIGHT)
	assert_float(matiere.total()).is_greater(1.0)
	assert_float(matiere.at(20, 17)).is_greater(0.0)


func test_rien_n_entre_dans_un_mur() -> void:
	var pair: Array[RefCounted] = _both(_settings(true, 4.0), 8)
	var gpu: GpuSolver = pair[1]
	assert_float(GridCheck.read(_device, gpu.density, WIDTH, HEIGHT).at(21, 13)).is_equal(0.0)
	assert_float(GridCheck.read(_device, gpu.u, WIDTH, HEIGHT).at(21, 13)).is_equal(0.0)
	assert_float(GridCheck.read(_device, gpu.v, WIDTH, HEIGHT).at(21, 13)).is_equal(0.0)


func test_un_fluide_epais_suit_la_meme_equation() -> void:
	var settings: FluidSettings = _settings(false, 0.0)
	settings.viscosity = 0.4
	settings.diffusion = 0.2
	settings.iterations = 60
	var pair: Array[RefCounted] = _both(settings, 3)
	var cpu: FluidSolver = pair[0]
	var gpu: GpuSolver = pair[1]
	assert_float(_gap(cpu.density, gpu.density)).is_less(0.02)
#@ 15+


## Un feu dont le seuil ne tombe pile sur aucune case des disques de `_both_on_fire` : à 0,2, les cases à 4 du centre valent
## 0,1999999881 sur la carte et 0,2 sur le processeur, et brûlent d'un seul côté.
func _fire() -> FireSettings:
	var fire: FireSettings = FireSettings.new()
	fire.ignition = 0.23
	fire.burn_rate = 3.0
	return fire


## Un même feu, nourri pareil, `steps` pas : (solveur du processeur, solveur de la carte).
func _both_on_fire(steps: int) -> Array[RefCounted]:
	var settings: FluidSettings = _settings(false, 0.0)
	var cpu: FluidSolver = FluidSolver.new(settings)
	var gpu: GpuSolver = GpuSolver.new(_device, settings)
	cpu.fire = _fire()
	gpu.fire = cpu.fire
	for _step: int in steps:
		cpu.fuel.add_disc(20.0, 24.0, 5.0, 2.0)
		cpu.temperature.add_disc(20.0, 24.0, 5.0, 1.0)
		gpu.add_matter(gpu.fuel, 20.0, 24.0, 5.0, 2.0)
		gpu.add_matter(gpu.temperature, 20.0, 24.0, 5.0, 1.0)
		cpu.step(0.1)
		gpu.step(0.1)
	return [cpu, gpu]


func test_avec_un_feu_il_suit_le_processeur() -> void:
	var pair: Array[RefCounted] = _both_on_fire(6)
	var cpu: FluidSolver = pair[0]
	var gpu: GpuSolver = pair[1]
	assert_float(_gap(cpu.temperature, gpu.temperature)).is_less(CLOSE)
	assert_float(_gap(cpu.fuel, gpu.fuel)).is_less(CLOSE)
	assert_float(_gap(cpu.soot, gpu.soot)).is_less(CLOSE)
	assert_float(_gap(cpu.v, gpu.v)).is_less(CLOSE)


func test_la_flamme_monte() -> void:
	var gpu: GpuSolver = _both_on_fire(10)[1]
	var chaleur: FluidField = GridCheck.read(_device, gpu.temperature, WIDTH, HEIGHT)
	var vitesse: FluidField = GridCheck.read(_device, gpu.v, WIDTH, HEIGHT)
	assert_float(chaleur.at(20, 14)).is_greater(0.0)
	assert_float(vitesse.at(20, 20)).is_less(0.0)
#@ all
