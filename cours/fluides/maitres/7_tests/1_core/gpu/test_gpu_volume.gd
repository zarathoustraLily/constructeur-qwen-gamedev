extends GdUnitTestSuite
## Règles du volume : un fluide au repos reste au repos ; une fumée chaude monte, droit, sans quitter son axe ; la fumée reste
## dans le volume et se perd à son rythme ; un pas ne casse pas la symétrie autour de la source.

const SIZE := Vector3i(24, 36, 24)

var _device: ComputeDevice


func before_test() -> void:
	_device = ComputeDevice.open()


func after_test() -> void:
	_device.release()


func _settings(vortex: float) -> VolumeSettings:
	var settings: VolumeSettings = VolumeSettings.new()
	settings.size = SIZE
	settings.iterations = 16
	settings.dissipation = 0.0
	settings.cooling = 0.5
	settings.vortex_strength = vortex
	return settings


func test_un_fluide_au_repos_reste_au_repos() -> void:
	var volume: GpuVolume = GpuVolume.new(_device, _settings(4.0))
	volume.step(0.1)
	for valeur: float in VolumeCheck.cells_of(_device, volume.velocity):
		assert_float(valeur).is_equal(0.0)


func test_une_fumee_chaude_monte_droit() -> void:
	var volume: GpuVolume = GpuVolume.new(_device, _settings(0.0))
	volume.add_source(Vector3(11.5, 6.0, 11.5), 5.0, 1.0, 2.0)
	var depart: Vector3 = VolumeCheck.center_of(VolumeCheck.cells_of(_device, volume.density), SIZE)
	for _pas: int in 10:
		volume.step(1.0 / 30.0)
	var arrivee: Vector3 = VolumeCheck.center_of(VolumeCheck.cells_of(_device, volume.density), SIZE)
	assert_float(arrivee.y).is_greater(depart.y + 1.0)
	assert_float(arrivee.x).is_equal_approx(depart.x, 0.2)
	assert_float(arrivee.z).is_equal_approx(depart.z, 0.2)


func test_la_chaleur_se_perd_a_son_rythme() -> void:
	var settings: VolumeSettings = _settings(0.0)
	settings.buoyancy = 0.0
	settings.weight = 0.0
	settings.dissipation = 0.5
	settings.cooling = 2.0
	var volume: GpuVolume = GpuVolume.new(_device, settings)
	volume.add_source(Vector3(12.0, 18.0, 12.0), 6.0, 1.0, 1.0)
	var fumee_avant: float = _total(volume.density)
	var chaleur_avant: float = _total(volume.temperature)
	volume.step(0.1)
	assert_float(_total(volume.density)).is_equal_approx(fumee_avant * exp(-0.05), 0.5)
	assert_float(_total(volume.temperature)).is_equal_approx(chaleur_avant * exp(-0.2), 0.5)


func test_un_tourbillon_ne_casse_pas_la_symetrie() -> void:
	var volume: GpuVolume = GpuVolume.new(_device, _settings(6.0))
	volume.add_source(Vector3(11.5, 6.0, 11.5), 5.0, 1.0, 2.0)
	for _pas: int in 6:
		volume.step(1.0 / 30.0)
	var centre: Vector3 = VolumeCheck.center_of(VolumeCheck.cells_of(_device, volume.density), SIZE)
	assert_float(centre.x).is_equal_approx(11.5, 0.3)
	assert_float(centre.z).is_equal_approx(11.5, 0.3)


func _total(volume: RID) -> float:
	var sum_of_cells: float = 0.0
	for value: float in VolumeCheck.cells_of(_device, volume):
		sum_of_cells += value
	return sum_of_cells
