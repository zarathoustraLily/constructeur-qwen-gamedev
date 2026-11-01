class_name GpuAdvection extends RefCounted
## Le transport sur la carte : les calculs de `Advection`, une image par champ. Tout se lance sans attendre : `ComputeDevice.finish`
## dit quand la carte doit avoir fini.

const SIMPLE := "res://1_core/gpu/shaders/advect.glsl"
const SHARP := "res://1_core/gpu/shaders/mac_cormack.glsl"

var _groups: Vector3i
var _simple: ComputePass
var _sharp: ComputePass


func _init(device: ComputeDevice, width: int, height: int) -> void:
	_groups = ComputePass.grid_groups(width, height)
	_simple = ComputePass.new(device, SIMPLE)
	_sharp = ComputePass.new(device, SHARP)


## Remplit `target` : chaque case reçoit la valeur de `source` à l'endroit d'où vient le courant (`u`, `v`) `delta` secondes plus tôt.
func semi_lagrangian(target: RID, source: RID, u: RID, v: RID, delta: float) -> void:
	_simple.run([target, source, u, v], PackedFloat32Array([delta]), _groups)


## Le transport de MacCormack : en avant dans `forward`, retour dans `backward`, puis la correction bornée dans `target`.
func mac_cormack(target: RID, source: RID, u: RID, v: RID, delta: float, forward: RID, backward: RID) -> void:
	semi_lagrangian(forward, source, u, v, delta)
	semi_lagrangian(backward, forward, u, v, -delta)
	_sharp.run([target, source, forward, backward, u, v], PackedFloat32Array([delta]), _groups)
