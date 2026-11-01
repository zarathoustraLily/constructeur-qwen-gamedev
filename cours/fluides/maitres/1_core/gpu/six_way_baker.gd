class_name SixWayBaker extends RefCounted
## Cuit ce qu'un volume renvoie de six lumières. Une image cuite ne connaît pas la lumière du jeu : en gardant les six réponses, on peut
## éclairer la fumée après coup, d'où que vienne la lumière, pour le prix de deux textures.

const SIX_WAY := "res://1_core/gpu/shaders/six_way.glsl"

var _device: ComputeDevice
var _pass: ComputePass


func _init(device: ComputeDevice) -> void:
	_device = device
	_pass = ComputePass.new(device, SIX_WAY)


## Les deux images de `volume`, en flottants : droite, haut, arrière, puis gauche, bas, avant ; l'alpha des deux est l'opacité.
func bake(volume: RID, absorption: float) -> Array[Image]:
	var format: RDTextureFormat = _device.rd.texture_get_format(volume)
	var first: RID = _device.new_color_texture(format.width, format.height)
	var second: RID = _device.new_color_texture(format.width, format.height)
	var constants: PackedFloat32Array = PackedFloat32Array([absorption, 1.0 / format.depth])
	_pass.run([first, second, volume], constants, ComputePass.grid_groups(format.width, format.height))
	_device.finish()
	return [_image_of(first, format), _image_of(second, format)]


func _image_of(texture: RID, format: RDTextureFormat) -> Image:
	var bytes: PackedByteArray = _device.rd.texture_get_data(texture, 0)
	return Image.create_from_data(format.width, format.height, false, Image.FORMAT_RGBAF, bytes)
