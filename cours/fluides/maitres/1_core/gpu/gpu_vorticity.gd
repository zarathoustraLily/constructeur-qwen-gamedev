class_name GpuVorticity extends RefCounted
## Les tourbillons sur la carte : les calculs de `Vorticity`.

const CURL := "res://1_core/gpu/shaders/curl.glsl"
const CONFINE := "res://1_core/gpu/shaders/confine.glsl"

var _groups: Vector3i
var _curl: ComputePass
var _confine: ComputePass


func _init(device: ComputeDevice, width: int, height: int) -> void:
	_groups = ComputePass.grid_groups(width, height)
	_curl = ComputePass.new(device, CURL)
	_confine = ComputePass.new(device, CONFINE)


## Remplit `target` avec la rotation de la vitesse (`u`, `v`).
func curl(target: RID, u: RID, v: RID) -> void:
	_curl.run([target, u, v], PackedFloat32Array(), _groups)


## Ajoute à (`u`, `v`) la force du confinement pendant `delta` secondes, d'après la rotation `spin`, à la force `strength`.
func confine(u: RID, v: RID, spin: RID, strength: float, delta: float) -> void:
	_confine.run([u, v, spin], PackedFloat32Array([strength, delta]), _groups)
