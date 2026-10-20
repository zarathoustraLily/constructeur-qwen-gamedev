extends Resource
class_name OceanFFTWaves
## Simulation de la houle par transformée de Fourier rapide (FFT), calculée sur la carte graphique en
## plusieurs cascades d'échelles différentes : elle fournit les textures de déplacement de l'océan et
## la hauteur de la houle en un point. Largement reprise de https://github.com/tessarakkt/godot4-oceanfft

## Indice du jeu d'uniformes des shaders de calcul.
const UNIFORM_SET := 0
## Taille d'un groupe de travail des shaders de calcul (pixels par côté).
const WORK_GROUP_DIM := 32
## Nombre d'or, utilisé pour les échelles des cascades par défaut.
const GOLDEN_RATIO := 1.618033989

## Points d'attache (binding) des ressources dans les shaders de calcul.
enum Binding {
	SETTINGS = 0,
	INITIAL_SPECTRUM = 20,
	SPECTRUM = 21,
	PING = 25,
	PONG = 26,
	INPUT = 27,
	OUTPUT = 28,
	DISPLACEMENT = 30,
}

## Résolutions possibles de la simulation (pixels par côté).
enum FFTResolution {
	FFT_2x2 = 2,
	FFT_4x4 = 4,
	FFT_8x8 = 8,
	FFT_16x16 = 16,
	FFT_32x32 = 32,
	FFT_64x64 = 64,
	FFT_128x128 = 128,
	FFT_256x256 = 256,
	FFT_512x512 = 512,
	FFT_1024x1024 = 1024,
	FFT_2048x2048 = 2048,
}

## Vrai : simulate() lance la simulation (en sautant des images selon simulation_frameskip). Sans
## effet sur force_simulate(), qui la lance toujours : à couper si on appelle la simulation soi-même.
@export var simulation_enabled := true

## Matériau de la surface : son shader déforme le maillage avec les textures de déplacement produites ici,
## et dessine l'eau.
@export var material:ShaderMaterial

@export_group("Simulation")

## Graine du hasard de départ de la houle.
@export var random_seed: int = 0

## Nombre d'appels à simulate() sautés entre deux simulations. Pour des vagues fluides, il faut au moins
## 30 simulations par seconde : images par seconde / (frameskip + 1) ≥ 30.
## 0 : aucune image sautée.
@export_range(0, 30, 1) var simulation_frameskip := 0

## Fréquence à laquelle simulate() rapatrie la carte des hauteurs vers le processeur. La flottaison la lit :
## avec trop d'images sautées, ce qui flotte semble décroché des vagues dessinées. Avec
## simulation_frameskip, seules comptent les images où la simulation a eu lieu.
## −1 : jamais de rapatriement (la flottaison ne voit plus la houle).
## 0 : rapatriement à chaque simulation.
@export_range(-1, 30, 1) var heightmap_sync_frameskip := 0

## Résolution des textures de déplacement calculées par FFT dans les shaders de calcul.
@export var fft_resolution:FFTResolution = FFTResolution.FFT_256x256:
	set(new_fft_resolution):
		fft_resolution = new_fft_resolution
		_is_initial_spectrum_changed = true

## Côté (m) du carré d'océan simulé ; les textures se répètent au-delà.
@export_range(0, 2048) var horizontal_dimension := 256:
	set(new_horizontal_dimension):
		horizontal_dimension = new_horizontal_dimension
		_is_initial_spectrum_changed = true

## Échelle de temps de la simulation : accélère ou ralentit les vagues.
@export_range(0.001, 5.0) var time_scale := 1.0

## Plages de nombres d'onde du spectre d'énergie des vagues que couvre chaque cascade de
## déplacement.
@export var cascade_ranges:Array[Vector2] = [Vector2(0.0, 0.03), Vector2(0.03, 0.15), Vector2(0.15, 1.0)]

## Échelles UV appliquées à chaque cascade de déplacement quand elle déforme la surface.
@export var cascade_scales:Array[float] = [GOLDEN_RATIO * 2.0, GOLDEN_RATIO, 0.5]


@export_group("Déformation de la surface")

## Abaisse la surface de l'océan avec la distance à la caméra, de plus en plus vite : la courbure
## d'une planète.
@export_range(0.0, 0.001, 0.0000001) var planetary_curve_strength := 0.000001:
	set(new_planetary_curve_strength):
		planetary_curve_strength = new_planetary_curve_strength
		material.set_shader_parameter("planetary_curve_strength", planetary_curve_strength)

@export_subgroup("Atténuation de l'amplitude")

## Échelle d'amplitude des vagues à amplitude_scale_fade_distance de la caméra.
@export_range(0.0, 5.0, 0.01) var amplitude_scale_min := 0.25:
	set(new_amplitude_scale_min):
		amplitude_scale_min = new_amplitude_scale_min
		material.set_shader_parameter("amplitude_scale_min", amplitude_scale_min)

## Échelle d'amplitude des vagues près de la caméra.
@export_range(0.0, 5.0, 0.01) var amplitude_scale_max := 1.0:
	set(new_amplitude_scale_max):
		amplitude_scale_max = new_amplitude_scale_max
		material.set_shader_parameter("amplitude_scale_max", amplitude_scale_max)

## L'amplitude passe linéairement de amplitude_scale_max près de la caméra à amplitude_scale_min à
## cette distance (m).
@export_range(0.0, 32000.0, 10.0) var amplitude_scale_fade_distance := 12000.0:
	set(new_amplitude_scale_fade_distance):
		amplitude_scale_fade_distance = new_amplitude_scale_fade_distance
		material.set_shader_parameter("amplitude_scale_fade_distance", amplitude_scale_fade_distance)


@export_group("Météo")

## Crêtes des vagues : plus la valeur est grande, plus elles sont pointues ; trop grande, la surface se
## replie sur elle-même.
@export_range(0.0, 10.0) var choppiness := 1.5:
	set(new_choppiness):
		choppiness = new_choppiness

## Direction du vent (degrés) : elle oriente le défilement des textures (wave_scroll_speed).
@export_range(0.0, 360.0) var wind_direction_degrees := 0.0:
	set(new_wind_direction_degrees):
		wind_direction_degrees = clamp(new_wind_direction_degrees, 0.0, 360.0)
		wind_direction = deg_to_rad(new_wind_direction_degrees)
	get:
		return rad_to_deg(wind_direction)

## Vitesse de défilement horizontal des textures de déplacement au fil du temps.
@export_range(-10.0, 10.0) var wave_scroll_speed := 0.0

## Vitesse du vent donnée au spectre des vagues : la longueur de wave_vector.
@export_range(0.0, 1000.0) var wind_speed := 300.0:
	set(new_wave_length):
		wave_vector = wave_vector.normalized() * new_wave_length
	get:
		return wave_vector.length()


## Vrai une fois la simulation initialisée (initialize_simulation()).
var initialized := false

## Décalage UV accumulé par le vent, pour le défilement des vagues ; mis à jour à chaque
## simulate().
var wind_uv_offset := Vector2.ZERO

## Direction du vent (radians).
var wind_direction := 0.0

## Vent donné au spectre initial (initial_spectrum.glsl) : sa longueur est la vitesse du vent.
var wave_vector := Vector2(300.0, 0.0):
	set(new_wave_vector):
		wave_vector = new_wave_vector
		_is_initial_spectrum_changed = true


var _uv_scale := 0.00390625

var _rd:RenderingDevice = RenderingServer.get_rendering_device()

var _fmt_r32f := RDTextureFormat.new()
var _fmt_rg32f := RDTextureFormat.new()
var _fmt_rgba32f := RDTextureFormat.new()

var _initial_spectrum_shader:RID
var _initial_spectrum_pipeline:RID
var _is_initial_spectrum_changed := true
var _initial_spectrum_settings_buffer_cascade:Array[RID] = []
var _initial_spectrum_settings_uniform_cascade:Array[RDUniform] = []
var _initial_spectrum_uniform_cascade:Array[RDUniform] = []
var _initial_spectrum_tex_cascade:Array[RID] = []

var _phase_shader:RID
var _phase_pipeline:RID
var _phase_settings_buffer:RID
var _phase_settings_uniform := RDUniform.new()
var _ping_uniform_cascade:Array[RDUniform] = []
var _pong_uniform_cascade:Array[RDUniform] = []
var _ping_image_cascade:Array[Image] = []
var _ping_tex_cascade:Array[RID] = []
var _pong_tex_cascade:Array[RID] = []

var _spectrum_shader:RID
var _spectrum_pipeline:RID
var _spectrum_settings_buffer:RID
var _spectrum_settings_uniform := RDUniform.new()
var _spectrum_uniform_cascade:Array[RDUniform] = []
var _spectrum_tex_cascade:Array[RID] = []

var _fft_horizontal_shader:RID
var _fft_horizontal_pipeline:RID
var _fft_vertical_shader:RID
var _fft_vertical_pipeline:RID
var _fft_settings_buffer:RID
var _fft_settings_uniform := RDUniform.new()
var _sub_pong_uniform := RDUniform.new()
var _sub_pong_tex:RID

var _waves_readback_ready:Array[bool] = []
var _waves_image_cascade:Array[Image] = []
var _waves_texture_cascade:Array[Texture2DRD] = []

var _is_ping_phase := true

var _frameskip := 0
var _heightmap_sync_frameskip := 0
var _accumulated_delta := 0.0


var _rng := RandomNumberGenerator.new()


## Prépare la simulation (sur le fil de rendu) ; `initialized` passe à vrai si une carte graphique de calcul existe.
## Le hasard de départ vient de `random_seed` : la même graine redonne la même mer, image par image.
func initialize_simulation() -> void:
	_rng.seed = random_seed
	RenderingServer.call_on_render_thread(_initialize_simulation)


## Une itération de la simulation, en respectant simulation_enabled et simulation_frameskip ; `delta`
## s'accumule pendant les images sautées.
func simulate(delta:float) -> void:
	assert(initialized, "OceanFFTWaves not initialized")
	
	if simulation_enabled:
		_accumulated_delta += delta
		
		wind_uv_offset += Vector2(cos(wind_direction), sin(wind_direction)) * wave_scroll_speed * delta
		material.set_shader_parameter("wind_uv_offset", wind_uv_offset)
		
		if simulation_frameskip > 0:
			_frameskip += 1
			if _frameskip <= simulation_frameskip:
				return
			else:
				_frameskip = 0
		
		var sync_heightmap := heightmap_sync_frameskip != -1
		if heightmap_sync_frameskip > 0:
			_heightmap_sync_frameskip += 1
			if _heightmap_sync_frameskip <= heightmap_sync_frameskip:
				sync_heightmap = false
			else:
				sync_heightmap = true
				_heightmap_sync_frameskip = 0
		
		RenderingServer.call_on_render_thread(_simulate.bind(_accumulated_delta, sync_heightmap))
		_accumulated_delta = 0.0


## Une itération de la simulation, sans tenir compte de simulation_enabled ni de
## simulation_frameskip.
func force_simulate(delta:float, sync_heightmap:bool = false) -> void:
	RenderingServer.call_on_render_thread(_simulate.bind(delta, sync_heightmap))


## Pixel de la texture de déplacement de la cascade `cascade` qui correspond à la position `global_pos` du
## plan horizontal XZ (y est ignoré).
func global_to_pixel(_camera:Camera3D, global_pos:Vector3, cascade:int) -> Vector2i:
	## L'ordre des opérations suit celui du vertex shader, qui tourne et met à l'échelle la carte de
	## déplacement avant de l'appliquer : tout changement ici doit être reporté dans le shader, et
	## inversement.
	
	assert(initialized, "OceanFFTWaves not initialized")
	
	## Coordonnée UV : le shader prend les coordonnées XZ du monde comme UV
	var uv_pos := Vector2.ZERO
	uv_pos.x = global_pos.x
	uv_pos.y = global_pos.z
	
	
	## Échelle UV
	uv_pos *= _uv_scale
	uv_pos *= 1.0 / cascade_scales[cascade]
	
	## Décalage du défilement par le vent
	uv_pos += wind_uv_offset * cascade_scales[cascade]
	
	## Ramené entre 0 et 1
	uv_pos.x -= floorf(uv_pos.x)
	uv_pos.y -= floorf(uv_pos.y)
	
	## Coordonnée en pixels
	var pixel_pos := Vector2i.ZERO
	pixel_pos.x = floor((fft_resolution - 1) * uv_pos.x)
	pixel_pos.y = floor((fft_resolution - 1) * uv_pos.y)
	
	return pixel_pos


## Hauteur de la houle à la verticale de `global_pos` (plan XZ, y ignoré), position relative au parent de
## l'océan. Chaque pixel code un déplacement vertical et un déplacement horizontal : on retire le
## déplacement horizontal lu, puis on relit, `steps` fois, pour retrouver le point qui arrive à la
## verticale de `global_pos`. On additionne les `max_cascade` premières cascades. Comme le shader, on
## atténue l'amplitude avec la distance à la caméra et on retire la courbure de la planète.
func get_wave_height(camera:Camera3D, global_pos:Vector3, max_cascade:int = 1, steps:int = 2) -> float:
	assert(initialized, "OceanFFTWaves not initialized")
	
	var pixel:Color
	var xz_offset := Vector3.ZERO
	var total_height := 0.0
	var linear_dist := (global_pos - camera.global_position).length()
	
	## Déplacements des vagues
	for cascade in range(max_cascade):
		for i in range(steps):
			var pixel_pos := global_to_pixel(camera, global_pos - xz_offset, cascade)
			
			pixel = _waves_image_cascade[cascade].get_pixelv(pixel_pos)
			xz_offset.x += pixel.r
			xz_offset.z += pixel.b
		
		total_height += pixel.g
		xz_offset = Vector3.ZERO
	
	## Atténuation de l'amplitude avec la distance
	var amplitude_fade_range:float = clamp(linear_dist, 0.0, amplitude_scale_fade_distance) / amplitude_scale_fade_distance
	total_height *= lerp(amplitude_scale_max, amplitude_scale_min, amplitude_fade_range)
	
	## Courbure de la planète
	var curvation:float = planetary_curve_strength * (pow(global_pos.x - camera.global_position.x, 2.0) + pow(global_pos.y - camera.global_position.z, 2.0))
	total_height -= curvation;
	
	return total_height


## Carte de déplacement d'une cascade, en Image : celle déjà rapatriée sur le processeur. Elle n'appelle
## pas _simulate() et ne lit rien de plus sur la carte graphique.
func get_waves(cascade:int = 0) -> Image:
	assert(initialized, "OceanFFTWaves not initialized")
	return _waves_image_cascade[cascade]


## Carte de déplacement d'une cascade, en Texture2DRD (la mémoire de la carte graphique).
func get_waves_texture(cascade:int = 0) -> Texture2DRD:
	assert(initialized, "OceanFFTWaves not initialized")
	return _waves_texture_cascade[cascade]


## Cartes de déplacement de toutes les cascades, en Images : celles déjà rapatriées sur le processeur.
func get_all_waves() -> Array[Image]:
	assert(initialized, "OceanFFTWaves not initialized")
	return _waves_image_cascade


## Cartes de déplacement de toutes les cascades, en Texture2DRD.
func get_all_waves_textures() -> Array[Texture2DRD]:
	assert(initialized, "OceanFFTWaves not initialized")
	return _waves_texture_cascade


func _pack_initial_spectrum_settings(cascade:int) -> PackedByteArray:
	var settings_bytes: PackedByteArray = PackedInt32Array([fft_resolution, horizontal_dimension * cascade_scales[cascade]]).to_byte_array()
	settings_bytes.append_array(PackedFloat32Array([cascade_ranges[cascade].x, cascade_ranges[cascade].y, wave_vector.x, wave_vector.y]).to_byte_array())
	return settings_bytes


func _pack_phase_settings(delta_time:float, cascade:int) -> PackedByteArray:
	var settings_bytes: PackedByteArray = PackedInt32Array([fft_resolution, horizontal_dimension * cascade_scales[cascade]]).to_byte_array()
	settings_bytes.append_array(PackedFloat32Array([delta_time]).to_byte_array())
	return settings_bytes


func _pack_spectrum_settings(cascade:int) -> PackedByteArray:
	var settings_bytes: PackedByteArray = PackedInt32Array([horizontal_dimension * cascade_scales[cascade]]).to_byte_array()
	settings_bytes.append_array(PackedFloat32Array([choppiness, fft_resolution]).to_byte_array())
	return settings_bytes


func _pack_fft_settings(subseq_count:int) -> PackedByteArray:
	return PackedInt32Array([fft_resolution, subseq_count]).to_byte_array()


#### Code du fil de rendu
################################################################################
## Tout ce qui suit tourne sur le fil de rendu principal, par
## RenderingServer.call_on_render_thread().


## Prépare la simulation : compile les shaders, crée les textures et les tampons de réglages.
## À appeler par RenderingServer.call_on_render_thread().
func _initialize_simulation() -> void:
	if not _rd:
		return
	var shader_file:Resource
	var settings_bytes:PackedByteArray
	var initial_image_rf := Image.create(fft_resolution, fft_resolution, false, Image.FORMAT_RF)
	var initial_image_rgf := Image.create(fft_resolution, fft_resolution, false, Image.FORMAT_RGF)
	
	#### Formats des textures (RDTextureFormat)
	############################################################################
	## Créés une fois, réutilisés ensuite.
	
	_fmt_r32f.width = fft_resolution
	_fmt_r32f.height = fft_resolution
	_fmt_r32f.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	_fmt_r32f.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	_fmt_rg32f.width = fft_resolution
	_fmt_rg32f.height = fft_resolution
	_fmt_rg32f.format = RenderingDevice.DATA_FORMAT_R32G32_SFLOAT
	_fmt_rg32f.usage_bits = _fmt_r32f.usage_bits
	
	_fmt_rgba32f.width = fft_resolution
	_fmt_rgba32f.height = fft_resolution
	_fmt_rgba32f.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	_fmt_rgba32f.usage_bits = _fmt_r32f.usage_bits
	
	#### Shader du spectre initial : compilation et préparation
	############################################################################
	## La texture du spectre initial part vide. Le shader du spectre initial la calcule à partir du
	## vent, de la résolution FFT et de la taille du carré simulé. Elle ne change pas tant que ces
	## réglages ne changent pas : on ne la recalcule pas à chaque image, seulement quand ils
	## changent.
	
	## Compilation du shader
	shader_file = load("res://1_core/water/fft/shaders/initial_spectrum.glsl")
	_initial_spectrum_shader = _rd.shader_create_from_spirv(shader_file.get_spirv())
	_initial_spectrum_pipeline = _rd.compute_pipeline_create(_initial_spectrum_shader)
	
	## Une texture par cascade
	_initial_spectrum_settings_buffer_cascade.resize(cascade_ranges.size())
	_initial_spectrum_settings_uniform_cascade.resize(cascade_ranges.size())
	_initial_spectrum_tex_cascade.resize(cascade_ranges.size())
	_initial_spectrum_uniform_cascade.resize(cascade_ranges.size())
	
	for i in cascade_ranges.size():
		## Tampon de réglages
		settings_bytes = _pack_initial_spectrum_settings(i)
		_initial_spectrum_settings_buffer_cascade[i] = _rd.storage_buffer_create(settings_bytes.size(), settings_bytes)
		_initial_spectrum_settings_uniform_cascade[i] = RDUniform.new()
		_initial_spectrum_settings_uniform_cascade[i].uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
		_initial_spectrum_settings_uniform_cascade[i].binding = Binding.SETTINGS
		_initial_spectrum_settings_uniform_cascade[i].add_id(_initial_spectrum_settings_buffer_cascade[i])
	
		## Vide : calculée à la première image
		_initial_spectrum_tex_cascade[i] = _rd.texture_create(_fmt_r32f, RDTextureView.new(), [initial_image_rf.get_data()])
		_initial_spectrum_uniform_cascade[i] = RDUniform.new()
		_initial_spectrum_uniform_cascade[i].uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		_initial_spectrum_uniform_cascade[i].binding = Binding.INITIAL_SPECTRUM
		_initial_spectrum_uniform_cascade[i].add_id(_initial_spectrum_tex_cascade[i])
	
	#### Shader de phase : compilation et préparation
	############################################################################
	## Fait avancer dans le temps un spectre de hasard préparé à l'avance.
	
	## Compilation du shader
	shader_file = load("res://1_core/water/fft/shaders/phase.glsl")
	_phase_shader = _rd.shader_create_from_spirv(shader_file.get_spirv())
	_phase_pipeline = _rd.compute_pipeline_create(_phase_shader)
	
	## Tableaux par cascade
	_ping_uniform_cascade.resize(cascade_ranges.size())
	_pong_uniform_cascade.resize(cascade_ranges.size())
	_ping_image_cascade.resize(cascade_ranges.size())
	_ping_tex_cascade.resize(cascade_ranges.size())
	_pong_tex_cascade.resize(cascade_ranges.size())
	
	## Tampon de réglages
	settings_bytes = _pack_phase_settings(0.0, 0)
	_phase_settings_buffer = _rd.storage_buffer_create(settings_bytes.size(), settings_bytes)
	_phase_settings_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	_phase_settings_uniform.binding = Binding.SETTINGS
	_phase_settings_uniform.add_id(_phase_settings_buffer)
	
	#### Textures de ping-pong
	############################################################################
	## Elles servent d'entrée et de sortie au shader de phase.
	##
	## C'est un double tampon : l'exécution étant asynchrone, le shader ne peut pas lire et écrire
	## sans risque la même texture dans le même passage.
	##
	## Aux images paires (phase « ping »), on lit Ping et on écrit dans Pong.
	## Aux images impaires (phase « pong »), c'est l'inverse : on lit Pong et on écrit dans
	## Ping.
	##
	## Au démarrage, Ping reçoit le hasard préparé.
	
	var ping_data:PackedFloat32Array = []
	
	## Ping doit partir de ce hasard préparé
	for i in range(fft_resolution * fft_resolution):
		if ping_data.append(_rng.randf_range(0.0, 1.0) * 2.0 * PI):
			print("error generating initial ping data")
	
	for cascade in cascade_ranges.size():
		_ping_image_cascade[cascade] = Image.create_from_data(fft_resolution, fft_resolution, false, Image.FORMAT_RF, ping_data.to_byte_array())
		_ping_tex_cascade[cascade] = _rd.texture_create(_fmt_r32f, RDTextureView.new(), [_ping_image_cascade[cascade].get_data()])
		_ping_uniform_cascade[cascade] = RDUniform.new()
		_ping_uniform_cascade[cascade].uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		_ping_uniform_cascade[cascade].binding = Binding.PING
		_ping_uniform_cascade[cascade].add_id(_ping_tex_cascade[cascade])
		
		## Pong part vide : la première exécution du shader de phase le calcule à partir de
		## Ping
		_pong_tex_cascade[cascade] = _rd.texture_create(_fmt_r32f, RDTextureView.new(), [initial_image_rf.get_data()])
		_pong_uniform_cascade[cascade] = RDUniform.new()
		_pong_uniform_cascade[cascade].uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		_pong_uniform_cascade[cascade].binding = Binding.PONG
		_pong_uniform_cascade[cascade].add_id(_pong_tex_cascade[cascade])
	
	#### Shader du spectre : compilation et préparation
	############################################################################
	## Combine les réglages de météo du spectre initial avec le hasard qui évolue dans le temps,
	## calculé par la phase (et rangé dans les textures Ping et Pong)
	
	## Compilation du shader
	shader_file = load("res://1_core/water/fft/shaders/spectrum.glsl")
	_spectrum_shader = _rd.shader_create_from_spirv(shader_file.get_spirv())
	_spectrum_pipeline = _rd.compute_pipeline_create(_spectrum_shader)
	
	## Tampon de réglages
	settings_bytes = _pack_spectrum_settings(0)
	_spectrum_settings_buffer = _rd.storage_buffer_create(settings_bytes.size(), settings_bytes)
	_spectrum_settings_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	_spectrum_settings_uniform.binding = Binding.SETTINGS
	_spectrum_settings_uniform.add_id(_spectrum_settings_buffer)
	
	_spectrum_tex_cascade.resize(cascade_ranges.size())
	_spectrum_uniform_cascade.resize(cascade_ranges.size())
	_waves_readback_ready.resize(cascade_ranges.size())
	_waves_image_cascade.resize(cascade_ranges.size())
	_waves_texture_cascade.resize(cascade_ranges.size())
	
	for i in cascade_ranges.size():
		## Vide : calculée à chaque image
		_spectrum_tex_cascade[i] = _rd.texture_create(_fmt_rg32f, RDTextureView.new(), [initial_image_rgf.get_data()])
		_spectrum_uniform_cascade[i] = RDUniform.new()
		_spectrum_uniform_cascade[i].uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		_spectrum_uniform_cascade[i].binding = Binding.SPECTRUM
		_spectrum_uniform_cascade[i].add_id(_spectrum_tex_cascade[i])
		
		## La texture de déplacement de la cascade est donnée au shader de la surface
		_waves_readback_ready[i] = true
		_waves_image_cascade[i] = Image.create(fft_resolution, fft_resolution, false, Image.FORMAT_RGF)
		_waves_texture_cascade[i] = Texture2DRD.new()
		_waves_texture_cascade[i].texture_rd_rid = _spectrum_tex_cascade[i]
	
	material.set_shader_parameter("cascade_displacements", _waves_texture_cascade)
	material.set_shader_parameter("cascade_uv_scales", cascade_scales)
	material.set_shader_parameter("uv_scale", _uv_scale)
	
	#### Shaders FFT : compilation et préparation
	############################################################################
	## Transforment le résultat du shader de spectre en carte de déplacement.
	##
	## La texture du spectre et la texture SubPong servent de ping-pong. La carte de déplacement
	## finale reste dans la texture du spectre.
	
	## Compilation des shaders
	shader_file = load("res://1_core/water/fft/shaders/fft_horizontal.glsl")
	_fft_horizontal_shader = _rd.shader_create_from_spirv(shader_file.get_spirv())
	_fft_horizontal_pipeline = _rd.compute_pipeline_create(_fft_horizontal_shader)
	
	shader_file = load("res://1_core/water/fft/shaders/fft_vertical.glsl")
	_fft_vertical_shader = _rd.shader_create_from_spirv(shader_file.get_spirv())
	_fft_vertical_pipeline = _rd.compute_pipeline_create(_fft_vertical_shader)
	
	## Tampon de réglages
	settings_bytes = _pack_fft_settings(0)
	_fft_settings_buffer = _rd.storage_buffer_create(settings_bytes.size(), settings_bytes)
	_fft_settings_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	_fft_settings_uniform.binding = Binding.SETTINGS
	_fft_settings_uniform.add_id(_fft_settings_buffer)
	
	## Vide : calculée à partir du spectre
	_sub_pong_tex = _rd.texture_create(_fmt_rg32f, RDTextureView.new(), [initial_image_rgf.get_data()])
	_sub_pong_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	_sub_pong_uniform.add_id(_sub_pong_tex)
	
	initialized = true


## Une itération de la simulation. La carte de déplacement obtenue se lit avec get_waves_texture() (la
## mémoire même où travaillent les shaders de calcul), ou en Image avec get_waves() : l'Image, en
## mémoire du processeur, n'est mise à jour que si `sync_heightmap` est vrai.
## À appeler par RenderingServer.call_on_render_thread().
func _simulate(delta:float, sync_heightmap:bool) -> void:
	if not _rd or not initialized:
		return
	var uniform_set:RID
	var compute_list:int
	var settings_bytes:PackedByteArray
	
	#### Pour chaque cascade
	############################################################################
	for cascade in cascade_ranges.size():
		
		#### Spectre initial
		########################################################################
		## Calculé à la première image, ou quand le vent, la résolution FFT ou la taille du carré
		## changent : pour les mêmes réglages, il ne change pas. Il reste dans la mémoire de la carte
		## graphique, sans retour vers le processeur.
	
		if _is_initial_spectrum_changed:
			## Tampon de réglages
			settings_bytes = _pack_initial_spectrum_settings(cascade)
			if _rd.buffer_update(_initial_spectrum_settings_buffer_cascade[cascade], 0, settings_bytes.size(), settings_bytes) != OK:
				print("error updating initial spectrum settings buffer")
			
			## Jeu d'uniformes
			uniform_set = _rd.uniform_set_create([
					_initial_spectrum_settings_uniform_cascade[cascade],
					_initial_spectrum_uniform_cascade[cascade]], _initial_spectrum_shader, UNIFORM_SET)
			
			## Liste de calcul
			compute_list = _rd.compute_list_begin()
			_rd.compute_list_bind_compute_pipeline(compute_list, _initial_spectrum_pipeline)
			_rd.compute_list_bind_uniform_set(compute_list, uniform_set, UNIFORM_SET)
			@warning_ignore("integer_division")
			_rd.compute_list_dispatch(compute_list, fft_resolution / WORK_GROUP_DIM, fft_resolution / WORK_GROUP_DIM, 1)
			_rd.compute_list_end()
			
			_rd.free_rid(uniform_set)
		
		## Plus de recalcul tant que le vent, la résolution FFT ou la taille du carré ne changent pas ; la
		## condition laisse passer toutes les cascades.
		if cascade == cascade_ranges.size() - 1:
			_is_initial_spectrum_changed = false
	
		#### Shader de phase : met à jour les textures de ping-pong
		########################################################################
		
		## Les textures restent en place dans la mémoire de la carte graphique : on échange seulement les
		## points d'attache.
		if _is_ping_phase:
			_ping_uniform_cascade[cascade].binding = Binding.PING
			_pong_uniform_cascade[cascade].binding = Binding.PONG
		
		else:
			_ping_uniform_cascade[cascade].binding = Binding.PONG
			_pong_uniform_cascade[cascade].binding = Binding.PING
		
		## Tampon de réglages
		settings_bytes = _pack_phase_settings(delta * time_scale, cascade)
		if _rd.buffer_update(_phase_settings_buffer, 0, settings_bytes.size(), settings_bytes) != OK:
			print("error updating phase settings buffer")
		
		## Jeu d'uniformes
		uniform_set = _rd.uniform_set_create([
				_phase_settings_uniform,
				_ping_uniform_cascade[cascade],
				_pong_uniform_cascade[cascade]], _phase_shader, UNIFORM_SET)
		
		## Liste de calcul
		compute_list = _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(compute_list, _phase_pipeline)
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set, UNIFORM_SET)
		@warning_ignore("integer_division")
		_rd.compute_list_dispatch(compute_list, fft_resolution / WORK_GROUP_DIM, fft_resolution / WORK_GROUP_DIM, 1)
		_rd.compute_list_end()
		
		_rd.free_rid(uniform_set)
	
		#### Shader du spectre, pour chaque cascade
		########################################################################
		
		## Tampon de réglages
		settings_bytes = _pack_spectrum_settings(cascade)
		if _rd.buffer_update(_spectrum_settings_buffer, 0, settings_bytes.size(), settings_bytes) != OK:
			print("error updating spectrum settings buffer")
		
		## Remet le point d'attache de la texture du spectre, que la suite de _simulate() change à
		## chaque image.
		_spectrum_uniform_cascade[cascade].binding = Binding.SPECTRUM
		
		## Jeu d'uniformes
		uniform_set = _rd.uniform_set_create([
				_spectrum_settings_uniform,
				_initial_spectrum_uniform_cascade[cascade],
				_spectrum_uniform_cascade[cascade],
				_ping_uniform_cascade[cascade],
				_pong_uniform_cascade[cascade]], _spectrum_shader, UNIFORM_SET)
		
		## Liste de calcul
		compute_list = _rd.compute_list_begin()
		_rd.compute_list_bind_compute_pipeline(compute_list, _spectrum_pipeline)
		_rd.compute_list_bind_uniform_set(compute_list, uniform_set, UNIFORM_SET)
		@warning_ignore("integer_division")
		_rd.compute_list_dispatch(compute_list, fft_resolution / WORK_GROUP_DIM, fft_resolution / WORK_GROUP_DIM, 1)
		_rd.compute_list_end()
		
		_rd.free_rid(uniform_set)
	
		#### FFT horizontale, pour chaque cascade
		########################################################################
		
		var is_sub_ping_phase := true
		var p := 1
		while p < fft_resolution:
			## Les textures restent en place dans la mémoire de la carte graphique : on échange seulement
			## les points d'attache.
			if is_sub_ping_phase:
				_spectrum_uniform_cascade[cascade].binding = Binding.INPUT
				_sub_pong_uniform.binding = Binding.OUTPUT
			
			else:
				_spectrum_uniform_cascade[cascade].binding = Binding.OUTPUT
				_sub_pong_uniform.binding = Binding.INPUT
			
			## Tampon de réglages
			settings_bytes = _pack_fft_settings(p)
			if _rd.buffer_update(_fft_settings_buffer, 0, settings_bytes.size(), settings_bytes) != OK:
				print("error updating horizontal FFT settings buffer")
			
			## Jeu d'uniformes
			uniform_set = _rd.uniform_set_create([
					_fft_settings_uniform,
					_sub_pong_uniform,
					_spectrum_uniform_cascade[cascade]], _fft_horizontal_shader, UNIFORM_SET)
			
			## Liste de calcul
			compute_list = _rd.compute_list_begin()
			_rd.compute_list_bind_compute_pipeline(compute_list, _fft_horizontal_pipeline)
			_rd.compute_list_bind_uniform_set(compute_list, uniform_set, UNIFORM_SET)
			_rd.compute_list_dispatch(compute_list, fft_resolution, 1, 1)
			_rd.compute_list_end()
			
			_rd.free_rid(uniform_set)
			
			p <<= 1
			is_sub_ping_phase = not is_sub_ping_phase
		
		#### FFT verticale, pour chaque cascade
		########################################################################
		
		p = 1
		while p < fft_resolution:
			## Les textures restent en place dans la mémoire de la carte graphique : on échange seulement
			## les points d'attache.
			if is_sub_ping_phase:
				_spectrum_uniform_cascade[cascade].binding = Binding.INPUT
				_sub_pong_uniform.binding = Binding.OUTPUT
			
			else:
				_spectrum_uniform_cascade[cascade].binding = Binding.OUTPUT
				_sub_pong_uniform.binding = Binding.INPUT
			
			## Tampon de réglages
			settings_bytes = _pack_fft_settings(p)
			if _rd.buffer_update(_fft_settings_buffer, 0, settings_bytes.size(), settings_bytes) != OK:
				print("error updating vertical FFT settings buffer")
			
			## Jeu d'uniformes
			uniform_set = _rd.uniform_set_create([
					_fft_settings_uniform,
					_sub_pong_uniform,
					_spectrum_uniform_cascade[cascade]], _fft_vertical_shader, UNIFORM_SET)
			
			## Liste de calcul
			compute_list = _rd.compute_list_begin()
			_rd.compute_list_bind_compute_pipeline(compute_list, _fft_vertical_pipeline)
			_rd.compute_list_bind_uniform_set(compute_list, uniform_set, UNIFORM_SET)
			_rd.compute_list_dispatch(compute_list, fft_resolution, 1, 1)
			_rd.compute_list_end()
			
			_rd.free_rid(uniform_set)
			
			p <<= 1
			is_sub_ping_phase = not is_sub_ping_phase
		
		
		## Rapatrie la carte de déplacement de la texture du spectre vers le processeur : la flottaison et
		## les vagues d'impact la lisent.
		if sync_heightmap: # && _waves_readback_ready[cascade]:
			var lambda: Callable = func (array : PackedByteArray) -> void:
				_waves_image_cascade[cascade].set_data(fft_resolution, fft_resolution, false, Image.FORMAT_RGF, array)
				_waves_readback_ready[cascade] = true
				
			_rd.texture_get_data_async(_spectrum_tex_cascade[cascade], 0, lambda)
			
	
	## Une fois par simulation, hors de la boucle des cascades
	_is_ping_phase = not _is_ping_phase
