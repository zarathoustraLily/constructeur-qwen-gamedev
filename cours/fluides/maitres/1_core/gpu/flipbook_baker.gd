class_name FlipbookBaker extends RefCounted
## Cuit une fumée en flipbook : on simule une fois, on photographie le volume à intervalles réguliers, et on range les images sur une
## planche. En jeu, il ne reste qu'une texture à lire : c'est ainsi qu'un effet tient sur une petite carte.

const PROJECT := "res://1_core/gpu/shaders/project_volume.glsl"

var _device: ComputeDevice
var _project: ComputePass


func _init(device: ComputeDevice) -> void:
	_device = device
	_project = ComputePass.new(device, PROJECT)


## L'image de `volume`, vue de face, écrite dans `target`, qui a la largeur et la hauteur du volume. Une image vaut une opacité par case.
func frame_of(target: RID, volume: RID, absorption: float) -> Image:
	var format: RDTextureFormat = _device.rd.texture_get_format(volume)
	var constants: PackedFloat32Array = PackedFloat32Array([absorption, 1.0 / format.depth])
	_project.run([target, volume], constants, ComputePass.grid_groups(format.width, format.height))
	_device.finish()
	return Image.create_from_data(format.width, format.height, false, Image.FORMAT_RF, _device.rd.texture_get_data(target, 0))


## La planche de `volume`. `feed` reçoit la durée d'un pas : elle nourrit la fumée avant chaque pas.
func bake(volume: GpuVolume, settings: FlipbookSettings, feed: Callable) -> Image:
	var size: Vector2i = Vector2i(volume.settings.size.x, volume.settings.size.y)
	var atlas: Image = Image.create_empty(size.x * settings.columns, size.y * settings.rows, false, Image.FORMAT_RF)
	var target: RID = _device.new_texture(size.x, size.y)
	for index: int in settings.columns * settings.rows:
		for _step: int in settings.steps_per_frame:
			feed.call(settings.delta)
			volume.step(settings.delta)
		var frame: Image = frame_of(target, volume.density, settings.absorption)
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, size), Flipbook.cell(index, settings.columns) * size)
	return atlas
