extends Control
## Une crue vue du ciel. Une source coule sur un relief, l'eau cherche les creux, et un glissé de la souris en verse encore. L'eau tourne sur
## l'appareil du rendu, et sa texture se montre telle quelle. Tout ce qui touche à la carte passe par le fil du rendu.

## Les réglages de l'eau.
@export var settings: FloodSettings
## L'eau versée par seconde, au centre de la source.
@export_range(0.0, 100.0, 0.1) var spring_rate: float = 6.0

var _device: ComputeDevice
var _flood: GpuFlood
var _texture: Texture2DRD
@onready var _view: TextureRect = $View


func _ready() -> void:
	_device = ComputeDevice.shared()
	if _device == null:
		set_physics_process(false)
		return
	var terrain: FluidField = hills(settings.width, settings.height)
	var image: Image = Image.create_from_data(settings.width, settings.height, false, Image.FORMAT_RF, terrain.data.to_byte_array())
	(_view.material as ShaderMaterial).set_shader_parameter("ground_map", ImageTexture.create_from_image(image))
	_texture = Texture2DRD.new()
	_view.texture = _texture
	RenderingServer.call_on_render_thread(_start.bind(terrain))


func _physics_process(delta: float) -> void:
	RenderingServer.call_on_render_thread(_advance.bind(delta))


func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if _flood == null or motion == null or motion.button_mask == 0:
		return
	var x: float = motion.position.x * settings.width / _view.size.x
	var y: float = motion.position.y * settings.height / _view.size.y
	RenderingServer.call_on_render_thread(_flood.add_water.bind(x, y, settings.width * 0.04, 1.0))


func _exit_tree() -> void:
	if _device == null:
		return
	_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_device.release)


## Un relief sans hasard : des vagues de terre, qui descendent vers le bas de l'image.
static func hills(width: int, height: int) -> FluidField:
	var terrain: FluidField = FluidField.new(width, height)
	for y: int in height:
		for x: int in width:
			var across: float = float(x) / width
			var along: float = float(y) / height
			var waves: float = sin(across * TAU * 2.0) * cos(along * TAU * 1.5)
			terrain.put(x, y, 0.8 + 0.25 * waves + 0.9 * (1.0 - along))
	return terrain


## Crée l'eau, sur le fil du rendu.
func _start(terrain: FluidField) -> void:
	_flood = GpuFlood.new(_device, settings, terrain)


## Nourrit la source, avance d'un pas et montre l'eau, sur le fil du rendu. Les textures s'échangent à chaque pas : celle qu'on montre
## change aussi.
func _advance(delta: float) -> void:
	_flood.add_water(settings.width * 0.5, settings.height * 0.1, settings.width * 0.06, spring_rate * delta)
	_flood.step(delta)
	_texture.texture_rd_rid = _flood.depth
