class_name GpuTracers extends RefCounted
## Des particules sur la carte, portées par la vitesse d'un solveur. Leurs positions ne repassent jamais par le processeur : un second shader
## les écrit directement dans le tampon d'une `MultiMesh`.

const MOVE := "res://1_core/gpu/shaders/tracers.glsl"
const INSTANCES := "res://1_core/gpu/shaders/tracer_instances.glsl"
## Le nombre de particules d'un groupe : `layout(local_size_x = 64)`.
const GROUP := 64

## Le nombre de particules.
var count: int = 0
## Les positions, deux flottants par particule.
var positions: RID

var _origins: RID
var _width: int = 0
var _height: int = 0
var _lifetime: int = 0
var _turn: int = 0
var _groups: Vector3i
var _move: ComputePass
var _instances: ComputePass


## `lifetime` : le nombre de pas qu'une particule vit avant de revenir à son départ (0 : elle ne revient qu'en sortant de la grille).
func _init(device: ComputeDevice, starts: PackedVector2Array, width: int, height: int, lifetime: int = 0) -> void:
	count = starts.size()
	_width = width
	_height = height
	_lifetime = lifetime
	var values: PackedFloat32Array = PackedFloat32Array()
	for start: Vector2 in starts:
		values.append(start.x)
		values.append(start.y)
	positions = device.new_buffer(values)
	_origins = device.new_buffer(values)
	_groups = Vector3i(ComputePass.groups_for(count, GROUP), 1, 1)
	_move = ComputePass.new(device, MOVE, [2, 3])
	_instances = ComputePass.new(device, INSTANCES)


## Avance de `delta` secondes dans le courant (`u`, `v`).
func step(u: RID, v: RID, delta: float) -> void:
	var constants: PackedFloat32Array = PackedFloat32Array([delta, _width, _height, _lifetime, _turn])
	_move.run([positions, _origins, u, v], constants, _groups)
	if _lifetime > 0:
		_turn = (_turn + 1) % _lifetime


## Écrit les positions dans le tampon d'instances `target`.
func write_instances(target: RID) -> void:
	_instances.run([positions, target], PackedFloat32Array(), _groups)
