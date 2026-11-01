class_name GpuFieldOps extends RefCounted
## Les petites passes sur un champ de la carte : ce qui tient en une boucle sur le processeur. `walls` est l'image des murs.

const SCALE := "res://1_core/gpu/shaders/scale_image.glsl"
const DISC := "res://1_core/gpu/shaders/add_disc.glsl"
const CLEAR := "res://1_core/gpu/shaders/clear_walls.glsl"
const STOP := "res://1_core/gpu/shaders/stop_at_walls.glsl"
#@ 15+
const ADD_SCALED := "res://1_core/gpu/shaders/add_scaled.glsl"
#@ all

var _groups: Vector3i
var _scale: ComputePass
var _disc: ComputePass
var _clear: ComputePass
var _stop: ComputePass
#@ 15+
var _add_scaled: ComputePass
#@ all


func _init(device: ComputeDevice, width: int, height: int) -> void:
	_groups = ComputePass.grid_groups(width, height)
	_scale = ComputePass.new(device, SCALE)
	_disc = ComputePass.new(device, DISC)
	_clear = ComputePass.new(device, CLEAR)
	_stop = ComputePass.new(device, STOP)
#@ 15+
	_add_scaled = ComputePass.new(device, ADD_SCALED)
#@ all


## Multiplie toutes les cases de `field` par `factor`.
func scale(field: RID, factor: float) -> void:
	_scale.run([field], PackedFloat32Array([factor]), _groups)


## Ajoute `amount` dans le disque de centre (`center_x`, `center_y`) : le plus au centre, rien au bord du rayon `radius`.
func add_disc(field: RID, center_x: float, center_y: float, radius: float, amount: float) -> void:
	_disc.run([field], PackedFloat32Array([center_x, center_y, radius, amount]), _groups)


## Met à zéro `field` dans les murs.
func clear_walls(field: RID, walls: RID) -> void:
	_clear.run([field, walls], PackedFloat32Array(), _groups)


## Retire à la vitesse (`u`, `v`) ce qui la ferait entrer dans un mur voisin.
func stop_at_walls(u: RID, v: RID, walls: RID) -> void:
	_stop.run([u, v, walls], PackedFloat32Array(), _groups)
#@ 15+


## Ajoute à `target` l'image `source` multipliée par `factor`.
func add_scaled(target: RID, source: RID, factor: float) -> void:
	_add_scaled.run([target, source], PackedFloat32Array([factor]), _groups)
#@ all
