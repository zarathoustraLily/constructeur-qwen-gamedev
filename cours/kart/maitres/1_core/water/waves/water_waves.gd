class_name WaterWaves extends Node
## Ondulations et vagues d'impact : une propagation d'ondes calculée sur la carte graphique
## (water_waves_compute.glsl) dans une texture centrée sur le joueur. L'océan en utilise deux :
## WaterRipples (ondulations des roues) et WaterWaves (sillages, explosions). Les impulsions ajoutées par
## add_ripple() s'y propagent. La texture est transmise à `water_material` ; elle peut aussi être relue par le
## processeur pour get_height() : les vagues d'impact portent alors ce qui flotte, et la simulation avance avec
## la physique. Trois textures alternent : la précédente, la courante et celle qu'on écrit.
## Sans RenderingDevice (rendu de compatibilité, ou sans fenêtre), rien n'est calculé et get_height() vaut 0.

## Nombre d'impulsions envoyées au shader de calcul à chaque pas (voir water_waves_compute.glsl).
const MAX_POINTS_PER_FRAME := 4
## Nombre de textures qui alternent.
const TEXTURE_COUNT := 3

## Résolution de la texture (pixels).
@export var texture_resolution: Vector2i = Vector2i(512, 512)
## Côtés (m) de la surface couverte par la texture, centrée sur le joueur.
@export var texture_size: Vector2 = Vector2(64, 64)
## Centre de la texture dans le monde (fixé par l'océan à la position du joueur).
@export var texture_offset: Vector3 = Vector3.ZERO
## Matériau de l'eau qui reçoit la texture.
@export var water_material: ShaderMaterial
## Coefficient d'amortissement transmis au shader de calcul.
@export var damp: float = 1.0
## Coefficient de vitesse de propagation (c²) transmis au shader de calcul.
@export var c2: float = 0.09
## Nom du paramètre de shader qui reçoit la texture ; les suffixes `_resolution`, `_size` et `_offset`
## nomment les autres paramètres transmis.
@export var texture_target: String = "waves_texture"
## Relit la texture sur le processeur, pour que get_height() donne la hauteur des vagues.
@export var use_cpu_readback: bool = true
## Une relecture tous les `cpu_readback_interval` pas.
@export var cpu_readback_interval: int = 2

## Centre (en pixels) de chacune des trois textures.
var ripple_texture_centers: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]
## Centre courant de la texture, en pixels.
var texture_pixel_offset: Vector2i
## Impulsions en attente : (x, z du monde, hauteur, rayon en pixels).
var ripple_origins: Array[Vector4] = []
## Dernière image relue (hauteurs), lue par get_height().
var water_image: Image
## Texture lue par le matériau ; elle désigne à chaque pas la dernière texture calculée.
var water_texture: Texture2DRD
## Indice (0 à 2) de la texture écrite à ce pas.
var next_texture: int = 0
## Compteur de pas, pour l'intervalle de relecture.
var frame_number: int = 0


## Ajoute une impulsion en `position` (monde), de hauteur `height` et de rayon `radius_px` (pixels de la
## texture).
func add_ripple(position: Vector3, height: float, radius_px: float) -> void:
	ripple_origins.append(Vector4(position.x, position.z, height, radius_px))


## Garde les impulsions les plus fortes du pas (hauteur × rayon), converties en pixels de la texture, et vide
## l'attente.
func take_frame_points() -> Array[Vector4]:
	ripple_origins.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.z * a.w > b.z * b.w)
	var points: Array[Vector4] = []
	var px_per_m := Vector2(texture_resolution) / texture_size
	for index: int in mini(ripple_origins.size(), MAX_POINTS_PER_FRAME):
		var origin := ripple_origins[index]
		var pixel := Vector2(origin.x, origin.y) * px_per_m - Vector2(texture_pixel_offset) \
			+ Vector2(texture_resolution) * 0.5
		points.append(Vector4(round(pixel.x), round(pixel.y), origin.z, origin.w))
	ripple_origins.clear()
	return points


## Jeu d'uniformes en lecture de la texture calculée à ce pas (lu par l'écume).
func get_current_image_set() -> RID:
	return texture_sets[next_texture]


func _ready() -> void:
	# Les ressources de la carte graphique se créent sur le fil de rendu.
	RenderingServer.call_on_render_thread(_initialize_compute_code)
	water_texture = Texture2DRD.new()
	if use_cpu_readback:
		water_image = Image.create(texture_resolution.x, texture_resolution.y, false, Image.FORMAT_RF)
	if water_material != null:
		water_material.set_shader_parameter(texture_target, water_texture)
		water_material.set_shader_parameter(texture_target + "_resolution", texture_resolution)
		water_material.set_shader_parameter(texture_target + "_size", texture_size)


func _exit_tree() -> void:
	if water_texture != null:
		water_texture.texture_rd_rid = RID()
	RenderingServer.call_on_render_thread(_free_compute_resources)


func _physics_process(_delta: float) -> void:
	next_texture = (next_texture + 1) % TEXTURE_COUNT
	if water_texture != null:
		water_texture.texture_rd_rid = texture_rds[next_texture]
	var px_per_m := Vector2(texture_resolution) / texture_size
	texture_pixel_offset = Vector2i(px_per_m * Vector2(texture_offset.x, texture_offset.z))
	ripple_texture_centers[next_texture] = texture_pixel_offset
	if water_material != null:
		water_material.set_shader_parameter(texture_target + "_offset", Vector2(texture_pixel_offset) / px_per_m)
	RenderingServer.call_on_render_thread(_render_process.bind(next_texture, take_frame_points(), texture_resolution))


## Hauteur des vagues en `position` (monde), lue dans la dernière image relue ; 0 hors de la texture, ou sans
## relecture.
func get_height(position: Vector3) -> float:
	if water_image == null:
		return 0.0
	var pos := Vector2(position.x, position.z) - Vector2(texture_offset.x, texture_offset.z) + texture_size * 0.5
	if pos.x < 0.0 or pos.y < 0.0 or pos.x >= texture_size.x or pos.y >= texture_size.y:
		return 0.0
	return ImageSampling.bilinear(water_image, pos / texture_size).r


################################################################################
# Tout ce qui suit tourne sur le fil de rendu.

## Appareil de rendu (RenderingDevice) du fil de rendu.
var rd: RenderingDevice
## Shader de calcul des vagues.
var shader: RID
## Pipeline de calcul du shader.
var pipeline: RID
## Les trois textures (RID du RenderingDevice).
var texture_rds: Array[RID] = [RID(), RID(), RID()]
## Jeux d'uniformes en lecture (points d'attache 0 et 1, et lus par le shader d'écume).
var texture_sets: Array[RID] = [RID(), RID(), RID()]
## Jeux d'uniformes en écriture (point d'attache 2). Depuis Godot 4.7, un jeu créé pour une image « readonly »
## ne peut plus servir pour une image « writeonly » : le calcul échouait à chaque pas.
var texture_write_sets: Array[RID] = [RID(), RID(), RID()]

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
	var shader_file: RDShaderFile = load("res://1_core/water/waves/water_waves_compute.glsl")
	if shader_file == null:
		return
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	if shader_spirv == null:
		return
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	_init_done = true

	# Les textures de la propagation.
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
	for index: int in TEXTURE_COUNT:
		texture_rds[index] = rd.texture_create(format, RDTextureView.new(), [])
		rd.texture_clear(texture_rds[index], Color(0, 0, 0, 0), 0, 1, 0, 1)
		texture_sets[index] = _create_uniform_set(texture_rds[index], 0)
		texture_write_sets[index] = _create_uniform_set(texture_rds[index], 2)


func _render_process(with_next_texture: int, wave_points: Array[Vector4], tex_resolution: Vector2i) -> void:
	if not _init_done or rd == null:
		return
	var push_constant := PackedFloat32Array()
	for index: int in MAX_POINTS_PER_FRAME:
		var wave_point := wave_points[index] if index < wave_points.size() else Vector4.ZERO
		push_constant.push_back(wave_point.x)  # x en pixels
		push_constant.push_back(wave_point.y)  # z en pixels
		push_constant.push_back(wave_point.z)  # hauteur
		push_constant.push_back(wave_point.w)  # rayon (pixels)
	push_constant.push_back(tex_resolution.x)
	push_constant.push_back(tex_resolution.y)

	# Centres des trois textures : la texture suivante, la courante et la précédente.
	var current := posmod(with_next_texture - 1, TEXTURE_COUNT)
	var previous := posmod(with_next_texture - 2, TEXTURE_COUNT)
	var next_offset := Vector2(ripple_texture_centers[with_next_texture])
	var current_offset := Vector2(ripple_texture_centers[current])
	var previous_offset := Vector2(ripple_texture_centers[previous])
	push_constant.push_back(current_offset.x)
	push_constant.push_back(current_offset.y)
	push_constant.push_back(previous_offset.x)
	push_constant.push_back(previous_offset.y)
	push_constant.push_back(next_offset.x)
	push_constant.push_back(next_offset.y)
	push_constant.push_back(damp)
	push_constant.push_back(c2)
	push_constant.push_back(0.0)
	push_constant.push_back(0.0)

	var x_groups: int = int((tex_resolution.x - 1) / 8.0) + 1
	var y_groups: int = int((tex_resolution.y - 1) / 8.0) + 1
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, texture_sets[current], 0)
	rd.compute_list_bind_uniform_set(compute_list, texture_sets[previous], 1)
	rd.compute_list_bind_uniform_set(compute_list, texture_write_sets[with_next_texture], 2)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()

	if use_cpu_readback:
		frame_number += 1
		if frame_number % cpu_readback_interval == 0:
			var on_data: Callable = func(array: PackedByteArray) -> void:
				water_image.set_data(texture_resolution.x, texture_resolution.y, false, Image.FORMAT_RF, array)
			rd.texture_get_data_async(texture_rds[with_next_texture], 0, on_data)


func _free_compute_resources() -> void:
	if rd == null:
		return
	for texture_rd: RID in texture_rds:
		if texture_rd.is_valid():
			rd.free_rid(texture_rd)
	if shader.is_valid():
		rd.free_rid(shader)
