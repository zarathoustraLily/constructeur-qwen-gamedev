extends GdUnitTestSuite
## Règles des vagues sur la carte : la même goutte donne la même surface que le processeur, pas après pas, y compris au bord ; les trois
## textures tournent ; un grand pas se découpe comme sur le processeur.

const SIZE := 48
const TOLERANCE := 0.0005

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	_device.release()


func _settings(damping: float) -> WaveSettings:
	var settings: WaveSettings = WaveSettings.new()
	settings.width = SIZE
	settings.height = SIZE
	settings.speed = 20.0
	settings.damping = damping
	return settings


func _gap(waves: GpuWaves, solver: WaveSolver) -> float:
	return GridCheck.largest_gap(GridCheck.read(_device, waves.surface, SIZE, SIZE), solver.surface)


func test_la_carte_suit_le_processeur() -> void:
	var waves: GpuWaves = GpuWaves.new(_device, _settings(0.99))
	var solver: WaveSolver = WaveSolver.new(_settings(0.99))
	waves.drop(20.0, 24.0, 6.0, 1.0)
	solver.drop(20.0, 24.0, 6.0, 1.0)
	for _pas: int in 12:
		waves.step(1.0 / 60.0)
		solver.step(1.0 / 60.0)
	assert_float(_gap(waves, solver)).is_less(TOLERANCE)


func test_au_bord_la_carte_suit_le_processeur() -> void:
	var waves: GpuWaves = GpuWaves.new(_device, _settings(1.0))
	var solver: WaveSolver = WaveSolver.new(_settings(1.0))
	waves.drop(4.0, 4.0, 4.0, 1.0)
	solver.drop(4.0, 4.0, 4.0, 1.0)
	for _pas: int in 16:
		waves.step(1.0 / 60.0)
		solver.step(1.0 / 60.0)
	assert_float(_gap(waves, solver)).is_less(TOLERANCE)


func test_un_grand_pas_se_decoupe_comme_sur_le_processeur() -> void:
	var waves: GpuWaves = GpuWaves.new(_device, _settings(1.0))
	var solver: WaveSolver = WaveSolver.new(_settings(1.0))
	waves.drop(24.0, 24.0, 5.0, 1.0)
	solver.drop(24.0, 24.0, 5.0, 1.0)
	waves.step(0.25)
	solver.step(0.25)
	assert_float(_gap(waves, solver)).is_less(TOLERANCE)


func test_une_goutte_pose_de_l_eau_sur_les_deux_surfaces() -> void:
	var waves: GpuWaves = GpuWaves.new(_device, _settings(1.0))
	waves.drop(24.0, 24.0, 6.0, 1.0)
	var avant: FluidField = GridCheck.read(_device, waves.surface, SIZE, SIZE)
	waves.step(0.0001)
	var apres: FluidField = GridCheck.read(_device, waves.surface, SIZE, SIZE)
	assert_float(GridCheck.largest_gap(avant, apres)).is_less(0.01)


func test_les_textures_tournent_a_chaque_pas() -> void:
	var waves: GpuWaves = GpuWaves.new(_device, _settings(1.0))
	var depart: RID = waves.surface
	waves.step(0.001)
	assert_bool(waves.surface == depart).is_false()
