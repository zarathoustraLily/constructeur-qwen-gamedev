class_name GpuVolume extends RefCounted
## Une fumée chaude en trois dimensions, sur la carte. Le pas est celui de `GpuSolver`, avec un axe de plus ; le processeur ne pourrait
## pas suivre : une grille de 64 × 96 × 64 compte près de 300 000 cases.

## Les réglages du volume.
var settings: VolumeSettings
## La fumée.
var density: RID
## La température.
var temperature: RID
## La vitesse, en cases par seconde.
var velocity: RID

var _next: RID
var _next_velocity: RID
var _pressure: RID
var _divergence: RID
var _spin: RID
var _passes: GpuVolumePasses


func _init(device: ComputeDevice, volume_settings: VolumeSettings) -> void:
	settings = volume_settings
	var size: Vector3i = settings.size
	density = device.new_volume(size, false)
	temperature = device.new_volume(size, false)
	velocity = device.new_volume(size, true)
	_next = device.new_volume(size, false)
	_next_velocity = device.new_volume(size, true)
	_pressure = device.new_volume(size, false)
	_divergence = device.new_volume(size, false)
	_spin = device.new_volume(size, true)
	_passes = GpuVolumePasses.new(device, size)


## Verse de la fumée et de la chaleur dans la boule de centre `center`.
func add_source(center: Vector3, radius: float, smoke: float, heat: float) -> void:
	_passes.add_sphere(density, center, radius, smoke)
	_passes.add_sphere(temperature, center, radius, heat)


## Avance de `delta` secondes.
func step(delta: float) -> void:
	_passes.lift(velocity, temperature, density, settings.buoyancy, settings.weight, delta)
	if settings.vortex_strength > 0.0:
		_passes.curl(_spin, velocity)
		_passes.confine(velocity, _spin, settings.vortex_strength, delta)
	_project()
	_passes.advect_velocity(_next_velocity, velocity, delta)
	var kept_velocity: RID = velocity
	velocity = _next_velocity
	_next_velocity = kept_velocity
	_project()
	density = _carried(density, delta)
	temperature = _carried(temperature, delta)
	_passes.scale(density, exp(-settings.dissipation * delta))
	_passes.scale(temperature, exp(-settings.cooling * delta))


## Rend la vitesse sans divergence.
func _project() -> void:
	_passes.divergence(_divergence, velocity)
	_passes.solve_pressure(_pressure, _divergence, settings.iterations, settings.relaxation)
	_passes.subtract_gradient(velocity, _pressure)


## `field` transporté, dans le double de travail ; `field` devient le nouveau double.
func _carried(field: RID, delta: float) -> RID:
	_passes.advect(_next, field, velocity, delta)
	var moved: RID = _next
	_next = field
	return moved
