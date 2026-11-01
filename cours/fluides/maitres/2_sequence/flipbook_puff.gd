extends Node3D
## Une bouffée de fumée cuite au démarrage, puis jouée en boucle sur un plan. Après la cuisson, plus aucun calcul : le plan lit une
## planche, et l'appareil de calcul est rendu. Dans un vrai jeu, on enregistre la planche et on ne cuit plus jamais.

## Les réglages du volume cuit.
@export var volume_settings: VolumeSettings
## Les réglages de la planche.
@export var settings: FlipbookSettings
## Les images montrées par seconde.
@export_range(1.0, 120.0, 0.1) var playback_rate: float = 24.0
## Combien de temps on verse de la fumée, en secondes.
@export_range(0.0, 10.0, 0.01) var feed_time: float = 0.4

var _time: float = 0.0
var _fed: float = 0.0
var _material: ShaderMaterial
@onready var _quad: MeshInstance3D = $Quad


func _ready() -> void:
	var device: ComputeDevice = ComputeDevice.open()
	if device == null:
		set_process(false)
		return
	var volume: GpuVolume = GpuVolume.new(device, volume_settings)
	var atlas: Image = FlipbookBaker.new(device).bake(volume, settings, _feed.bind(volume))
	device.release()
	atlas.convert(Image.FORMAT_L8)
	_material = _quad.material_override as ShaderMaterial
	_material.set_shader_parameter("flipbook", ImageTexture.create_from_image(atlas))
	_material.set_shader_parameter("columns", settings.columns)
	_material.set_shader_parameter("rows", settings.rows)


func _process(delta: float) -> void:
	_time += delta
	var frame: float = Flipbook.frame_at(_time, playback_rate, settings.columns * settings.rows, true)
	_material.set_shader_parameter("frame", frame)


## Verse de la fumée et de la chaleur au bas du volume, jusqu'à `feed_time`.
func _feed(delta: float, volume: GpuVolume) -> void:
	if _fed >= feed_time:
		return
	_fed += delta
	var size: Vector3 = Vector3(volume_settings.size)
	volume.add_source(Vector3(size.x * 0.5, size.y * 0.2, size.z * 0.5), size.x * 0.2, 20.0 * delta, 20.0 * delta)
