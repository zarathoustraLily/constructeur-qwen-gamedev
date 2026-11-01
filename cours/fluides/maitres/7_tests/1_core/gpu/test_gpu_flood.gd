extends GdUnitTestSuite
## Règles de l'eau peu profonde sur la carte : elle suit le processeur, pas après pas, sur le plat comme sur un relief, jusqu'au bord ; elle
## ne perd pas d'eau ; un lac au repos le reste.

const SIZE := 32
const TOLERANCE := 0.0005

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	_device.release()


func _settings() -> FloodSettings:
	var settings: FloodSettings = FloodSettings.new()
	settings.width = SIZE
	settings.height = SIZE
	settings.pull = 100.0
	settings.friction = 0.98
	return settings


func _relief() -> FluidField:
	var sol: FluidField = FluidField.new(SIZE, SIZE)
	for y: int in SIZE:
		for x: int in SIZE:
			sol.put(x, y, 0.6 + 0.3 * sin(x * 0.4) * cos(y * 0.3))
	return sol


func _depth_of(flood: GpuFlood) -> FluidField:
	return GridCheck.read(_device, flood.depth, SIZE, SIZE)


func test_sur_le_plat_la_carte_suit_le_processeur() -> void:
	var flood: GpuFlood = GpuFlood.new(_device, _settings(), FluidField.new(SIZE, SIZE))
	var solver: FloodSolver = FloodSolver.new(_settings(), FluidField.new(SIZE, SIZE))
	flood.add_water(12.0, 16.0, 7.0, 2.0)
	solver.add_water(12.0, 16.0, 7.0, 2.0)
	for _pas: int in 10:
		flood.step(1.0 / 30.0)
		solver.step(1.0 / 30.0)
	assert_float(GridCheck.largest_gap(_depth_of(flood), solver.depth)).is_less(TOLERANCE)


func test_sur_un_relief_la_carte_suit_le_processeur() -> void:
	var flood: GpuFlood = GpuFlood.new(_device, _settings(), _relief())
	var solver: FloodSolver = FloodSolver.new(_settings(), _relief())
	flood.add_water(5.0, 5.0, 6.0, 1.0)
	solver.add_water(5.0, 5.0, 6.0, 1.0)
	for _pas: int in 10:
		flood.step(1.0 / 30.0)
		solver.step(1.0 / 30.0)
	assert_float(GridCheck.largest_gap(_depth_of(flood), solver.depth)).is_less(TOLERANCE)


func test_la_carte_ne_perd_pas_d_eau() -> void:
	var flood: GpuFlood = GpuFlood.new(_device, _settings(), FluidField.new(SIZE, SIZE))
	flood.add_water(4.0, 4.0, 6.0, 2.0)
	var depart: float = _depth_of(flood).total()
	for _pas: int in 20:
		flood.step(1.0 / 30.0)
	assert_float(_depth_of(flood).total()).is_equal_approx(depart, 0.01)


func test_un_lac_au_repos_reste_au_repos() -> void:
	var sol: FluidField = _relief()
	var flood: GpuFlood = GpuFlood.new(_device, _settings(), sol)
	var eau: FluidField = FluidField.new(SIZE, SIZE)
	for i: int in eau.data.size():
		eau.data[i] = 1.5 - sol.data[i]
	_device.upload(flood.depth, eau)
	for _pas: int in 10:
		flood.step(1.0 / 30.0)
	assert_float(GridCheck.largest_gap(_depth_of(flood), eau)).is_less(TOLERANCE)
