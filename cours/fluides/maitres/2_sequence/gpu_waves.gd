extends Node3D
## De l'eau à l'écran. La surface tourne sur l'appareil du rendu, et sa texture soulève le plan sans repasser par le processeur. Il
## pleut de temps en temps, et un clic pose une goutte. Tout ce qui touche à la carte passe par le fil du rendu.

## Les réglages de la surface.
@export var settings: WaveSettings
## Le temps entre deux gouttes, en secondes (0 : aucune).
@export_range(0.0, 10.0, 0.01) var drop_every: float = 0.8
## Le rayon d'une goutte, en cases.
@export_range(1.0, 50.0, 0.1) var drop_radius: float = 6.0
## La hauteur d'une goutte : négative, elle creuse l'eau.
@export_range(-10.0, 10.0, 0.01) var drop_height: float = -1.5

var _device: ComputeDevice
var _waves: GpuWaves
var _texture: Texture2DRD
var _until_drop: float = 0.0
@onready var _water: MeshInstance3D = $Water
@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_device = ComputeDevice.shared()
	if _device == null:
		set_physics_process(false)
		return
	_texture = Texture2DRD.new()
	var material: ShaderMaterial = _water.material_override as ShaderMaterial
	material.set_shader_parameter("surface", _texture)
	material.set_shader_parameter("cells", Vector2(settings.width, settings.height))
	material.set_shader_parameter("cell_size", _plane_size().x / settings.width)
	RenderingServer.call_on_render_thread(_start)


func _physics_process(delta: float) -> void:
	_until_drop -= delta
	if drop_every > 0.0 and _until_drop <= 0.0:
		_until_drop = drop_every
		_drop_at(randf() * settings.width, randf() * settings.height)
	RenderingServer.call_on_render_thread(_advance.bind(delta))


func _unhandled_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	var origin: Vector3 = _camera.project_ray_origin(click.position)
	var hit: Variant = Plane.PLANE_XZ.intersects_ray(origin, _camera.project_ray_normal(click.position))
	if hit != null:
		var cell: Vector2 = cell_of(hit)
		_drop_at(cell.x, cell.y)


func _exit_tree() -> void:
	if _device == null:
		return
	_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_device.release)


## La case de la grille sous le point `point` du plan.
func cell_of(point: Vector3) -> Vector2:
	var across: Vector2 = Vector2(point.x, point.z) / _plane_size() + Vector2(0.5, 0.5)
	return across * Vector2(settings.width, settings.height)


func _plane_size() -> Vector2:
	return (_water.mesh as PlaneMesh).size


func _drop_at(x: float, y: float) -> void:
	RenderingServer.call_on_render_thread(_waves.drop.bind(x, y, drop_radius, drop_height))


## Crée la surface, sur le fil du rendu.
func _start() -> void:
	_waves = GpuWaves.new(_device, settings)


## Avance d'un pas et montre la surface, sur le fil du rendu. Les textures tournent à chaque pas : celle qu'on montre change aussi.
func _advance(delta: float) -> void:
	_waves.step(delta)
	_texture.texture_rd_rid = _waves.surface
