extends Node
## Ondulations et vagues d'impact : une propagation d'ondes calculée sur la carte graphique
## (water_waves_compute.glsl) dans une texture centrée sur le joueur. L'océan en utilise deux :
## WaterRipples (ondulations des roues) et WaterWaves (sillages, explosions). Les impulsions ajoutées
## par add_ripple() s'y propagent. La texture est transmise à `water_material` ; elle peut aussi être
## relue par le processeur pour get_height(). Trois textures alternent d'une image à l'autre.

## Résolution de la texture (pixels).
@export var texture_resolution : Vector2i = Vector2i(512, 512)
## Surface couverte par la texture (m), centrée sur le joueur.
@export var texture_size : Vector2 = Vector2(64, 64)
## Centre de la texture dans le monde (fixé par l'océan à la position du joueur).
@export var texture_offset : Vector3 = Vector3.ZERO
## Matériau de l'eau qui reçoit la texture.
@export var water_material : ShaderMaterial
## Coefficient d'amortissement transmis au shader de calcul.
@export var damp : float = 1.0
## Coefficient de vitesse de propagation (c²) transmis au shader de calcul.
@export var c2 : float = 0.09

## Nom du paramètre de shader qui reçoit la texture ; les suffixes `_resolution`, `_size` et
## `_offset` nomment les autres paramètres transmis.
@export var texture_target : String = "waves_texture"

## Centre (en pixels) de chacune des trois textures.
var ripple_texture_centers : Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO]
## Centre courant de la texture, en pixels.
var texture_pixel_offset : Vector2i
## Impulsions en attente : (x, z monde, hauteur, rayon en pixels)
var ripple_origins : Array[Vector4] = [];
## Nombre d'impulsions envoyées au compute shader à chaque image (voir water_waves_compute.glsl)
const MAX_POINTS_PER_FRAME := 4

#used for CPU side collisions
## Relit la texture côté processeur, pour que get_height() donne la hauteur des vagues.
@export var use_cpu_readback : bool = true
## Une relecture toutes les `cpu_readback_interval` images.
@export var cpu_readback_interval : int = 2
## Dernière image relue (hauteurs), lue par get_height().
var water_image : Image 



## Inutilisée.
var t: float = 0.0
## Inutilisée.
var max_t: float = 0.1

## Texture lue par le matériau ; elle désigne à chaque image la dernière texture calculée.
var water_texture : Texture2DRD
## Indice (0 à 2) de la texture écrite à cette image.
var next_texture : int = 0
## Compteur d'images, pour l'intervalle de relecture.
var frame_number : int = 0

## height : hauteur de l'impulsion, radius_px : rayon en pixels de la texture
## (les appels existants passent déjà (position, hauteur, rayon) dans cet ordre).
func add_ripple(position: Vector3, height: float, radius_px: float) -> void:
	ripple_origins.append(Vector4(position.x, position.z, height, radius_px))

## Garde les impulsions les plus fortes de l'image, converties en pixels de la texture de sortie.
func _take_frame_points() -> Array[Vector4]:
	ripple_origins.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.z * a.w > b.z * b.w)
	var points : Array[Vector4] = []
	var px_per_m := Vector2(texture_resolution) / texture_size
	for i: int in mini(ripple_origins.size(), MAX_POINTS_PER_FRAME):
		var o := ripple_origins[i]
		var pixel := Vector2(o.x, o.y) * px_per_m - Vector2(texture_pixel_offset) + Vector2(texture_resolution) * 0.5
		points.append(Vector4(round(pixel.x), round(pixel.y), o.z, o.w))
	ripple_origins.clear()
	return points

## Jeu d'uniformes en lecture de la texture calculée à cette image (lu par l'écume).
func get_current_image_set() -> RID:
	return texture_sets[next_texture]

func _ready() -> void:
	# In case we're running stuff on the rendering thread
	# we need to do our initialisation on that thread.
	RenderingServer.call_on_render_thread(_initialize_compute_code)

	for i in range(len(ripple_texture_centers)):
		ripple_texture_centers[i] = Vector2i.ZERO
		
	water_texture = Texture2DRD.new()
	
	if use_cpu_readback:
		water_image = Image.create(texture_resolution.x, texture_resolution.y, false, Image.FORMAT_RF)	
		
	if water_material:
		water_material.set_shader_parameter(texture_target, water_texture)
		water_material.set_shader_parameter(texture_target + "_resolution", texture_resolution)
		water_material.set_shader_parameter(texture_target + "_size", texture_size)


func _exit_tree() -> void:
	# Make sure we clean up!
	if water_texture:
		water_texture.texture_rd_rid = RID()

	RenderingServer.call_on_render_thread(_free_compute_resources)

func _process(_delta: float) -> void:
	next_texture = (next_texture + 1) % 3
	if water_texture:
		water_texture.texture_rd_rid = texture_rds[next_texture]
	var offset: Vector2 = Vector2(texture_offset.x, texture_offset.z);
	var offset_scalar: Vector2 = Vector2(texture_resolution) / texture_size
	texture_pixel_offset = offset_scalar * offset
	
	ripple_texture_centers[next_texture] = texture_pixel_offset;
		
	if water_material:		
		water_material.set_shader_parameter(texture_target + "_offset", Vector2(texture_pixel_offset) / offset_scalar)
	
	RenderingServer.call_on_render_thread(_render_process.bind(next_texture, _take_frame_points(), texture_resolution, texture_size))
	

###############################################################################
# Everything after this point is designed to run on our rendering thread.

## Appareil de rendu (RenderingDevice) du fil de rendu.
var rd : RenderingDevice

## Shader de calcul des vagues.
var shader : RID
## Pipeline de calcul du shader.
var pipeline : RID

## Les trois textures (RID du RenderingDevice).
var texture_rds : Array = [ RID(), RID(), RID() ]
## Sets en lecture (slots 0 et 1, et lus par le shader d'écume)
var texture_sets : Array = [ RID(), RID(), RID() ]
## Sets en écriture (slot 2). Depuis Godot 4.7, un set créé pour une image « readonly »
## ne peut plus être branché sur une image « writeonly » : le dispatch échouait à chaque image.
var texture_write_sets : Array = [ RID(), RID(), RID() ]

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
	var shader_file: RDShaderFile = load("res://1_core/water/waves/water_waves_compute.glsl")
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

	for i in range(3):
		# Create our texture.
		texture_rds[i] = rd.texture_create(tf, RDTextureView.new(), [])

		# Make sure our textures are cleared.
		rd.texture_clear(texture_rds[i], Color(0, 0, 0, 0), 0, 1, 0, 1)

		# Now create our uniform set so we can use these textures in our shader.
		texture_sets[i] = _create_uniform_set(texture_rds[i], 0)
		texture_write_sets[i] = _create_uniform_set(texture_rds[i], 2)


func _render_process(with_next_texture: int, wave_points : Array[Vector4], tex_resolution: Vector2i, _tex_size: Vector2) -> void:
	if not _init_done or not rd:
		return
	var push_constant : PackedFloat32Array = PackedFloat32Array()
	for i in range(MAX_POINTS_PER_FRAME):
		var wave_point := wave_points[i] if i < wave_points.size() else Vector4.ZERO
		push_constant.push_back(wave_point.x) # x pixel
		push_constant.push_back(wave_point.y) # z pixel
		push_constant.push_back(wave_point.z) # height
		push_constant.push_back(wave_point.w) # radius (pixels)

	push_constant.push_back(tex_resolution.x)
	push_constant.push_back(tex_resolution.y)
	
	# offsets
	var next_offset : Vector2 = ripple_texture_centers[with_next_texture]
	var current_offset : Vector2 = ripple_texture_centers[(with_next_texture - 1) % 3]
	var previous_offset : Vector2 = ripple_texture_centers[(with_next_texture - 2) % 3]
	
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

	var next_set: RID = texture_write_sets[with_next_texture]
	var current_set: RID = texture_sets[(with_next_texture - 1) % 3]
	var previous_set: RID = texture_sets[(with_next_texture - 2) % 3]

	# Run our compute shader.
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, current_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, previous_set, 1)
	rd.compute_list_bind_uniform_set(compute_list, next_set, 2)
	rd.compute_list_set_push_constant(compute_list, push_constant.to_byte_array(), push_constant.size() * 4)
	rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
	rd.compute_list_end()
	

	if use_cpu_readback:
		frame_number += 1
		if frame_number % cpu_readback_interval == 0:
			var lambda: Callable = func (array : PackedByteArray) -> void:
				water_image.set_data(texture_resolution.x, texture_resolution.y, false, Image.FORMAT_RF, array)
					
			rd.texture_get_data_async(texture_rds[with_next_texture], 0, lambda)

func _free_compute_resources() -> void:
	for i in range(3):
		if texture_rds[i]:
			rd.free_rid(texture_rds[i])

	if shader:
		rd.free_rid(shader)


## Hauteur des vagues en `position` (monde), lue dans la dernière image relue ; 0 hors de la texture.
## Demande `use_cpu_readback`.
func get_height(position: Vector3) -> float:
	var pos: Vector2 = Vector2(position.x, position.z) - Vector2(texture_offset.x, texture_offset.z)
	pos += 0.5 * texture_size
	if pos.x < 0.0 or pos.y < 0.0 or pos.x >= texture_size.x or pos.y >= texture_size.y:
		return 0.0

	var uv: Vector2 = pos / texture_size * Vector2(texture_resolution)
	var px: Vector2 = floor(uv)
	var frac: Vector2 = uv - px

	var x: int = int(px.x)
	var y: int = int(px.y)

	if x < 0 or y < 0 or x >= texture_resolution.x - 1 or y >= texture_resolution.y - 1:
		return 0.0

	var v00: float = water_image.get_pixel(x,     y    ).r
	var v10: float = water_image.get_pixel(x + 1, y    ).r
	var v01: float = water_image.get_pixel(x,     y + 1).r
	var v11: float = water_image.get_pixel(x + 1, y + 1).r

	# Bilinear interpolation
	var v0: float = lerp(v00, v10, frac.x)
	var v1: float = lerp(v01, v11, frac.x)
	return lerp(v0, v1, frac.y)

	
