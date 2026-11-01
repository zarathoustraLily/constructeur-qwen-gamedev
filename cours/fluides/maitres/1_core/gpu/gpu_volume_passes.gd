class_name GpuVolumePasses extends RefCounted
## Les passes d'un fluide en trois dimensions. Un champ est un volume d'un flottant par case, la vitesse un volume de quatre
## flottants par case : `x`, `y`, `z`, et un quatrième inutilisé, parce que le format à trois canaux n'existe pas en écriture.

const ADVECT := "res://1_core/gpu/shaders/advect_scalar_3d.glsl"
const ADVECT_VELOCITY := "res://1_core/gpu/shaders/advect_velocity_3d.glsl"
const DIVERGENCE := "res://1_core/gpu/shaders/divergence_3d.glsl"
const PRESSURE := "res://1_core/gpu/shaders/pressure_3d.glsl"
const GRADIENT := "res://1_core/gpu/shaders/gradient_3d.glsl"
const STOP := "res://1_core/gpu/shaders/stop_at_box.glsl"
const SPHERE := "res://1_core/gpu/shaders/add_sphere.glsl"
const SCALE := "res://1_core/gpu/shaders/scale_volume.glsl"
const LIFT := "res://1_core/gpu/shaders/lift_3d.glsl"
const CURL := "res://1_core/gpu/shaders/curl_3d.glsl"
const CONFINE := "res://1_core/gpu/shaders/confine_3d.glsl"

var _groups: Vector3i
var _advect: ComputePass
var _advect_velocity: ComputePass
var _divergence: ComputePass
var _pressure: ComputePass
var _gradient: ComputePass
var _stop: ComputePass
var _sphere: ComputePass
var _scale: ComputePass
var _lift: ComputePass
var _curl: ComputePass
var _confine: ComputePass


func _init(device: ComputeDevice, size: Vector3i) -> void:
	_groups = ComputePass.volume_groups(size)
	_advect = ComputePass.new(device, ADVECT, [1, 2])
	_advect_velocity = ComputePass.new(device, ADVECT_VELOCITY, [1])
	_divergence = ComputePass.new(device, DIVERGENCE)
	_pressure = ComputePass.new(device, PRESSURE)
	_gradient = ComputePass.new(device, GRADIENT)
	_stop = ComputePass.new(device, STOP)
	_sphere = ComputePass.new(device, SPHERE)
	_scale = ComputePass.new(device, SCALE)
	_lift = ComputePass.new(device, LIFT)
	_curl = ComputePass.new(device, CURL)
	_confine = ComputePass.new(device, CONFINE)


## Remplit `target` : chaque case reçoit la valeur de `source` d'où vient le courant `velocity`, `delta` secondes plus tôt.
func advect(target: RID, source: RID, velocity: RID, delta: float) -> void:
	_advect.run([target, source, velocity], PackedFloat32Array([delta]), _groups)


## Remplit `target` avec la vitesse `velocity` transportée par elle-même.
func advect_velocity(target: RID, velocity: RID, delta: float) -> void:
	_advect_velocity.run([target, velocity], PackedFloat32Array([delta]), _groups)


## Remplit `target` avec la divergence de `velocity`.
func divergence(target: RID, velocity: RID) -> void:
	_divergence.run([target, velocity], PackedFloat32Array(), _groups)


## Remplit `pressure` : `iterations` passes rouge-noir sur `divergence_volume`, surrelaxées de `relaxation`.
func solve_pressure(pressure: RID, divergence_volume: RID, iterations: int, relaxation: float) -> void:
	for _pass: int in iterations:
		for color: int in 2:
			_pressure.run([pressure, divergence_volume], PackedFloat32Array([relaxation, color]), _groups)


## Retire à `velocity` la pente de `pressure`, puis ce qui sortirait du volume.
func subtract_gradient(velocity: RID, pressure: RID) -> void:
	_gradient.run([velocity, pressure], PackedFloat32Array(), _groups)
	_stop.run([velocity], PackedFloat32Array(), _groups)


## Ajoute `amount` à `field` dans la boule de centre `center` : le plus au centre, rien au bord du rayon `radius`.
func add_sphere(field: RID, center: Vector3, radius: float, amount: float) -> void:
	_sphere.run([field], PackedFloat32Array([center.x, center.y, center.z, radius, amount]), _groups)


## Multiplie toutes les cases de `field` par `factor`.
func scale(field: RID, factor: float) -> void:
	_scale.run([field], PackedFloat32Array([factor]), _groups)


## Pousse `velocity` vers le haut : la chaleur monte, la fumée pèse.
func lift(velocity: RID, temperature: RID, density: RID, buoyancy: float, weight: float, delta: float) -> void:
	_lift.run([velocity, temperature, density], PackedFloat32Array([buoyancy, weight, delta]), _groups)


## Remplit `target` avec la rotation de `velocity`.
func curl(target: RID, velocity: RID) -> void:
	_curl.run([target, velocity], PackedFloat32Array(), _groups)


## Ajoute à `velocity` la force du confinement pendant `delta` secondes, d'après la rotation `spin`.
func confine(velocity: RID, spin: RID, strength: float, delta: float) -> void:
	_confine.run([velocity, spin], PackedFloat32Array([strength, delta]), _groups)
