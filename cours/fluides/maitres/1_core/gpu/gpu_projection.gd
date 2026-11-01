class_name GpuProjection extends RefCounted
## La projection sur la carte : les calculs de `FluidProjection`. C'est ici que le GPU change tout : une passe de pression touche
## toutes les cases d'une couleur en même temps. `walls` est l'image de `ComputeDevice.new_mask`.

const DIVERGENCE := "res://1_core/gpu/shaders/divergence.glsl"
const PRESSURE := "res://1_core/gpu/shaders/pressure.glsl"
const GRADIENT := "res://1_core/gpu/shaders/subtract_gradient.glsl"

var _groups: Vector3i
var _divergence: ComputePass
var _pressure: ComputePass
var _gradient: ComputePass


func _init(device: ComputeDevice, width: int, height: int) -> void:
	_groups = ComputePass.grid_groups(width, height)
	_divergence = ComputePass.new(device, DIVERGENCE)
	_pressure = ComputePass.new(device, PRESSURE)
	_gradient = ComputePass.new(device, GRADIENT)


## Remplit `target` avec la divergence de la vitesse (`u`, `v`).
func divergence(target: RID, u: RID, v: RID, walls: RID) -> void:
	_divergence.run([target, u, v, walls], PackedFloat32Array(), _groups)


## Remplit `pressure` : `iterations` passes rouge-noir sur `divergence_texture`, surrelaxées de `relaxation`.
func solve_pressure(pressure: RID, divergence_texture: RID, walls: RID, iterations: int, relaxation: float) -> void:
	for _pass: int in iterations:
		for color: int in 2:
			_pressure.run([pressure, divergence_texture, walls], PackedFloat32Array([relaxation, color]), _groups)


## Retire à la vitesse (`u`, `v`) la pente de `pressure`.
func subtract_gradient(u: RID, v: RID, pressure: RID, walls: RID) -> void:
	_gradient.run([u, v, pressure, walls], PackedFloat32Array(), _groups)
