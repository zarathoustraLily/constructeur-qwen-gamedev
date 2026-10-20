class_name TireMarksManager extends Node
## Traces de pneus : une texture calculée sur la carte graphique (tire_marks_shader.glsl), centrée sur le
## joueur, où chaque roue au sol imprime sa marque, qui reste. La texture est transmise aux matériaux
## `island_material` sous le nom `texture_target` : le terrain s'y assombrit, l'herbe s'y couche. Deux textures
## alternent d'une image à l'autre (l'une est lue pendant que l'autre est écrite). Les traces se dessinent
## seulement : c'est une présentation. Sans RenderingDevice (rendu de compatibilité, ou sans fenêtre), rien
## n'est calculé.

## Nombre de textures qui alternent.
const PING_PONG_AMOUNT := 2
## Marques envoyées au shader de calcul à chaque image (voir tire_marks_shader.glsl).
const MAX_MARKS_PER_FRAME := 4

## Résolution de la texture des traces (pixels).
@export var texture_resolution: Vector2i = Vector2i(512, 512)
## Côtés (m) de la surface couverte par la texture, centrée sur le joueur.
@export var texture_size: Vector2 = Vector2(64, 64)
## Centre de la texture dans le monde : la position du joueur (voir set_player_position()).
@export var texture_offset: Vector3 = Vector3.ZERO
## Matériaux qui reçoivent la texture des traces.
@export var island_material: Array[ShaderMaterial]
## Nom du paramètre de shader qui reçoit la texture ; les suffixes `_resolution`, `_size` et `_offset` nomment
## les autres paramètres transmis.
@export var texture_target: String = "tire_marks_texture"

## Centre (en pixels) de chacune des deux textures, pour recaler les traces quand le joueur avance.
var texture_centers: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
## Centre courant de la texture, en pixels.
var texture_pixel_offset: Vector2i
## Marques en attente pour l'image : (x et z en pixels, force, rayon en pixels).
var tire_origins: Array[Vector4] = []
## Texture lue par les matériaux ; elle désigne à chaque image la dernière texture calculée.
var tire_marks_texture: Texture2DRD
## Indice (0 ou 1) de la texture écrite à cette image.
var next_texture: int = 0


## Imprime une marque de roue en `position` (monde) : force `strength` (0 pour une roue en l'air, 1 pleine),
## rayon `radius_px` (pixels de la texture). Elle est prise en compte au prochain calcul.
func add_tire(position: Vector3, strength: float, radius_px: float) -> void:
	var px_per_m := Vector2(texture_resolution) / texture_size
	var pixel := px_per_m * Vector2(position.x, position.z) - Vector2(texture_pixel_offset) \
		+ Vector2(texture_resolution) * 0.5
	tire_origins.append(Vector4(floorf(pixel.x), floorf(pixel.y), strength, radius_px))


## Recentre la texture des traces sur `pos`.
func set_player_position(pos: Vector3) -> void:
	texture_offset = pos


## Les marques de l'image, au plus MAX_MARKS_PER_FRAME, et vide l'attente.
func take_marks() -> Array[Vector4]:
	var marks: Array[Vector4] = tire_origins.slice(0, MAX_MARKS_PER_FRAME)
	tire_origins.clear()
	return marks


func _ready() -> void:
	RenderingServer.call_on_render_thread(_initialize_compute_code)
	tire_marks_texture = Texture2DRD.new()
	for material: ShaderMaterial in island_material:
		material.set_shader_parameter(texture_target, tire_marks_texture)
		material.set_shader_parameter(texture_target + "_resolution", texture_resolution)
		material.set_shader_parameter(texture_target + "_size", texture_size)


func _exit_tree() -> void:
	if tire_marks_texture != null:
		tire_marks_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_free_compute_resources)


func _process(_delta: float) -> void:
	next_texture = (next_texture + 1) % PING_PONG_AMOUNT
	if tire_marks_texture != null:
		tire_marks_texture.texture_rd_rid = texture_rds[next_texture]
	var px_per_m := Vector2(texture_resolution) / texture_size
	texture_pixel_offset = Vector2i(px_per_m * Vector2(texture_offset.x, texture_offset.z))
	texture_centers[next_texture] = texture_pixel_offset
	for material: ShaderMaterial in island_material:
		material.set_shader_parameter(texture_target + "_offset", Vector2(texture_pixel_offset) / px_per_m)
	# Une copie des marques part sur le fil de rendu : l'attente se vide ici, sur le fil principal.
	RenderingServer.call_on_render_thread(_render_process.bind(next_texture, take_marks()))


################################################################################
# Tout ce qui suit tourne sur le fil de rendu.

## Appareil de rendu (RenderingDevice) du fil de rendu.
var rd: RenderingDevice
## Shader de calcul des traces.
var shader: RID
## Pipeline de calcul du shader.
var pipeline: RID
## Les deux textures de traces (RID du RenderingDevice).
var texture_rds: Array[RID] = [RID(), RID()]
## Jeux d'uniformes en lecture (point d'attache 0) des deux textures.
var texture_sets: Array[RID] = [RID(), RID()]
## Jeux d'uniformes du point d'attache 1 (image « writeonly ») : obligatoires depuis Godot 4.7.
var texture_write_sets: Array[RID] = [RID(), RID()]

var _init_done: bool = false


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
	var shader_file: RDShaderFile = load("res://1_core/effects/tire_marks/tire_marks_shader.glsl")
	if shader_file == null:
		return
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	if shader_spirv == null:
		return
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	_init_done = true

	# Les deux textures de traces.
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


func _render_process(with_next_texture: int, marks: Array[Vector4]) -> void:
	if not _init_done or rd == null:
		return
	var push_constant := PackedFloat32Array()
	for index: int in MAX_MARKS_PER_FRAME:
		var mark := marks[index] if index < marks.size() else Vector4.ZERO
		push_constant.push_back(mark.x)  # x en pixels
		push_constant.push_back(mark.y)  # z en pixels
		push_constant.push_back(mark.z)  # force
		push_constant.push_back(mark.w)  # rayon (pixels)
	push_constant.push_back(texture_resolution.x)
	push_constant.push_back(texture_resolution.y)

	# Centres des deux textures : la courante, lue, et celle qu'on écrit.
	var current := posmod(with_next_texture - 1, PING_PONG_AMOUNT)
	var current_offset := Vector2(texture_centers[current])
	var next_offset := Vector2(texture_centers[with_next_texture])
	push_constant.push_back(current_offset.x)
	push_constant.push_back(current_offset.y)
	push_constant.push_back(next_offset.x)
	push_constant.push_back(next_offset.y)
	push_constant.push_back(0.0)
	push_constant.push_back(0.0)

	var x_groups: int = int((texture_resolution.x - 1) / 8.0) + 1
	var y_groups: int = int((texture_resolution.y - 1) / 8.0) + 1
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, texture_sets[current], 0)
	rd.compute_list_bind_uniform_set(compute_list, texture_write_sets[with_next_texture], 1)
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
