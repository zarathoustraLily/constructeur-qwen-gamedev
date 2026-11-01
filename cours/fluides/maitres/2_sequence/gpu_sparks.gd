extends Control
## Des étincelles dans le feu. Le feu et ses étincelles tournent sur l'appareil du rendu : le courant du solveur déplace les particules, et
## leurs positions vont droit au tampon de la `MultiMesh`. Le moteur ne les connaît pas : on lui donne donc la boîte où elles restent.

## Les réglages du fluide.
@export var settings: FluidSettings
## Les réglages du feu.
@export var fire: FireSettings
## Le nombre d'étincelles.
@export_range(1, 200000, 1) var spark_count: int = 3000
## Le nombre de pas qu'une étincelle vit.
@export_range(1, 1000, 1) var spark_life: int = 90
## Le carburant versé par seconde, au centre de la source.
@export_range(0.0, 100.0, 0.1) var fuel_rate: float = 10.0
## La chaleur versée par seconde, au centre de la source : c'est elle qui allume.
@export_range(0.0, 50.0, 0.1) var heat_rate: float = 3.0

var _device: ComputeDevice
var _solver: GpuSolver
var _tracers: GpuTracers
var _instances: RID
var _texture: Texture2DRD
var _multimesh: MultiMesh
@onready var _view: TextureRect = $View
@onready var _sparks: MultiMeshInstance2D = $Sparks


func _ready() -> void:
	_device = ComputeDevice.shared()
	if _device == null:
		set_physics_process(false)
		return
	_texture = Texture2DRD.new()
	_view.texture = _texture
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.mesh = _spark_mesh()
	_multimesh.custom_aabb = AABB(Vector3.ZERO, Vector3(settings.width, settings.height, 1.0))
	_multimesh.instance_count = spark_count
	_sparks.multimesh = _multimesh
	RenderingServer.call_on_render_thread(_start)


func _physics_process(delta: float) -> void:
	_sparks.scale = _view.size / Vector2(settings.width, settings.height)
	RenderingServer.call_on_render_thread(_advance.bind(delta))


func _exit_tree() -> void:
	if _device == null:
		return
	_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_device.release)


## Le départ de chaque étincelle : au hasard dans la source, mais toujours le même hasard.
func _spark_starts() -> PackedVector2Array:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 7
	var starts: PackedVector2Array = PackedVector2Array()
	for _i: int in spark_count:
		var x: float = random.randf_range(settings.width * 0.38, settings.width * 0.62)
		starts.append(Vector2(x, random.randf_range(settings.height * 0.8, settings.height * 0.95)))
	return starts


func _spark_mesh() -> QuadMesh:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.8, 0.8)
	return mesh


## Crée le solveur et les étincelles, sur le fil du rendu.
func _start() -> void:
	_solver = GpuSolver.new(_device, settings)
	_solver.fire = fire
	_tracers = GpuTracers.new(_device, _spark_starts(), settings.width, settings.height, spark_life)
	_instances = RenderingServer.multimesh_get_buffer_rd_rid(_multimesh.get_rid())


## Nourrit le feu, avance d'un pas, déplace les étincelles et montre le tout, sur le fil du rendu.
func _advance(delta: float) -> void:
	var middle: float = settings.width * 0.5
	var bottom: float = settings.height * 0.92
	var radius: float = settings.width * 0.12
	_solver.add_matter(_solver.fuel, middle, bottom, radius, fuel_rate * delta)
	_solver.add_matter(_solver.temperature, middle, bottom, radius, heat_rate * delta)
	_solver.step(delta)
	_tracers.step(_solver.u, _solver.v, delta)
	_tracers.write_instances(_instances)
	_texture.texture_rd_rid = _solver.temperature
