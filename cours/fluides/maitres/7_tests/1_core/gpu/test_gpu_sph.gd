extends GdUnitTestSuite
## Règles de SPH sur la carte. Chaque particule se range dans la liste de sa case, sans qu'aucune se perde, même rangées en même temps.
## Les densités, les pressions et les forces rendent ce que rend le processeur, et plusieurs pas le suivent. Personne ne sort de la cuve.

const DELTA := 1.0 / 60.0
const CLOSE := 0.002

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	_device.release()


func _settings() -> SphSettings:
	var settings: SphSettings = SphSettings.new()
	settings.width = 16.0
	settings.height = 12.0
	settings.radius = 1.0
	settings.spacing = 0.5
	settings.stiffness = 60.0
	settings.viscosity = 0.2
	settings.gravity = 20.0
	settings.substeps = 2
	return settings


func _cpu() -> SphSolver:
	var solver: SphSolver = SphSolver.new(_settings())
	solver.add_block(Vector2(1.0, 4.0), Vector2(7.0, 11.5))
	solver.rebuild_neighbours()
	return solver


func _ints(buffer: RID) -> PackedInt32Array:
	return _device.rd.buffer_get_data(buffer).to_int32_array()


func _largest_gap(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	var gap: float = 0.0
	for i: int in a.size():
		gap = maxf(gap, absf(a[i] - b[i]))
	return gap


func _largest_vector_gap(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var gap: float = 0.0
	for i: int in a.size():
		gap = maxf(gap, a[i].distance_to(b[i]))
	return gap


func test_chaque_particule_se_range_dans_la_liste_de_sa_case() -> void:
	var cpu: SphSolver = _cpu()
	var gpu: GpuSph = GpuSph.new(_device, cpu.settings, cpu.positions)
	gpu.rebuild_neighbours()
	_device.finish()
	var tetes: PackedInt32Array = _ints(gpu.heads)
	var suites: PackedInt32Array = _ints(gpu.links)
	var vues: int = 0
	for slot: int in tetes.size():
		var i: int = tetes[slot]
		while i != -1:
			var case_attendue: Vector2i = cpu.cell_of(cpu.positions[i])
			assert_int(case_attendue.y * 16 + case_attendue.x).is_equal(slot)
			vues += 1
			i = suites[i]
	assert_int(vues).is_equal(cpu.positions.size())


func test_les_densites_rendent_ce_que_rend_le_processeur() -> void:
	var cpu: SphSolver = _cpu()
	cpu.update_densities()
	var gpu: GpuSph = GpuSph.new(_device, cpu.settings, cpu.positions)
	gpu.rebuild_neighbours()
	gpu.update_densities()
	_device.finish()
	assert_float(_largest_gap(_device.read_buffer(gpu.densities), cpu.densities)).is_less(CLOSE)
	assert_float(_largest_gap(_device.read_buffer(gpu.pressures), cpu.pressures)).is_less(CLOSE * 60.0)


func test_les_forces_rendent_ce_que_rend_le_processeur() -> void:
	var cpu: SphSolver = _cpu()
	cpu.update_densities()
	cpu.update_forces()
	var gpu: GpuSph = GpuSph.new(_device, cpu.settings, cpu.positions)
	gpu.rebuild_neighbours()
	gpu.update_densities()
	gpu.update_forces()
	_device.finish()
	var attendues: PackedVector2Array = cpu.get("_forces")
	assert_float(_largest_vector_gap(_device.read_vectors(gpu.forces), attendues)).is_less(CLOSE)


func test_plusieurs_pas_suivent_le_processeur() -> void:
	var cpu: SphSolver = _cpu()
	var gpu: GpuSph = GpuSph.new(_device, cpu.settings, cpu.positions)
	for _pas: int in 6:
		cpu.step(DELTA)
		gpu.step(DELTA)
	_device.finish()
	assert_float(_largest_vector_gap(_device.read_vectors(gpu.positions), cpu.positions)).is_less(0.02)


func test_personne_ne_sort_de_la_cuve() -> void:
	var cpu: SphSolver = _cpu()
	var gpu: GpuSph = GpuSph.new(_device, cpu.settings, cpu.positions)
	for _pas: int in 20:
		gpu.step(DELTA)
	_device.finish()
	for place: Vector2 in _device.read_vectors(gpu.positions):
		assert_bool(place.x >= 0.0 and place.y >= 0.0 and place.x <= 16.0 and place.y <= 12.0).is_true()


func test_les_tampons_de_vecteurs_rendent_ce_qu_on_y_a_mis() -> void:
	var valeurs: PackedVector2Array = PackedVector2Array([Vector2(1.5, -2.0), Vector2(0.25, 8.0)])
	var tampon: RID = _device.new_vector_buffer(valeurs)
	assert_bool(_device.read_vectors(tampon)[1].is_equal_approx(Vector2(0.25, 8.0))).is_true()


func test_un_tampon_d_entiers_part_de_zero() -> void:
	var tampon: RID = _device.new_int_buffer(5)
	assert_array(Array(_ints(tampon))).is_equal([0, 0, 0, 0, 0])
