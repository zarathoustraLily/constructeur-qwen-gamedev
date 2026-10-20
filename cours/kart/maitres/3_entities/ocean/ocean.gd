class_name Ocean extends WaterSurface
#@ 8
## Océan du jeu : la houle FFT (`ocean`, OceanFFTWaves), calculée sur la carte graphique. Il respecte le
## contrat WaterSurface : la hauteur de l'eau est celle de la houle, multipliée par le masque de l'île (pas de
## houle sur l'île, ni sur les plages).
#@ 9+
## Océan du jeu : houle FFT (`ocean`, OceanFFTWaves), ondulations (WaterRipples), vagues d'impact (WaterWaves) et
## écume (WaterFoam), toutes centrées sur le joueur. Il respecte le contrat WaterSurface : la hauteur de l'eau
## additionne houle et vagues, multipliées par le masque de l'île.
#@ all
## Sans RenderingDevice (rendu de compatibilité, ou sans fenêtre), la houle ne démarre jamais : l'eau reste
## plate, à hauteur 0, comme la surface de base, et la mer calme (CalmSea) remplace la surface de l'océan.
#@ 9+

@onready var water_ripples: WaterWaves = $WaterRipples
@onready var water_waves: WaterWaves = $WaterWaves
@onready var water_foam: WaterFoam = $WaterFoam
#@ all

## Masque de l'île : son canal rouge multiplie la hauteur de l'eau (0 sur l'île, 1 au large).
@export var island_mask: Texture2D
## Côtés (m) du carré que couvre le masque, centré sur l'origine (donnés par la scène de l'océan).
@export var island_mask_size: Vector2 = Vector2.ZERO
## Simulation de houle FFT.
@export var ocean: OceanFFTWaves

## Image du masque, décompressée au démarrage.
var island_mask_image: Image
#@ 9+
## Dernière position du joueur reçue.
var player_position: Vector3
#@ all


func _ready() -> void:
	if ocean != null and not ocean.initialized:
		ocean.initialize_simulation()
	island_mask_image = island_mask.get_image()
	if island_mask_image.is_compressed():
		island_mask_image.decompress()
	island_mask_image.convert(Image.FORMAT_RGBA8)


# La houle porte ce qui flotte : elle avance avec la physique.
func _physics_process(delta: float) -> void:
	if ocean == null or not ocean.initialized:
		if ocean != null:
			ocean.initialize_simulation()
		return
	ocean.simulate(delta)
#@ 9+
	# Les textures que l'écume lit : ondulations, vagues d'impact, houle.
	water_foam.ripples_size_ratio = water_foam.texture_size / water_ripples.texture_size \
		* Vector2(water_foam.texture_resolution) / Vector2(water_ripples.texture_resolution)
	water_foam.ripples_resolution = water_ripples.texture_resolution
	water_foam.ripples_texture_set = water_ripples.get_current_image_set()
	water_foam.waves_size_ratio = water_foam.texture_size / water_waves.texture_size \
		* Vector2(water_foam.texture_resolution) / Vector2(water_waves.texture_resolution)
	water_foam.waves_resolution = water_waves.texture_resolution
	water_foam.waves_texture_set = water_waves.get_current_image_set()
	water_foam.fft_resolution = Vector2(ocean.fft_resolution, ocean.fft_resolution)
	water_foam.fft_size_ratio = water_foam.texture_size / ocean.horizontal_dimension \
		* Vector2(water_foam.texture_resolution) / Vector2(water_foam.fft_resolution)
	water_foam.fft_wind_uv_offset = ocean.wind_uv_offset
	water_foam.fft_cascade_uv_scaled = ocean.cascade_scales
	water_foam.fft_uv_scale = ocean._uv_scale
	water_foam.create_fft_waves_cascades_set(ocean.get_all_waves_textures())
#@ all


## Valeur du masque de l'île en `pos` (de 0 à 1).
func get_island_mask(pos: Vector3) -> float:
	return ImageSampling.centered(island_mask_image, Vector2(pos.x, pos.z), island_mask_size).r


#@ 8
## Hauteur de l'eau à la verticale de `global_pos` : la houle, multipliée par le masque de l'île ; 0 tant que
## la houle n'est pas prête.
func get_wave_height(global_pos: Vector3, max_cascade: int = DEFAULT_CASCADES,
		steps: int = DEFAULT_STEPS) -> float:
	if ocean == null or not ocean.initialized:
		return 0.0
	var height := ocean.get_wave_height(get_viewport().get_camera_3d(), global_pos, max_cascade, steps)
	return get_island_mask(global_pos) * height
#@ 9+
## Hauteur de l'eau à la verticale de `global_pos` : houle et vagues, multipliées par le masque de l'île ; 0
## tant que la houle n'est pas prête.
func get_wave_height(global_pos: Vector3, max_cascade: int = DEFAULT_CASCADES,
		steps: int = DEFAULT_STEPS) -> float:
	if ocean == null or not ocean.initialized:
		return 0.0
	var height := ocean.get_wave_height(get_viewport().get_camera_3d(), global_pos, max_cascade, steps) \
		+ water_waves.get_height(global_pos)
	return get_island_mask(global_pos) * height


## Recentre ondulations, vagues et écume sur `pos`.
func set_player_position(pos: Vector3) -> void:
	player_position = pos
	water_ripples.texture_offset = pos
	water_waves.texture_offset = pos
	water_foam.texture_offset = pos


## Ajoute une ondulation en `pos`, de hauteur `height` et de rayon `radius_px` (pixels de la simulation).
func add_ripple(pos: Vector3, height: float, radius_px: float) -> void:
	water_ripples.add_ripple(pos, height, radius_px)


## Ajoute une vague d'impact en `pos`, de hauteur `height` et de rayon `radius_px` (pixels de la simulation).
func add_wave(pos: Vector3, height: float, radius_px: float) -> void:
	water_waves.add_ripple(pos, height, radius_px)


## Écume persistante (sillage) en `pos` : quantité de 0 à 1, rayon en mètres.
func add_foam(pos: Vector3, amount: float, radius: float) -> void:
	water_foam.add_foam(pos, amount, radius)
#@ all
