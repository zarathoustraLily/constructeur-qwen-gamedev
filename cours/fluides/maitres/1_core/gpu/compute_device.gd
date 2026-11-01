class_name ComputeDevice extends RefCounted
## La carte graphique du simulateur : un appareil de calcul à soi, ses tampons, ses textures. La carte ne connaît pas la mémoire
## de Godot : ce qu'on y crée y reste jusqu'à ce qu'on le rende. Tout est donc noté ici, et `release` rend tout.

## L'appareil : il vit à part du rendu de l'écran, et ne travaille que quand on le lui dit (`finish`).
var rd: RenderingDevice

var _owned: Array[RID] = []
#@ 16+
var _shared: bool = false
#@ 17+
var _filter: RID
#@ all


## Un appareil de calcul, ou null s'il n'y a pas de carte : sans fenêtre, Godot n'en ouvre aucune.
static func open() -> ComputeDevice:
	var device: RenderingDevice = RenderingServer.create_local_rendering_device()
	if device == null:
		return null
	var compute: ComputeDevice = ComputeDevice.new()
	compute.rd = device
	return compute
#@ 16+


## L'appareil du rendu de Godot, ou null sans carte (sans fenêtre, ou en Compatibilité). Ses textures se montrent à l'écran sans
## repasser par le processeur. Il travaille avec le rendu : on lui parle par `RenderingServer.call_on_render_thread`.
static func shared() -> ComputeDevice:
	var device: RenderingDevice = RenderingServer.get_rendering_device()
	if device == null:
		return null
	var compute: ComputeDevice = ComputeDevice.new()
	compute.rd = device
	compute._shared = true
	return compute
#@ all


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


## Une texture d'un flottant par case, que les shaders lisent et écrivent comme une image. Elle part de zéro : la carte ne vide pas
## la mémoire qu'elle redonne, et une texture créée sans données garde ce que la précédente y a laissé.
func new_texture(width: int, height: int) -> RID:
	var format: RDTextureFormat = RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	format.width = width
	format.height = height
	format.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
#@ 14+
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
#@ 16+
			| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
#@ 12+
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT)
	var zeros: PackedByteArray = PackedByteArray()
	zeros.resize(width * height * 4)
	zeros.fill(0)
	return keep(rd.texture_create(format, RDTextureView.new(), [zeros]))


## Recopie `field` dans `texture`, de la même taille.
func upload(texture: RID, field: FluidField) -> void:
	rd.texture_update(texture, 0, field.data.to_byte_array())


## Recopie `texture` dans `field`, de la même taille.
func download(texture: RID, field: FluidField) -> void:
	field.data = rd.texture_get_data(texture, 0).to_float32_array()
#@ 14+


## Recopie `source` dans `target`, de la même taille, sur la carte.
func copy(target: RID, source: RID) -> void:
	var format: RDTextureFormat = rd.texture_get_format(source)
	var size: Vector3 = Vector3(format.width, format.height, 1.0)
	rd.texture_copy(source, target, Vector3.ZERO, Vector3.ZERO, size, 0, 0, 0, 0)
#@ 13+


## L'image des murs : un octet par case, qui suffit à dire plein ou libre.
func new_mask(walls: ObstacleMask) -> RID:
	var format: RDTextureFormat = RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R8_UNORM
	format.width = walls.width
	format.height = walls.height
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	return keep(rd.texture_create(format, RDTextureView.new(), [walls.solid]))
#@ 17+


## Un volume de la carte, vide : un flottant par case, ou quatre si `vector` est vrai. Il est vidé sur la carte (`texture_clear`) : à
## cette taille, préparer ses zéros côté processeur coûterait des centaines de mégaoctets.
func new_volume(size: Vector3i, vector: bool) -> RID:
	var format: RDTextureFormat = RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT if vector else RenderingDevice.DATA_FORMAT_R32_SFLOAT
	format.texture_type = RenderingDevice.TEXTURE_TYPE_3D
	format.width = size.x
	format.height = size.y
	format.depth = size.z
	format.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
			| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT)
	var volume: RID = keep(rd.texture_create(format, RDTextureView.new()))
	rd.texture_clear(volume, Color(0.0, 0.0, 0.0, 0.0), 0, 1, 0, 1)
	return volume


## Le filtre de la carte : il mélange les huit cases autour d'un point, et s'arrête au bord du volume.
func trilinear() -> RID:
	if not _filter.is_valid():
		var state: RDSamplerState = RDSamplerState.new()
		state.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
		state.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
		state.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		state.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		state.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		_filter = keep(rd.sampler_create(state))
	return _filter
#@ 20+


## Une image de quatre flottants par case, vide, que les shaders écrivent et qu'on relit.
func new_color_texture(width: int, height: int) -> RID:
	var format: RDTextureFormat = RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	format.width = width
	format.height = height
	format.usage_bits = (RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
			| RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT)
	var texture: RID = keep(rd.texture_create(format, RDTextureView.new()))
	rd.texture_clear(texture, Color(0.0, 0.0, 0.0, 0.0), 0, 1, 0, 1)
	return texture
#@ all


## Envoie à la carte ce qu'on lui a demandé, et attend qu'elle ait fini.
#@ 16+
## L'appareil du rendu n'en a pas besoin : son travail part avec l'image.
#@ all
func finish() -> void:
#@ 16+
	if _shared:
		return
#@ all
	rd.submit()
	rd.sync()


## Rend tout à la carte, du dernier créé au premier (un pipeline dépend de son shader), puis ferme l'appareil.
func release() -> void:
	for i: int in range(_owned.size() - 1, -1, -1):
		rd.free_rid(_owned[i])
	_owned.clear()
#@ 11-15
	rd.free()
#@ 16+
	if not _shared:
		rd.free()
#@ all
	rd = null
