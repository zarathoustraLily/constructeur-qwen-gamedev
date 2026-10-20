class_name WaterFoamView extends Node
## Écume de la mer : une texture calculée sur la carte graphique (accumulate_foam.glsl), centrée sur le
## joueur, à partir des ondulations, des vagues d'impact, de la houle FFT et des points ajoutés par add_foam()
## (sillage des roues). La texture est transmise aux matériaux `target_materials` sous le nom
## `texture_target`. Deux textures alternent d'une image à l'autre. C'est une présentation : l'écume ne porte
## rien, elle se dessine.
## Sans RenderingDevice (rendu de compatibilité, ou sans fenêtre), rien n'est calculé.

## Nombre de cascades de houle attendues.
const FFT_CASCADE_COUNT := 3
## Nombre de textures qui alternent.
const PING_PONG_AMOUNT := 2
## Points d'écume par image : la taille des push constants (128 octets) le limite (voir accumulate_foam.glsl).
const MAX_FOAM_POINTS_PER_FRAME := 2

## Résolution de la texture d'écume (pixels).
@export var texture_resolution: Vector2i = Vector2i(512, 512)
## Côtés (m) de la surface couverte par la texture, centrée sur le joueur.
@export var texture_size: Vector2 = Vector2(64, 64)
## Centre de la texture dans le monde : la position du joueur.
@export var texture_offset: Vector3 = Vector3.ZERO
## Matériaux qui reçoivent la texture d'écume.
@export var target_materials: Array[ShaderMaterial]
## Nom du paramètre de shader qui reçoit la texture ; les suffixes `_resolution`, `_size` et `_offset`
## nomment les autres paramètres transmis.
@export var texture_target: String = "foam_texture"

## Centre (en pixels) de chacune des deux textures, pour recaler l'écume quand le joueur avance.
var texture_centers: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
## Centre courant de la texture, en pixels.
var texture_pixel_offset: Vector2i

# Donnés par l'océan à chaque pas de physique.
## Rapport d'échelle entre la texture d'écume et celle des ondulations.
var ripples_size_ratio: Vector2
## Résolution de la texture des ondulations.
var ripples_resolution: Vector2
## Jeu d'uniformes de la texture des ondulations en cours.
var ripples_texture_set: RID
## Rapport d'échelle entre la texture d'écume et celle des vagues d'impact.
var waves_size_ratio: Vector2
## Résolution de la texture des vagues d'impact.
var waves_resolution: Vector2
## Jeu d'uniformes de la texture des vagues d'impact en cours.
var waves_texture_set: RID
## Rapport d'échelle entre la texture d'écume et la simulation de houle.
var fft_size_ratio: Vector2
## Résolution de la simulation de houle.
var fft_resolution: Vector2
## Décalage de la houle dû au vent.
var fft_wind_uv_offset: Vector2
## Échelle de chaque cascade de houle.
var fft_cascade_uv_scaled: Array[float] = [0.0, 0.0, 0.0]
## Échelle générale des coordonnées de la houle.
var fft_uv_scale: float
## Jeu d'uniformes des textures de houle, créé une fois par create_fft_waves_cascades_set().
var fft_waves_texture_set: RID
## Vrai une fois ce jeu d'uniformes créé.
var fft_waves_texture_set_initialized: bool = false

## Texture lue par les matériaux ; elle désigne à chaque image la dernière texture calculée.
var foam_texture: Texture2DRD
## Indice (0 ou 1) de la texture écrite à cette image.
var next_texture: int = 0
## Écume en attente : (x, z du monde, quantité, rayon en mètres).
var foam_origins: Array[Vector4] = []


## Ajoute de l'écume en `position` (monde) : quantité `amount` (de 0 à 1), rayon `radius` (m). À chaque
## image, seuls les points les plus forts sont gardés.
func add_foam(position: Vector3, amount: float, radius: float) -> void:
	foam_origins.append(Vector4(position.x, position.z, amount, radius))


## Garde les points d'écume les plus forts de l'image (quantité × rayon), convertis en pixels de la texture, et
## vide l'attente.
func take_foam_points() -> Array[Vector4]:
	foam_origins.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.z * a.w > b.z * b.w)
	var points: Array[Vector4] = []
	var px_per_m := Vector2(texture_resolution) / texture_size
	for index: int in mini(foam_origins.size(), MAX_FOAM_POINTS_PER_FRAME):
		var origin := foam_origins[index]
		var pixel := Vector2(origin.x, origin.y) * px_per_m - Vector2(texture_pixel_offset) \
			+ Vector2(texture_resolution) * 0.5
		points.append(Vector4(pixel.x, pixel.y, origin.z, origin.w * px_per_m.x))
	foam_origins.clear()
	return points


func _ready() -> void:
	RenderingServer.call_on_render_thread(_initialize_compute_code)
	foam_texture = Texture2DRD.new()
	for material: ShaderMaterial in target_materials:
		material.set_shader_parameter(texture_target, foam_texture)
		material.set_shader_parameter(texture_target + "_resolution", texture_resolution)
		material.set_shader_parameter(texture_target + "_size", texture_size)


func _exit_tree() -> void:
	if foam_texture != null:
		foam_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_free_compute_resources)


func _process(_delta: float) -> void:
	next_texture = (next_texture + 1) % PING_PONG_AMOUNT
	if foam_texture != null:
		foam_texture.texture_rd_rid = texture_rds[next_texture]
	var px_per_m := Vector2(texture_resolution) / texture_size
	texture_pixel_offset = Vector2i(px_per_m * Vector2(texture_offset.x, texture_offset.z))
	texture_centers[next_texture] = texture_pixel_offset
	for material: ShaderMaterial in target_materials:
		material.set_shader_parameter(texture_target + "_offset", Vector2(texture_pixel_offset) / px_per_m)
	RenderingServer.call_on_render_thread(_render_process.bind(next_texture, take_foam_points()))


################################################################################
# Tout ce qui suit tourne sur le fil de rendu.

## Appareil de rendu (RenderingDevice) du fil de rendu.
var rd: RenderingDevice
## Shader de calcul de l'écume.
var shader: RID
## Pipeline de calcul du shader.
var pipeline: RID
## Les deux textures d'écume (RID du RenderingDevice).
var texture_rds: Array[RID] = [RID(), RID()]
## Jeux d'uniformes en lecture des deux textures.
var texture_sets: Array[RID] = [RID(), RID()]
## Jeux d'uniformes du point d'attache 1 (image « writeonly ») : obligatoires depuis Godot 4.7.
var texture_write_sets: Array[RID] = [RID(), RID()]

var _init_done: bool = false


## Crée, une seule fois, le jeu d'uniformes qui donne au shader d'écume les textures des cascades de houle.
## Sans RenderingDevice prêt, il attend l'appel suivant.
func create_fft_waves_cascades_set(textures: Array[Texture2DRD]) -> void:
	if fft_waves_texture_set_initialized or not _init_done:
		return
	if textures.size() != FFT_CASCADE_COUNT:
		push_error("Écume : %d cascades de houle reçues, %d attendues" % [textures.size(), FFT_CASCADE_COUNT])
	var uniforms: Array[RDUniform] = []
	var sampler := RDSamplerState.new()
	sampler.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	var sampler_rid := rd.sampler_create(sampler)
	for index: int in textures.size():
		var uniform := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		uniform.binding = index
		uniform.add_id(sampler_rid)
		uniform.add_id(textures[index].texture_rd_rid)
		uniforms.append(uniform)
	fft_waves_texture_set = rd.uniform_set_create(uniforms, shader, 4)
	fft_waves_texture_set_initialized = true


func _create_uniform_set(texture_rd: RID, set_index: int) -> RID:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(texture_rd)
	return rd.uniform_set_create([uniform], shader, set_index)


func _initialize_compute_code() -> void:
	rd = RenderingServer.get_rendering_device()
	if rd == null:
		return
	var shader_file: RDShaderFile = load("res://1_core/water/waves/accumulate_foam.glsl")
	if shader_file == null:
		return
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	if shader_spirv == null:
		return
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	_init_done = true

	# Les deux textures d'écume.
	var format := RDTextureFormat.new()
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	format.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	format.width = texture_resolution.x
	format.height = texture_resolution.y
	format.depth = 1
	format.array_layers = 1
	format.mipmaps = 1
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT + RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
		+ RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
		+ RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT
	for index: int in PING_PONG_AMOUNT:
		texture_rds[index] = rd.texture_create(format, RDTextureView.new(), [])
		rd.texture_clear(texture_rds[index], Color(0, 0, 0, 0), 0, 1, 0, 1)
		texture_sets[index] = _create_uniform_set(texture_rds[index], 0)
		texture_write_sets[index] = _create_uniform_set(texture_rds[index], 1)


func _render_process(with_next_texture: int, foam_points: Array[Vector4]) -> void:
	# L'écume lit aussi la houle : elle attend que l'océan lui ait donné ses cascades.
	if not _init_done or rd == null or not fft_waves_texture_set_initialized:
		return
	var current := posmod(with_next_texture - 1, PING_PONG_AMOUNT)
	var texture_delta := (Vector2(texture_centers[with_next_texture]) - Vector2(texture_centers[current])).round()
	var push_constant := PackedFloat32Array()
	push_constant.push_back(texture_resolution.x)
	push_constant.push_back(texture_resolution.y)
	push_constant.push_back(texture_delta.x)
	push_constant.push_back(texture_delta.y)
	push_constant.push_back(texture_size.x)
	push_constant.push_back(texture_size.y)
	push_constant.push_back(texture_offset.x)
	push_constant.push_back(texture_offset.z)
	push_constant.push_back(ripples_size_ratio.x)
	push_constant.push_back(ripples_size_ratio.y)
	push_constant.push_back(ripples_resolution.x)
	push_constant.push_back(ripples_resolution.y)
	push_constant.push_back(waves_size_ratio.x)
	push_constant.push_back(waves_size_ratio.y)
	push_constant.push_back(waves_resolution.x)
	push_constant.push_back(waves_resolution.y)
	push_constant.push_back(fft_size_ratio.x)
	push_constant.push_back(fft_size_ratio.y)
	push_constant.push_back(fft_resolution.x)
	push_constant.push_back(fft_resolution.y)
	push_constant.push_back(fft_cascade_uv_scaled[0])
	push_constant.push_back(fft_cascade_uv_scaled[1])
	push_constant.push_back(fft_cascade_uv_scaled[2])
	push_constant.push_back(fft_uv_scale)
	for index: int in MAX_FOAM_POINTS_PER_FRAME:
		var foam_point := foam_points[index] if index < foam_points.size() else Vector4.ZERO
		push_constant.push_back(foam_point.x)
		push_constant.push_back(foam_point.y)
		push_constant.push_back(foam_point.z)
		push_constant.push_back(foam_point.w)

	var x_groups: int = int((texture_resolution.x - 1) / 8.0) + 1
	var y_groups: int = int((texture_resolution.y - 1) / 8.0) + 1
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, texture_sets[current], 0)
	rd.compute_list_bind_uniform_set(compute_list, texture_write_sets[with_next_texture], 1)
	rd.compute_list_bind_uniform_set(compute_list, ripples_texture_set, 2)
	rd.compute_list_bind_uniform_set(compute_list, waves_texture_set, 3)
	rd.compute_list_bind_uniform_set(compute_list, fft_waves_texture_set, 4)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()


func _free_compute_resources() -> void:
	if rd == null:
		return
	for texture_rd: RID in texture_rds:
		if texture_rd.is_valid():
			rd.free_rid(texture_rd)
	if shader.is_valid():
		rd.free_rid(shader)
