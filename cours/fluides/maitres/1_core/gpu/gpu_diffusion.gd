class_name GpuDiffusion extends RefCounted
## La diffusion sur la carte. `Diffusion` parcourt les cases dans l'ordre, chacune lisant celles qui viennent d'être calculées :
## une carte ne peut pas faire ça. Le damier rouge-noir cherche la solution de la même équation, par un autre chemin.

const DIFFUSE := "res://1_core/gpu/shaders/diffuse.glsl"

var _device: ComputeDevice
var _groups: Vector3i
var _diffuse: ComputePass


func _init(device: ComputeDevice, width: int, height: int) -> void:
	_device = device
	_groups = ComputePass.grid_groups(width, height)
	_diffuse = ComputePass.new(device, DIFFUSE)


## Remplit `target` avec `source` diffusé `delta` secondes au taux `rate` (en cases² par seconde), en `iterations` passes.
func solve(target: RID, source: RID, rate: float, delta: float, iterations: int) -> void:
	var exchange: float = rate * delta
	_device.copy(target, source)
	for _pass: int in iterations:
		for color: int in 2:
			_diffuse.run([target, source], PackedFloat32Array([exchange, color]), _groups)
