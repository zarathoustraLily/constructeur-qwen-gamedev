extends Node3D
## Une fumée cuite en six réponses, autour de laquelle tourne une lumière. La fumée ne bouge pas : c'est son relief qui change, alors
## qu'on ne lit que deux textures.

## Les réglages du volume cuit.
@export var volume_settings: VolumeSettings
## Les pas de simulation avant la cuisson.
@export_range(1, 200, 1) var simulation_steps: int = 40
## La lumière retirée par unité de fumée et par longueur de volume.
@export_range(0.0, 50.0, 0.1) var absorption: float = 8.0
## La vitesse de la lumière autour de la fumée, en radians par seconde.
@export_range(0.0, 10.0, 0.01) var turn_speed: float = 0.8

@onready var _quad: MeshInstance3D = $Quad
@onready var _light: DirectionalLight3D = $Light


func _ready() -> void:
	var device: ComputeDevice = ComputeDevice.open()
	if device == null:
		set_process(false)
		return
	var volume: GpuVolume = GpuVolume.new(device, volume_settings)
	var size: Vector3 = Vector3(volume_settings.size)
	for _step: int in simulation_steps:
		volume.add_source(Vector3(size.x * 0.5, size.y * 0.2, size.z * 0.5), size.x * 0.2, 0.6, 0.6)
		volume.step(0.033)
	var lights: Array[Image] = SixWayBaker.new(device).bake(volume.density, absorption)
	device.release()
	var material: ShaderMaterial = _quad.material_override as ShaderMaterial
	material.set_shader_parameter("first_lights", ImageTexture.create_from_image(lights[0]))
	material.set_shader_parameter("second_lights", ImageTexture.create_from_image(lights[1]))


func _process(delta: float) -> void:
	_light.rotate_y(turn_speed * delta)
