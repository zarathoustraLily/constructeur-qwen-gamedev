class_name GpuCombustion extends RefCounted
## Le feu sur la carte : les calculs de `Combustion`. Le refroidissement n'a pas de passe à lui : c'est `GpuFieldOps.scale`.

const BURN := "res://1_core/gpu/shaders/burn.glsl"
const LIFT := "res://1_core/gpu/shaders/lift.glsl"

var _groups: Vector3i
var _burn: ComputePass
var _lift: ComputePass


func _init(device: ComputeDevice, width: int, height: int) -> void:
	_groups = ComputePass.grid_groups(width, height)
	_burn = ComputePass.new(device, BURN)
	_lift = ComputePass.new(device, LIFT)


## Brûle pendant `delta` secondes ; `expansion` reçoit la dilatation de chaque case.
func burn(fuel: RID, temperature: RID, soot: RID, expansion: RID, settings: FireSettings, delta: float) -> void:
	var constants: PackedFloat32Array = PackedFloat32Array([settings.ignition, settings.burn_rate, settings.heat,
			settings.soot_yield, settings.expansion, delta])
	_burn.run([fuel, temperature, soot, expansion], constants, _groups)


## Pousse la vitesse verticale `v` : la chaleur monte, la suie pèse.
func lift(v: RID, temperature: RID, soot: RID, settings: FireSettings, delta: float) -> void:
	var constants: PackedFloat32Array = PackedFloat32Array([settings.soot_weight, settings.buoyancy, delta])
	_lift.run([v, temperature, soot], constants, _groups)
