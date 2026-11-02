class_name GpuFlood extends RefCounted
## L'eau peu profonde sur la carte : le pas de `FloodSolver`. Les quatre débits d'une case tiennent dans une seule image à quatre canaux.

const FLOW := "res://1_core/gpu/shaders/flood_flow.glsl"
const DEPTH := "res://1_core/gpu/shaders/flood_depth.glsl"

## Les réglages de l'eau.
var settings: FloodSettings
## La profondeur de l'eau.
var depth: RID

var _ground: RID
var _next_depth: RID
var _flow: RID
var _next_flow: RID
var _groups: Vector3i
var _flow_pass: ComputePass
var _depth_pass: ComputePass
var _ops: GpuFieldOps


func _init(device: ComputeDevice, flood_settings: FloodSettings, terrain: FluidField) -> void:
	settings = flood_settings
	var width: int = settings.width
	var height: int = settings.height
	depth = device.new_texture(width, height)
	_next_depth = device.new_texture(width, height)
	_ground = device.new_texture(width, height)
	device.upload(_ground, terrain)
	_flow = device.new_color_texture(width, height)
	_next_flow = device.new_color_texture(width, height)
	_groups = ComputePass.grid_groups(width, height)
	_flow_pass = ComputePass.new(device, FLOW)
	_depth_pass = ComputePass.new(device, DEPTH)
	_ops = GpuFieldOps.new(device, width, height)


## Verse `amount` d'eau dans le disque de rayon `radius`.
func add_water(center_x: float, center_y: float, radius: float, amount: float) -> void:
	_ops.add_disc(depth, center_x, center_y, radius, amount)


## Avance de `delta` secondes.
func step(delta: float) -> void:
	var count: int = WaveSolver.substeps(delta, sqrt(2.0 * settings.pull))
	var part: float = delta / count
	var flow_constants: PackedFloat32Array = PackedFloat32Array([part, settings.pull, settings.friction])
	var depth_constants: PackedFloat32Array = PackedFloat32Array([part])
	for _i: int in count:
		_flow_pass.run([_next_flow, _flow, depth, _ground], flow_constants, _groups)
		var kept_flow: RID = _flow
		_flow = _next_flow
		_next_flow = kept_flow
		_depth_pass.run([_next_depth, depth, _flow], depth_constants, _groups)
		var kept_depth: RID = depth
		depth = _next_depth
		_next_depth = kept_depth
