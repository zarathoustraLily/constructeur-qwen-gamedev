extends Control
## Le feu sur la carte, à l'écran. Le solveur tourne sur l'appareil du rendu, et la texture de la température se montre telle
## quelle : aucune case ne repasse par le processeur. Tout ce qui touche à la carte passe par le fil du rendu.

## Les réglages du fluide.
@export var settings: FluidSettings
## Les réglages du feu.
@export var fire: FireSettings
## Le carburant versé par seconde, au centre de la source.
@export_range(0.0, 100.0, 0.1) var fuel_rate: float = 10.0
## La chaleur versée par seconde, au centre de la source : c'est elle qui allume.
@export_range(0.0, 50.0, 0.1) var heat_rate: float = 3.0

var _device: ComputeDevice
var _solver: GpuSolver
var _texture: Texture2DRD
@onready var _view: TextureRect = $View


func _ready() -> void:
	_device = ComputeDevice.shared()
	if _device == null:
		set_physics_process(false)
		return
	_texture = Texture2DRD.new()
	_view.texture = _texture
	RenderingServer.call_on_render_thread(_start)


func _physics_process(delta: float) -> void:
	RenderingServer.call_on_render_thread(_advance.bind(delta))


func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if _solver == null or motion == null or motion.button_mask == 0:
		return
	var scale_x: float = settings.width / _view.size.x
	var scale_y: float = settings.height / _view.size.y
	var push: Callable = _solver.add_force.bind(motion.position.x * scale_x, motion.position.y * scale_y, settings.width * 0.05,
			motion.relative.x * scale_x * 60.0, motion.relative.y * scale_y * 60.0)
	RenderingServer.call_on_render_thread(push)


func _exit_tree() -> void:
	if _device == null:
		return
	_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_device.release)


## Crée le solveur, sur le fil du rendu.
func _start() -> void:
	_solver = GpuSolver.new(_device, settings)
	_solver.fire = fire


## Nourrit le feu, avance d'un pas et montre la température, sur le fil du rendu. Le solveur échange ses textures à chaque pas :
## celle qu'on montre change aussi.
func _advance(delta: float) -> void:
	var middle: float = settings.width * 0.5
	var bottom: float = settings.height * 0.92
	var radius: float = settings.width * 0.12
	_solver.add_matter(_solver.fuel, middle, bottom, radius, fuel_rate * delta)
	_solver.add_matter(_solver.temperature, middle, bottom, radius, heat_rate * delta)
	_solver.step(delta)
	_texture.texture_rd_rid = _solver.temperature
