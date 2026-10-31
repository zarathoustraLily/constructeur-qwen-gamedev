class_name GraphicsQualityApplier extends Node
## Choisit le niveau de qualité graphique et l'applique au niveau, à son entrée dans l'arbre (après le décor et la
## brume). Le choix : `--qualite=haute` ou `--qualite=basse` après `--` sur la ligne de commande ; sinon celui que le
## joueur a enregistré (user://reglages.cfg, section « graphismes », clé « qualite ») ; sinon d'après la carte
## graphique : intégrée, logicielle ou virtuelle, la basse ; sinon la haute. Appliquer, c'est régler l'environnement (une
## copie : la ressource partagée reste intacte), la fenêtre (échelle 3D, atlas d'ombres), les lumières du décor (qui
## fait des ombres, quelle portée) et la brume (volumétrique ou de repli).
#@ 19+
#@ 19
## Il dit aussi aux effets brefs (VfxBurst) s'ils ont droit à leur lumière.
#@ 20+
## Il dit aussi aux effets (leur groupe) s'ils ont droit à leur lumière.
#@ 21+
## Il règle enfin ce qui se dessine : le seuil des niveaux de détail, la portée et les ombres des petits objets du décor,
## l'ombre de la lune.
#@ all

## Le fichier des réglages du joueur.
const SETTINGS_FILE: String = "user://reglages.cfg"
#@ 21+
## La marge de la portée des petits objets, en mètres : ils ne clignotent pas à la limite.
const DETAIL_MARGIN: float = 2.0
#@ all

## La qualité haute.
@export var high: GraphicsQuality
## La qualité basse (petit PC).
@export var low: GraphicsQuality
## L'environnement du niveau.
@export var world: WorldEnvironment
## Le décor dont les lumières sont réglées (la lune n'en fait pas partie).
@export var lights_root: Node
## Le lieu du combat : les lumières les plus proches gardent leurs ombres.
@export var focus: Node3D
## La brume volumétrique.
@export var mist: FogVolume
## La brume de repli, sans brouillard volumétrique.
@export var mist_fallback: Node3D
#@ 21+
## La lune, dont l'ombre est réglée.
@export var moon: DirectionalLight3D
#@ all

## Le niveau appliqué.
var current: GraphicsQuality
## Les lumières du décor, de la plus proche du lieu du combat à la plus lointaine.
var lights: Array[Light3D] = []

var _shadows: Array[bool] = []
var _ranges: Array[float] = []
var _omni_modes: Array[OmniLight3D.ShadowMode] = []
var _environment: Environment
#@ 21+
var _decor: Array[MeshInstance3D] = []
var _sizes: PackedFloat32Array = PackedFloat32Array()
var _casts: Array[GeometryInstance3D.ShadowCastingSetting] = []
#@ all


func _ready() -> void:
	_collect_lights()
#@ 21+
	_collect_decor()
#@ all
	_environment = world.environment
	apply(choose(OS.get_cmdline_user_args(), _saved(), RenderingServer.get_video_adapter_type()), get_viewport())


## Le niveau voulu : l'argument `--qualite=…` d'abord, puis le choix enregistré `saved`, puis la carte graphique
## (`adapter`, un RenderingDevice.DeviceType).
func choose(args: PackedStringArray, saved: String, adapter: int) -> GraphicsQuality:
	for arg: String in args:
		if arg.begins_with("--qualite="):
			return _by_name(arg.trim_prefix("--qualite="), high)
	if saved != "":
		return _by_name(saved, high)
	var small: bool = adapter in [RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, RenderingDevice.DEVICE_TYPE_CPU,
			RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU]
	return low if small else high


## Applique `quality` au niveau ; `viewport` : la fenêtre dont l'échelle 3D et l'atlas d'ombres sont réglés.
func apply(quality: GraphicsQuality, viewport: Viewport) -> void:
	current = quality
	var environment: Environment = _environment.duplicate() as Environment
	environment.sdfgi_enabled = quality.sdfgi and _environment.sdfgi_enabled
	environment.ssil_enabled = quality.ssil and _environment.ssil_enabled
	environment.ssao_enabled = quality.ssao and _environment.ssao_enabled
	environment.glow_enabled = quality.glow and _environment.glow_enabled
	environment.volumetric_fog_enabled = quality.volumetric_fog and _environment.volumetric_fog_enabled
	environment.ambient_light_energy = _environment.ambient_light_energy * quality.ambient_scale
	world.environment = environment
	viewport.scaling_3d_scale = quality.scale_3d
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if quality.fsr else Viewport.SCALING_3D_MODE_BILINEAR
	viewport.positional_shadow_atlas_size = quality.shadow_atlas
#@ 21+
	viewport.mesh_lod_threshold = quality.lod_threshold
	moon.directional_shadow_mode = quality.moon_shadow_mode
	for i: int in _decor.size():
		var piece: MeshInstance3D = _decor[i]
		var reach: float = quality.detail_range if _sizes[i] <= quality.detail_size else 0.0
		piece.visibility_range_end = reach
		piece.visibility_range_end_margin = DETAIL_MARGIN if reach > 0.0 else 0.0
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if _sizes[i] < quality.shadow_min_size else _casts[i]
#@ all
	RenderingServer.directional_shadow_atlas_set_size(quality.directional_shadow, true)
	# Le moteur Compatibilité (OpenGL) n'a pas les ombres en demi-sphères : il garde les cubes.
	var cheap_omni: bool = quality.cheap_omni_shadows and RenderingServer.get_current_rendering_method() != "gl_compatibility"
	for i: int in lights.size():
		var light: Light3D = lights[i]
		light.shadow_enabled = _shadows[i] and i < quality.shadow_lights
		var reach: float = minf(_ranges[i], quality.light_range_max) if quality.light_range_max > 0.0 else _ranges[i]
		if light is OmniLight3D:
			var omni: OmniLight3D = light as OmniLight3D
			omni.omni_range = reach
			omni.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID if cheap_omni else _omni_modes[i]
		elif light is SpotLight3D:
			(light as SpotLight3D).spot_range = reach
	mist.visible = quality.volumetric_fog
	mist_fallback.visible = not quality.volumetric_fog
#@ 19+
#@ 19
	for burst: Node in get_tree().get_nodes_in_group(VfxBurst.GROUP):
		(burst as VfxBurst).light_allowed = quality.effect_lights
#@ 20+
	get_tree().set_group(VfxBurst.GROUP, &"light_allowed", quality.effect_lights)
#@ all


## Le nombre de passes d'ombre qu'une image peut demander avec ce réglage : six par lumière omnidirectionnelle en cube,
## deux en demi-sphères, une par projecteur (les ombres de la lune ne sont pas comptées).
func shadow_passes() -> int:
	var passes: int = 0
	for light: Light3D in lights:
		if not light.shadow_enabled:
			continue
		if light is OmniLight3D:
			passes += 6 if (light as OmniLight3D).omni_shadow_mode == OmniLight3D.SHADOW_CUBE else 2
		else:
			passes += 1
	return passes


func _collect_lights() -> void:
	for node: Node in lights_root.find_children("*", "Light3D", true, false):
		if node is OmniLight3D or node is SpotLight3D:
			lights.append(node as Light3D)
	var center: Vector3 = focus.global_position
	lights.sort_custom(func(a: Light3D, b: Light3D) -> bool:
		return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center))
	for light: Light3D in lights:
		_shadows.append(light.shadow_enabled)
		_ranges.append((light as OmniLight3D).omni_range if light is OmniLight3D else (light as SpotLight3D).spot_range)
		_omni_modes.append((light as OmniLight3D).omni_shadow_mode if light is OmniLight3D else OmniLight3D.SHADOW_CUBE)


#@ 21+
func _collect_decor() -> void:
	for node: Node in lights_root.find_children("*", "MeshInstance3D", true, false):
		var piece: MeshInstance3D = node as MeshInstance3D
		var size: Vector3 = (piece.global_transform * piece.get_aabb()).size
		_decor.append(piece)
		_sizes.append(maxf(size.x, maxf(size.y, size.z)))
		_casts.append(piece.cast_shadow)


#@ all
func _saved() -> String:
	var file: ConfigFile = ConfigFile.new()
	if file.load(SETTINGS_FILE) != OK:
		return ""
	return String(file.get_value("graphismes", "qualite", ""))


func _by_name(level: String, fallback: GraphicsQuality) -> GraphicsQuality:
	if level == String(low.id):
		return low
	if level == String(high.id):
		return high
	return fallback
