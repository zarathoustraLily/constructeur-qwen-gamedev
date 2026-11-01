class_name ComputeDevice extends RefCounted
## La carte graphique du simulateur : un appareil de calcul à soi, ses tampons, ses textures. La carte ne connaît pas la mémoire
## de Godot : ce qu'on y crée y reste jusqu'à ce qu'on le rende. Tout est donc noté ici, et `release` rend tout.

## L'appareil : il vit à part du rendu de l'écran, et ne travaille que quand on le lui dit (`finish`).
var rd: RenderingDevice

var _owned: Array[RID] = []


## Un appareil de calcul, ou null s'il n'y a pas de carte : sans fenêtre, Godot n'en ouvre aucune.
static func open() -> ComputeDevice:
	var device: RenderingDevice = RenderingServer.create_local_rendering_device()
	if device == null:
		return null
	var compute: ComputeDevice = ComputeDevice.new()
	compute.rd = device
	return compute


## Note `resource` pour la rendre à la fin, et la rend telle quelle à l'appelant.
func keep(resource: RID) -> RID:
	_owned.append(resource)
	return resource


## Un tampon sur la carte, rempli avec `values`.
func new_buffer(values: PackedFloat32Array) -> RID:
	var bytes: PackedByteArray = values.to_byte_array()
	return keep(rd.storage_buffer_create(bytes.size(), bytes))


## Les valeurs du tampon `buffer`.
func read_buffer(buffer: RID) -> PackedFloat32Array:
	return rd.buffer_get_data(buffer).to_float32_array()
#@ 12+


## Une texture d'un flottant par case, que les shaders lisent et écrivent comme une image.
func new_texture(width: int, height: int) -> RID:
	var format: RDTextureFormat = RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	format.width = width
	format.height = height
	format.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT)
	return keep(rd.texture_create(format, RDTextureView.new()))


## Recopie `field` dans `texture`, de la même taille.
func upload(texture: RID, field: FluidField) -> void:
	rd.texture_update(texture, 0, field.data.to_byte_array())


## Recopie `texture` dans `field`, de la même taille.
func download(texture: RID, field: FluidField) -> void:
	field.data = rd.texture_get_data(texture, 0).to_float32_array()
#@ 13+


## L'image des murs : un octet par case, qui suffit à dire plein ou libre.
func new_mask(walls: ObstacleMask) -> RID:
	var format: RDTextureFormat = RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	format.width = walls.width
	format.height = walls.height
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	return keep(rd.texture_create(format, RDTextureView.new(), [walls.solid]))
#@ all


## Envoie à la carte ce qu'on lui a demandé, et attend qu'elle ait fini.
func finish() -> void:
	rd.submit()
	rd.sync()


## Rend tout à la carte, du dernier créé au premier (un pipeline dépend de son shader), puis ferme l'appareil.
func release() -> void:
	for i: int in range(_owned.size() - 1, -1, -1):
		rd.free_rid(_owned[i])
	_owned.clear()
	rd.free()
	rd = null
