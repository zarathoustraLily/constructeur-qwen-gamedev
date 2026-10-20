extends Node
## Écume de la mer : une texture calculée sur la carte graphique (accumulate_foam.glsl), centrée sur le
## joueur, à partir des ondulations, des vagues d'impact, de la houle FFT et des points ajoutés par
## add_foam() (sillage des roues). La texture est transmise aux matériaux `target_materials` sous le
## nom `texture_target`. Le calcul tourne sur le fil de rendu ; deux textures alternent d'une image à l'autre.

## Résolution de la texture d'écume (pixels).
@export var texture_resolution : Vector2i = Vector2i(512, 512)
## Surface couverte par la texture (m), centrée sur le joueur.
@export var texture_size : Vector2 = Vector2(64, 64)
## Centre de la texture dans le monde : la position du joueur.
@export var texture_offset : Vector3 = Vector3.ZERO
## Matériaux qui reçoivent la texture d'écume.
@export var target_materials : Array[ShaderMaterial]
## Nom du paramètre de shader qui reçoit la texture ; les suffixes `_resolution`, `_size` et
## `_offset` nomment les autres paramètres transmis.
@export var texture_target : String = "foam_texture"

## Centre (en pixels) de chacune des deux textures, pour recaler l'écume quand le joueur avance.
var texture_centers : Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
## Centre courant de la texture, en pixels.
var texture_pixel_offset : Vector2i

#INTERNAL, THESE ARE UPDATED BY THE OCEAN
## Rapport d'échelle entre la texture d'écume et celle des ondulations (fixé par l'océan à chaque image).
var ripples_size_ratio : Vector2
## Résolution de la texture des ondulations (fixée par l'océan).
var ripples_resolution : Vector2
## Jeu d'uniformes de la texture des ondulations en cours (fixé par l'océan).
var ripples_texture_set : RID

## Rapport d'échelle entre la texture d'écume et celle des vagues d'impact (fixé par l'océan).
var waves_size_ratio : Vector2
## Résolution de la texture des vagues d'impact (fixée par l'océan).
var waves_resolution : Vector2
## Jeu d'uniformes de la texture des vagues d'impact en cours (fixé par l'océan).
var waves_texture_set : RID

## Nombre de cascades de houle attendues.
const FFT_CASCADE_COUNT = 3
## Rapport d'échelle entre la texture d'écume et la simulation de houle (fixé par l'océan).
var fft_size_ratio : Vector2
## Résolution de la simulation de houle (fixée par l'océan).
var fft_resolution : Vector2
## Décalage de la houle dû au vent (fixé par l'océan).
var fft_wind_uv_offset : Vector2
## Échelle de chaque cascade de houle (fixée par l'océan).
var fft_cascade_uv_scaled : Array[float] = [0.0, 0.0, 0.0]
## Échelle générale des coordonnées de la houle (fixée par l'océan).
var fft_uv_scale : float
## Jeu d'uniformes des textures de houle, créé une fois par create_fft_waves_cascades_set().
var fft_waves_texture_set : RID
## Vrai une fois ce jeu d'uniformes créé.
var fft_waves_texture_set_initialized: bool = false
#END INTERNAL

## Texture lue par les matériaux ; elle désigne à chaque image la dernière texture calculée.
var foam_texture : Texture2DRD
## Indice (0 ou 1) de la texture écrite à cette image.
var next_texture : int = 0
## Inutilisée.
var frame_number : int = 0

## Nombre de textures qui alternent.
const PING_PONG_AMOUNT : int = 2

## Écume injectée (sillage des roues) : (x, z monde, quantité, rayon en mètres)
var foam_origins : Array[Vector4] = []
## Limité par la taille des push constants (128 octets) : voir accumulate_foam.glsl
const MAX_FOAM_POINTS_PER_FRAME := 2

## Ajoute de l'écume en `position` (monde) : quantité `amount` (de 0 à 1), rayon `radius` (m).
## À chaque image, seuls les points les plus forts sont gardés.
func add_foam(position: Vector3, amount: float, radius: float) -> void:
	foam_origins.append(Vector4(position.x, position.z, amount, radius))

func _take_foam_points() -> Array[Vector4]:
	foam_origins.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.z * a.w > b.z * b.w)
	var points : Array[Vector4] = []
	var px_per_m := Vector2(texture_resolution) / texture_size
	for i: int in mini(foam_origins.size(), MAX_FOAM_POINTS_PER_FRAME):
		var o := foam_origins[i]
		var pixel := Vector2(o.x, o.y) * px_per_m - Vector2(texture_pixel_offset) + Vector2(texture_resolution) * 0.5
		points.append(Vector4(pixel.x, pixel.y, o.z, o.w * px_per_m.x))
	foam_origins.clear()
	return points


## Recentre la texture d'écume sur `pos`.
func set_player_position(pos : Vector3) -> void:
	texture_offset = pos

func _ready() -> void:
	RenderingServer.call_on_render_thread(_initialize_compute_code)

	for i in range(PING_PONG_AMOUNT):
		texture_centers[i] = Vector2i.ZERO
		
	foam_texture = Texture2DRD.new()
	$TextureRect.texture = foam_texture
	for material in target_materials:
		material.set_shader_parameter(texture_target, foam_texture)
		material.set_shader_parameter(texture_target + "_resolution", texture_resolution)
		material.set_shader_parameter(texture_target + "_size", texture_size)


func _exit_tree() -> void:
	if foam_texture:
		foam_texture.texture_rd_rid = RID()

	RenderingServer.call_on_render_thread(_free_compute_resources)

func _process(_delta: float) -> void:
	next_texture = (next_texture + 1) % PING_PONG_AMOUNT
	if foam_texture:
		foam_texture.texture_rd_rid = texture_rds[next_texture]
	var offset: Vector2 = Vector2(texture_offset.x, texture_offset.z);
	var offset_scalar: Vector2 = Vector2(texture_resolution) / texture_size
	texture_pixel_offset = offset_scalar * offset
	
	texture_centers[next_texture] = texture_pixel_offset;
		
	for material in target_materials:
		material.set_shader_parameter(texture_target + "_offset", Vector2(texture_pixel_offset) / offset_scalar)
		
	RenderingServer.call_on_render_thread(_render_process.bind(next_texture, _take_foam_points()))
	

###############################################################################
# Everything after this point is designed to run on our rendering thread.

## Appareil de rendu (RenderingDevice) du fil de rendu.
var rd : RenderingDevice

## Shader de calcul de l'écume.
var shader : RID
## Pipeline de calcul du shader.
var pipeline : RID

## Les deux textures d'écume (RID du RenderingDevice).
var texture_rds : Array = [ RID(), RID() ]
## Jeux d'uniformes en lecture des deux textures.
var texture_sets : Array = [ RID(), RID() ]
## Sets pour le slot 1 (image « writeonly ») : obligatoire depuis Godot 4.7
var texture_write_sets : Array = [ RID(), RID() ]

## Crée, une seule fois, le jeu d'uniformes qui donne au shader d'écume les textures des cascades de houle.
func create_fft_waves_cascades_set(textures : Array[Texture2DRD]) -> void:
	if fft_waves_texture_set_initialized:
		return
	if textures.size() != FFT_CASCADE_COUNT:
		printerr("Not the right amount of casccades supplied to the foam shader")
	
	var uniforms : Array[RDUniform] = []
	var sampler: RDSamplerState = RDSamplerState.new()
	sampler.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
	sampler.mag_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler.min_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	sampler.mip_filter = RenderingDevice.SAMPLER_FILTER_LINEAR
	var sampler_rid  : RID = rd.sampler_create(sampler)
	for i in range(textures.size()):
		var uniform := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		uniform.binding = i
		uniform.add_id(sampler_rid)
		uniform.add_id(textures[i].texture_rd_rid)
		uniforms.append(uniform)
		
	fft_waves_texture_set = rd.uniform_set_create(uniforms, shader, 4)
	
	fft_waves_texture_set_initialized = true

func _create_uniform_set(texture_rd : RID, set_index : int) -> RID:
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = 0
	uniform.add_id(texture_rd)
	return rd.uniform_set_create([uniform], shader, set_index)


var _init_done := false

func _initialize_compute_code() -> void:
	rd = RenderingServer.get_rendering_device()
	if not rd:
		return

	# Create our shader.
	var shader_file: RDShaderFile = load("res://1_core/water/waves/accumulate_foam.glsl")
	if not shader_file:
		return
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	if not shader_spirv:
		return
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	_init_done = true

	# Create our textures to manage our wave.
	var tf : RDTextureFormat = RDTextureFormat.new()
	tf.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	tf.width = texture_resolution.x
	tf.height = texture_resolution.y
	tf.depth = 1
	tf.array_layers = 1
	tf.mipmaps = 1
	tf.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT + RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
		+ RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
		+ RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT

	for i in range(PING_PONG_AMOUNT):
		texture_rds[i] = rd.texture_create(tf, RDTextureView.new(), [])
		rd.texture_clear(texture_rds[i], Color(0, 0, 0, 0), 0, 1, 0, 1)
		texture_sets[i] = _create_uniform_set(texture_rds[i], 0)
		texture_write_sets[i] = _create_uniform_set(texture_rds[i], 1)


func _render_process(with_next_texture: int, foam_points : Array[Vector4]) -> void:
	if not _init_done or not rd:
		return
	var push_constant : PackedFloat32Array = PackedFloat32Array()
	var next_offset : Vector2 = texture_centers[with_next_texture]
	var current_offset : Vector2 = texture_centers[(with_next_texture - 1) % PING_PONG_AMOUNT]
	var texture_delta: Vector2 = (next_offset - current_offset).round()
	
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
	
	for i in range(MAX_FOAM_POINTS_PER_FRAME):
		var foam_point := foam_points[i] if i < foam_points.size() else Vector4.ZERO
		push_constant.push_back(foam_point.x)
		push_constant.push_back(foam_point.y)
		push_constant.push_back(foam_point.z)
		push_constant.push_back(foam_point.w)
	
	var x_groups: int = int((texture_resolution.x - 1) / 8.0) + 1
	var y_groups: int = int((texture_resolution.y - 1) / 8.0) + 1

	var next_set: RID = texture_write_sets[with_next_texture]
	var current_set: RID = texture_sets[(with_next_texture + 1) % PING_PONG_AMOUNT]

	# Run our compute shader.
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, current_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, next_set, 1)
	rd.compute_list_bind_uniform_set(compute_list, ripples_texture_set, 2)
	rd.compute_list_bind_uniform_set(compute_list, waves_texture_set, 3)
	rd.compute_list_bind_uniform_set(compute_list, fft_waves_texture_set, 4)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()
	
func _free_compute_resources() -> void:
	for i in range(PING_PONG_AMOUNT):
		if texture_rds[i]:
			rd.free_rid(texture_rds[i])

	if shader:
		rd.free_rid(shader)
