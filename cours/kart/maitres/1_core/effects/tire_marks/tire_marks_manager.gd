extends Node
## Traces de pneus : une texture calculée sur la carte graphique (tire_marks_shader.glsl), centrée
## sur le joueur, où chaque roue au sol imprime sa marque. La texture est transmise aux matériaux
## `island_material` sous le nom `texture_target`. Le calcul tourne sur le fil de rendu ; deux
## textures alternent d'une image à l'autre (l'une est lue pendant que l'autre est écrite).

## Résolution de la texture des traces (pixels).
@export var texture_resolution : Vector2i = Vector2i(512, 512)
## Surface couverte par la texture (m), centrée sur le joueur.
@export var texture_size : Vector2 = Vector2(64, 64)
## Centre de la texture dans le monde : la position du joueur (voir set_player_position()).
@export var texture_offset : Vector3 = Vector3.ZERO
## Matériaux qui reçoivent la texture des traces.
@export var island_material : Array[ShaderMaterial]

## Nom du paramètre de shader qui reçoit la texture ; les suffixes `_resolution`, `_size` et
## `_offset` nomment les autres paramètres transmis.
@export var texture_target : String = "tire_marks_texture"

## Centre (en pixels) de chacune des deux textures, pour recaler les traces quand le joueur avance.
var texture_centers : Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
## Centre courant de la texture, en pixels.
var texture_pixel_offset : Vector2i
## Marques en attente pour l'image : (x et z en pixels, rayon, force) ; quatre au plus sont envoyées.
var tire_origins : Array[Vector4] = [];

## Texture lue par les matériaux ; elle désigne à chaque image la dernière texture calculée.
var tire_marks_texture : Texture2DRD
## Indice (0 ou 1) de la texture écrite à cette image.
var next_texture : int = 0
## Inutilisée.
var frame_number : int = 0

## Nombre de textures qui alternent.
const PING_PONG_AMOUNT : int = 2

## Imprime une marque de roue en `position` (monde), de rayon `radius` et de force `strength`
## (0 pour une roue en l'air). Elle est prise en compte au prochain calcul.
func add_tire(position: Vector3, radius: float, strength: float) -> void:
	var pixel_position : Vector2i = Vector2(texture_resolution) / texture_size * Vector2(position.x, position.z)
	pixel_position -= texture_pixel_offset - Vector2i(texture_resolution * 0.5)
	tire_origins.append(Vector4(pixel_position.x, pixel_position.y, radius, strength))

## Recentre la texture des traces sur `pos` (le joueur l'appelle à chaque image).
func set_player_position(pos : Vector3) -> void:
	texture_offset = pos

func _ready() -> void:
	RenderingServer.call_on_render_thread(_initialize_compute_code)

	for i in range(PING_PONG_AMOUNT):
		texture_centers[i] = Vector2i.ZERO
		
	tire_marks_texture = Texture2DRD.new()
	
	for material in island_material:
		material.set_shader_parameter(texture_target, tire_marks_texture)
		material.set_shader_parameter(texture_target + "_resolution", texture_resolution)
		material.set_shader_parameter(texture_target + "_size", texture_size)


func _exit_tree() -> void:
	if tire_marks_texture:
		tire_marks_texture.texture_rd_rid = RID()

	RenderingServer.call_on_render_thread(_free_compute_resources)

func _process(_delta: float) -> void:
	next_texture = (next_texture + 1) % PING_PONG_AMOUNT
	if tire_marks_texture:
		tire_marks_texture.texture_rd_rid = texture_rds[next_texture]
	var offset: Vector2 = Vector2(texture_offset.x, texture_offset.z);
	var offset_scalar: Vector2 = Vector2(texture_resolution) / texture_size
	texture_pixel_offset = offset_scalar * offset
	
	texture_centers[next_texture] = texture_pixel_offset;
		
	for material in island_material:
		material.set_shader_parameter(texture_target + "_offset", Vector2(texture_pixel_offset) / offset_scalar)
		
	RenderingServer.call_on_render_thread(_render_process.bind(next_texture, tire_origins))
	

###############################################################################
# Everything after this point is designed to run on our rendering thread.

## Appareil de rendu (RenderingDevice) du fil de rendu.
var rd : RenderingDevice

## Shader de calcul des traces.
var shader : RID
## Pipeline de calcul du shader.
var pipeline : RID

## Les deux textures de traces (RID du RenderingDevice).
var texture_rds : Array = [ RID(), RID() ]
## Jeux d'uniformes en lecture (slot 0) des deux textures.
var texture_sets : Array = [ RID(), RID() ]
## Sets pour le slot 1 (image « writeonly ») : obligatoire depuis Godot 4.7
var texture_write_sets : Array = [ RID(), RID() ]

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
	var shader_file: RDShaderFile = load("res://1_core/effects/tire_marks/tire_marks_shader.glsl")
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


func _render_process(with_next_texture: int, tire_origins_list : Array[Vector4]) -> void:
	if not _init_done or not rd:
		return
	var push_constant : PackedFloat32Array = PackedFloat32Array()
	for i in range(4):
		var tire_origin: Vector4 = Vector4() if tire_origins_list.size() <= i else tire_origins_list[i]
		push_constant.push_back(tire_origin.x) # x position
		push_constant.push_back(tire_origin.y) # z position
		push_constant.push_back(tire_origin.z) # radius
		push_constant.push_back(tire_origin.w) # strength
	tire_origins_list.clear()

	push_constant.push_back(texture_resolution.x)
	push_constant.push_back(texture_resolution.y)
	
	# offsets
	var next_offset : Vector2 = texture_centers[with_next_texture]
	var current_offset : Vector2 = texture_centers[(with_next_texture - 1) % PING_PONG_AMOUNT]
	
	push_constant.push_back(current_offset.x)
	push_constant.push_back(current_offset.y)
	push_constant.push_back(next_offset.x)
	push_constant.push_back(next_offset.y)
	
	push_constant.push_back(0.0)
	push_constant.push_back(0.0)

	var x_groups: int = int((texture_resolution.x - 1) / 8.0) + 1
	var y_groups: int = int((texture_resolution.y - 1) / 8.0) + 1

	var next_set: RID = texture_write_sets[with_next_texture]
	var current_set: RID = texture_sets[(with_next_texture + 1) % PING_PONG_AMOUNT]

	# Run our compute shader.
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)

	rd.compute_list_bind_uniform_set(compute_list, current_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, next_set, 1)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()
	

func _free_compute_resources() -> void:
	for i in range(PING_PONG_AMOUNT):
		if texture_rds[i]:
			rd.free_rid(texture_rds[i])

	if shader:
		rd.free_rid(shader)
