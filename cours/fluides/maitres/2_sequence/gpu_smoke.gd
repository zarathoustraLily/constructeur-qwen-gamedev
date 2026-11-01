extends Node3D
## Une fumée en trois dimensions, à l'écran. Le volume tourne sur l'appareil du rendu ; sa texture va droit au shader de la boîte, par
## `Texture3DRD`, sans repasser par le processeur. Tout ce qui touche à la carte passe par le fil du rendu.

## Les réglages du volume.
@export var settings: VolumeSettings
## La fumée versée par seconde, au centre de la source.
@export_range(0.0, 100.0, 0.1) var smoke_rate: float = 12.0
## La chaleur versée par seconde, au centre de la source : c'est elle qui fait monter la fumée.
@export_range(0.0, 100.0, 0.1) var heat_rate: float = 16.0

var _device: ComputeDevice
var _volume: GpuVolume
var _texture: Texture3DRD
@onready var _box: MeshInstance3D = $Box


func _ready() -> void:
	_device = ComputeDevice.shared()
	if _device == null:
		set_physics_process(false)
		return
	_texture = Texture3DRD.new()
	(_box.material_override as ShaderMaterial).set_shader_parameter("volume", _texture)
	RenderingServer.call_on_render_thread(_start)


func _physics_process(delta: float) -> void:
	RenderingServer.call_on_render_thread(_advance.bind(delta))


func _exit_tree() -> void:
	if _device == null:
		return
	_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_device.release)


## Crée le volume, sur le fil du rendu.
func _start() -> void:
	_volume = GpuVolume.new(_device, settings)


## Nourrit la source, avance d'un pas et montre la fumée, sur le fil du rendu. Le volume échange ses textures à chaque pas : celle
## qu'on montre change aussi.
func _advance(delta: float) -> void:
	var size: Vector3 = Vector3(settings.size)
	var source: Vector3 = Vector3(size.x * 0.5, size.y * 0.12, size.z * 0.5)
	_volume.add_source(source, size.x * 0.14, smoke_rate * delta, heat_rate * delta)
	_volume.step(delta)
	_texture.texture_rd_rid = _volume.density
