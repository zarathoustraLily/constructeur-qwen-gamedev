extends Node3D
## Visite de l'étape : ciel, soleil, sol, caméra libre, jour et nuit, mesure du temps de rendu.
## Ce qu'on visite, ce sont les nœuds enfants posés dans la scène (l'immeuble ou la rue).
##
## C'est un morceau du déroulé, au sens de l'organisation du projet : elle vit dans
## « 2_sequence ». Elle ne fabrique rien elle-même : elle montre ce que « 6_assets » fournit,
## affiche le bandeau de « 4_ui », se sert de la caméra de « 1_core », et prend ses réglages
## (teintes du ciel, sol, cadrage, qualité) dans « 5_data/visit/visit_settings.tres ».
##
#@ 1-12
## Clavier : N, jour ou nuit ; F, recadrer ; R, résolution du rendu 3D (100, 75, 50 %) ;
## V, synchro verticale ; Échap, quitter. La caméra est décrite dans free_camera_input.gd.
##
#@ 13+
## Clavier : N, jour ou nuit ; F, recadrer ; P, qualité (basse, moyenne, haute) ; R, résolution
## du rendu 3D (100, 75, 50 %) ; V, synchro verticale ; Échap, quitter. La caméra est décrite
## dans free_camera_input.gd.
##
## Qualité : un réglage de la machine, pas de l'immeuble. Il change la finesse des shaders, les
## ombres, l'anticrénelage et la résolution du rendu. Si les images mettent trop longtemps, la
## visite baisse la qualité toute seule, un cran à la fois ; appuyer sur P ou R reprend la main.
##
#@ all
## Ligne de commande, après « -- » :
##   --shot=<fichier.png>                   rend une image, l'enregistre et quitte
##   --bench=120                            mesure le temps de rendu sur 120 images et quitte
##   --scale=0.5                            résolution du rendu 3D, de 0.25 à 1
#@ 13+ quiet
##   --quality=0                            qualité : 0 basse, 1 moyenne, 2 haute
#@ all
##   --night                                commence de nuit
##   --cam=x,y,z  --look=x,y,z  --fov=45    place la caméra
##   --sun=-50,35                           hauteur et azimut du soleil, en degrés
##   --set-<variable>=<valeur>              règle une variable des nœuds visités, par exemple
##                                          --set-bay_count=3 ou --set-stone_color=Color(0.9,0.9,0.8)

const FreeCamera := preload("res://1_core/camera/free_camera.gd")
const FreeCameraInput := preload("res://1_core/camera/free_camera_input.gd")
const StepBanner := preload("res://4_ui/step_banner/step_banner.gd")

#@ 1-12
const HELP_TEXT: String = "N : jour / nuit   F : recadrer   R : résolution   V : synchro   clic droit + ZQSD : caméra   A / E : descendre, monter   Maj : vite   Échap : quitter"
#@ 13+
const HELP_TEXT: String = "N : jour / nuit   F : recadrer   P : qualité   R : résolution   V : synchro   clic droit + ZQSD : caméra   A / E : descendre, monter   Maj : vite   Échap : quitter"

# Ce que chaque qualité règle dans le moteur, de la plus basse à la plus haute. Les valeurs
# chiffrées (portée des ombres, résolution) sont dans les réglages de la visite.
## Découpage de l'ombre du soleil : une seule carte, deux ou quatre. Chaque carte en plus est un
## rendu de plus de tout ce qui porte une ombre.
const QUALITY_SHADOW_MODES: Array[DirectionalLight3D.ShadowMode] = [
	DirectionalLight3D.SHADOW_ORTHOGONAL, DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS,
]
## Adoucissement du bord des ombres.
const QUALITY_SHADOW_FILTERS: Array[RenderingServer.ShadowQuality] = [
	RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_HIGH,
]
## Anticrénelage par suréchantillonnage (MSAA) : coûteux, réservé à la qualité haute. Les deux
## autres se contentent d'un lissage de l'image finie (FXAA), presque gratuit.
const QUALITY_MSAA: Array[Viewport.MSAA] = [Viewport.MSAA_DISABLED, Viewport.MSAA_DISABLED, Viewport.MSAA_4X]
#@ all

## Réglages de la visite (5_data/visit/visit_settings.tres), donnés par la scène.
@export var settings: VisitSettings
## Titre affiché en haut de l'écran.
@export var title: String = ""
## Pose un trottoir et une chaussée devant la façade. À couper quand la scène visitée
## apporte son propre sol (la rue).
@export var ground: bool = true
## Vrai : la caméra se place seule pour que tout tienne dans l'image. Faux : elle part de
## « camera_position » et regarde « camera_target ».
@export var auto_frame: bool = true
@export var camera_position: Vector3 = Vector3.ZERO
@export var camera_target: Vector3 = Vector3.ZERO
## Champ de vision, en degrés ; 0 : celui des réglages de la visite.
@export var camera_fov: float = 0.0
## Portée des ombres du soleil, comptée depuis la caméra, en mètres ; 0 : celle des réglages.
## Au-delà, plus rien ne porte d'ombre. Une tour se regarde de plus loin qu'un immeuble : il lui
## faut une portée plus longue.
@export var shadow_distance: float = 0.0
#@ 13+
## Qualité au démarrage : 0 basse, 1 moyenne, 2 haute.
@export var quality: int = 1
## Baisser la qualité toute seule quand les images mettent trop longtemps.
@export var auto_quality: bool = true
#@ all

var _args: Dictionary[String, String] = {}
var _night: bool = false
var _environment: Environment
var _sky_material: ProceduralSkyMaterial
var _sun: DirectionalLight3D
var _camera: FreeCamera
var _banner: StepBanner
## Les nœuds visités : les enfants posés dans la scène.
var _subjects: Array[Node3D] = []
#@ 13+
## Mesures faites depuis le démarrage, et mesures lentes de suite.
var _periods: int = 0
var _slow_periods: int = 0
## Ce que la qualité automatique a fait, pour le dire à l'écran.
var _auto_note: String = ""
#@ all


func _ready() -> void:
	if settings == null:
		push_error("StepViewer : réglages de la visite absents (5_data/visit/visit_settings.tres).")
		return
	_args = _parse_args()
	_night = _args.has("night")
	for child: Node in get_children():
		if child is Node3D:
			_subjects.append(child as Node3D)
	if shadow_distance <= 0.0:
		shadow_distance = settings.shadow_distance
	_apply_overrides()
	_build_environment()
	if ground:
		_build_ground()
	_camera = FreeCamera.new()
	_camera.fov = option("fov", str(camera_fov if camera_fov > 0.0 else settings.camera_fov)).to_float()
	_camera.far = settings.camera_far
	add_child(_camera)
	_camera.current = true
	var camera_input: FreeCameraInput = FreeCameraInput.new()
	add_child(camera_input)
	camera_input.setup(_camera)
	_apply_time_of_day()
	_frame_camera()
#@ 13+
	if _args.has("quality"):
		quality = clampi(option("quality").to_int(), 0, settings.quality_names.size() - 1)
		auto_quality = false
	_apply_quality()
#@ all
	if _args.has("scale"):
		get_viewport().scaling_3d_scale = clampf(option("scale").to_float(), settings.min_render_scale, 1.0)
	if _args.has("shot"):
		_capture(option("shot"))
		return
	_banner = StepBanner.new()
	add_child(_banner)
	if _args.has("bench"):
		_benchmark(maxi(option("bench").to_int(), 1))
		return
	_banner.set_title(title)
	_banner.set_help(HELP_TEXT)
#@ 13+
	_show_quality()
	_banner.frame_measured.connect(_watch_frame_time)
#@ all
	_banner.start_meter(settings.meter_period)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_N:
			_night = not _night
			_apply_time_of_day()
		KEY_F:
			_frame_camera()
#@ 13+
		KEY_P:
			# P, et non Q : les touches sont lues par leur place sur le clavier, et la place du
			# Q d'un clavier QWERTY est celle du A d'un AZERTY, qui fait descendre la caméra.
			# La main est reprise : plus de baisse automatique.
			auto_quality = false
			_auto_note = ""
			quality = (quality + 1) % settings.quality_names.size()
			_apply_quality()
			_show_quality()
#@ all
		KEY_R:
#@ 13+
			auto_quality = false
			_auto_note = ""
			_show_quality()
#@ all
			var viewport: Viewport = get_viewport()
			var current: int = settings.render_scales.find(viewport.scaling_3d_scale)
			viewport.scaling_3d_scale = settings.render_scales[(current + 1) % settings.render_scales.size()]
		KEY_V:
			var off: bool = DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if off else DisplayServer.VSYNC_DISABLED)
		KEY_ESCAPE:
			get_tree().quit()


## Valeur d'une option de ligne de commande, ou « fallback » si elle est absente.
func option(key: String, fallback: String = "") -> String:
	return String(_args.get(key, fallback))


## Règle les variables demandées par « --set-<variable>=<valeur> » sur les nœuds visités qui
## les possèdent, puis les fait reconstruire.
func _apply_overrides() -> void:
	for key: String in _args:
		if not key.begins_with("set-"):
			continue
		var property: String = key.trim_prefix("set-")
		var value: Variant = str_to_var(_args[key])
		for subject: Node3D in _subjects:
			if property in subject:
				subject.set(property, value)
				if subject.has_method("rebuild"):
					subject.call("rebuild")


#@ 13+
# --- Qualité ----------------------------------------------------------------

## Applique la qualité courante : aux nœuds visités (finesse de leurs shaders), au soleil
## (ombres) et à la fenêtre de rendu (anticrénelage, résolution).
func _apply_quality() -> void:
	for subject: Node3D in _subjects:
		if subject.has_method("set_quality"):
			subject.call("set_quality", quality)
	_sun.directional_shadow_mode = QUALITY_SHADOW_MODES[quality]
	_sun.directional_shadow_max_distance = shadow_distance * settings.quality_shadow_shares[quality]
	RenderingServer.directional_soft_shadow_filter_set_quality(QUALITY_SHADOW_FILTERS[quality])
	var viewport: Viewport = get_viewport()
	viewport.msaa_3d = QUALITY_MSAA[quality]
	# Le lissage de l'image finie (FXAA) n'existe pas dans le moteur Compatibilité ; ailleurs, il
	# sert là où le suréchantillonnage (MSAA) est coupé.
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if QUALITY_MSAA[quality] == Viewport.MSAA_DISABLED else Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.scaling_3d_scale = settings.quality_render_scales[quality]


## Ce que la mesure affiche de la qualité : son nom, et ce que la visite en a fait toute seule.
func _show_quality() -> void:
	if _banner != null:
		_banner.set_quality(settings.quality_names[quality] + _auto_note)


## Baisse la qualité d'un cran quand plusieurs mesures de suite sont trop lentes. En qualité
## basse, il reste un dernier levier : rendre en demi-résolution. Elle ne remonte jamais seule :
## la qualité ferait le yoyo.
func _watch_frame_time(frame_ms: float) -> void:
	_periods += 1
	if not auto_quality or _periods <= settings.startup_periods:
		return
	_slow_periods = _slow_periods + 1 if frame_ms > settings.slow_frame_ms else 0
	if _slow_periods < settings.slow_periods:
		return
	_slow_periods = 0
	var viewport: Viewport = get_viewport()
	if quality > 0:
		quality -= 1
		_apply_quality()
		_auto_note = ", baissée automatiquement"
	elif viewport.scaling_3d_scale > settings.last_resort_render_scale:
		viewport.scaling_3d_scale = settings.last_resort_render_scale
		_auto_note = ", résolution réduite automatiquement"
	_show_quality()


#@ all
# --- Ciel, soleil, sol, jour et nuit ----------------------------------------

func _build_environment() -> void:
	_sky_material = ProceduralSkyMaterial.new()
	var sky: Sky = Sky.new()
	sky.sky_material = _sky_material

	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.glow_intensity = settings.glow_intensity
	_environment.glow_bloom = settings.glow_bloom
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)

	_sun = DirectionalLight3D.new()
	var angles: Vector2 = _parse_vector2(option("sun"), settings.sun_angles)
	_sun.rotation_degrees = Vector3(angles.x, angles.y, 0.0)
	_sun.shadow_enabled = true
	# L'ombre du soleil est rendue sur deux cartes, jusqu'à « shadow_distance » : la moitié du
	# travail des quatre cartes par défaut, pour une image très proche.
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_sun.directional_shadow_max_distance = shadow_distance
	add_child(_sun)
#@ 1-12
	# Anticrénelage : un lissage de l'image finie (FXAA), presque gratuit. Il n'existe pas dans
	# le moteur Compatibilité.
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
#@ all


## Un trottoir devant la façade, puis la chaussée.
func _build_ground() -> void:
	_add_slab(settings.sidewalk_size, settings.sidewalk_center, settings.sidewalk_color)
	_add_slab(settings.road_size, settings.road_center, settings.road_color)


func _add_slab(size: Vector3, center: Vector3, color: Color) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = settings.ground_roughness
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = center
	instance.material_override = material
	add_child(instance)


func _apply_time_of_day() -> void:
	var compatibility: bool = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if _night:
		# Heure bleue : le ciel garde assez de lumière pour qu'on lise encore les façades.
		_sky_material.sky_top_color = settings.night_sky_top
		_sky_material.sky_horizon_color = settings.night_sky_horizon
		_sky_material.ground_bottom_color = settings.night_ground_bottom
		_sky_material.ground_horizon_color = settings.night_ground_horizon
		_sun.light_color = settings.night_sun_color
		_sun.light_energy = settings.night_sun_energy
	else:
		_sky_material.sky_top_color = settings.day_sky_top
		_sky_material.sky_horizon_color = settings.day_sky_horizon
		_sky_material.ground_bottom_color = settings.day_ground_bottom
		_sky_material.ground_horizon_color = settings.day_ground_horizon
		_sun.light_color = settings.day_sun_color
		_sun.light_energy = settings.day_sun_energy
	# Compatibilité additionne en sRGB la lumière des lampes à ombres : à réglages égaux, les
	# surfaces éclairées y sortent bien plus claires qu'en Forward+ ou Mobile. On baisse donc le
	# soleil, et on le réchauffe le jour, pour retrouver à peu près la même image.
	if compatibility:
		_sun.light_energy *= settings.compatibility_sun_night if _night else settings.compatibility_sun_day
		if not _night:
			_sun.light_color = settings.compatibility_day_sun_color
	# Halo autour des fenêtres éclairées.
	_environment.glow_enabled = _night and not compatibility
	# Les immeubles allument eux-mêmes leurs fenêtres, à partir de l'étape 005.
	for subject: Node3D in _subjects:
		if subject.has_method("set_night"):
			subject.call("set_night", 1.0 if _night else 0.0)


# --- Caméra, mesure, capture ------------------------------------------------

## Place la caméra : là où la ligne de commande ou la scène le demandent, ou bien de façon
## que tout ce qui est visité tienne dans l'image, vu de trois quarts.
func _frame_camera() -> void:
	var position_wanted: Vector3 = settings.camera_position if auto_frame else camera_position
	var target_wanted: Vector3 = settings.camera_target if auto_frame else camera_target
	if _args.has("cam") or _args.has("look") or not auto_frame:
		_camera.look_at_from_position(_parse_vector3(option("cam"), position_wanted),
				_parse_vector3(option("look"), target_wanted), Vector3.UP)
		return
	var bounds: AABB = AABB()
	var first: bool = true
	for subject: Node3D in _subjects:
		var box: AABB = _bounds_of(subject)
		if box.size.is_zero_approx():
			continue
		bounds = box if first else bounds.merge(box)
		first = false
	if first:
		_camera.look_at_from_position(position_wanted, target_wanted, Vector3.UP)
		return
	_camera.frame_bounds(bounds, get_viewport().get_visible_rect().size, settings.frame_margin,
			settings.frame_side_share, settings.eye_height, settings.eye_height_share)


## Boîte englobante, dans le monde, de tout ce qu'un nœud dessine. Les immeubles rangent leur
## géométrie dans des nœuds internes : on les parcourt aussi.
func _bounds_of(node: Node) -> AABB:
	var bounds: AABB = AABB()
	var first: bool = true
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		pending.append_array(current.get_children(true))
		var visual: VisualInstance3D = current as VisualInstance3D
		if visual == null:
			continue
		var box: AABB = visual.global_transform * visual.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds


## Mesure le temps de rendu sur « frames » images (le bandeau compte), l'écrit dans la console
## et quitte.
func _benchmark(frames: int) -> void:
	var text: String = await _banner.benchmark(frames, settings.warmup_frames)
	print(text)
	get_tree().quit()


## Rend quelques images pour laisser les ombres et le ciel se stabiliser, enregistre et quitte.
func _capture(path: String) -> void:
	for _frame: int in range(settings.capture_frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var error: Error = image.save_png(path)
	print("capture: ", path, " ", image.get_size(), " erreur=", error)
	get_tree().quit()


func _parse_args() -> Dictionary[String, String]:
	var result: Dictionary[String, String] = {}
	for raw: String in OS.get_cmdline_user_args():
		if not raw.begins_with("--"):
			continue
		var body: String = raw.trim_prefix("--")
		var separator: int = body.find("=")
		if separator < 0:
			result[body] = "1"
		else:
			result[body.substr(0, separator)] = body.substr(separator + 1)
	return result


## « x,y,z » lu comme un Vector3, ou « fallback » si le texte est vide ou ne s'y prête pas.
func _parse_vector3(text: String, fallback: Vector3) -> Vector3:
	if text.is_empty():
		return fallback
	var value: Variant = str_to_var("Vector3(%s)" % text)
	if value is Vector3:
		return value
	return fallback


## « x,y » lu comme un Vector2, ou « fallback » si le texte est vide ou ne s'y prête pas.
func _parse_vector2(text: String, fallback: Vector2) -> Vector2:
	if text.is_empty():
		return fallback
	var value: Variant = str_to_var("Vector2(%s)" % text)
	if value is Vector2:
		return value
	return fallback
