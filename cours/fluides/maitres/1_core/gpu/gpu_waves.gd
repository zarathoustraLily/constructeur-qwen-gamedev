class_name GpuWaves extends RefCounted
## La surface de l'eau sur la carte : le pas de `WaveSolver`. Il faut trois textures : on écrit la nouvelle à partir des deux dernières,
## et elles tournent à chaque pas.

const WAVE := "res://1_core/gpu/shaders/wave.glsl"

## Les réglages de la surface.
var settings: WaveSettings
## La hauteur de l'eau.
var surface: RID

var _previous: RID
var _next: RID
var _groups: Vector3i
var _wave: ComputePass
var _ops: GpuFieldOps


func _init(device: ComputeDevice, wave_settings: WaveSettings) -> void:
	settings = wave_settings
	surface = device.new_texture(settings.width, settings.height)
	_previous = device.new_texture(settings.width, settings.height)
	_next = device.new_texture(settings.width, settings.height)
	_groups = ComputePass.grid_groups(settings.width, settings.height)
	_wave = ComputePass.new(device, WAVE)
	_ops = GpuFieldOps.new(device, settings.width, settings.height)


## Pose une bosse d'eau immobile.
func drop(center_x: float, center_y: float, radius: float, amount: float) -> void:
	_ops.add_disc(surface, center_x, center_y, radius, amount)
	_ops.add_disc(_previous, center_x, center_y, radius, amount)


## Avance de `delta` secondes.
func step(delta: float) -> void:
	var count: int = WaveSolver.substeps(delta, settings.speed)
	var courant: float = delta / count * settings.speed
	var constants: PackedFloat32Array = PackedFloat32Array([courant * courant, settings.damping])
	for _i: int in count:
		_wave.run([_next, surface, _previous], constants, _groups)
		var oldest: RID = _previous
		_previous = surface
		surface = _next
		_next = oldest
