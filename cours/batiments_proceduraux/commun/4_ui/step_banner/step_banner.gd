extends CanvasLayer
## Bandeau affiché par-dessus la visite des étapes : titre de l'étape, aide, mesure du rendu.
## C'est de l'interface, sans logique de jeu : il vit dans « 4_ui ».
##
## Il mesure lui-même le temps de rendu de la fenêtre et l'affiche, en moyenne sur une période ;
## à chaque période, il dit combien a duré une image (signal frame_measured).

## Durée moyenne d'une image sur la dernière période, attente de l'écran comprise, en millisecondes.
signal frame_measured(frame_ms: float)

const RENDERER_NAMES: Dictionary[String, String] = {"forward_plus": "Forward+", "mobile": "Mobile", "gl_compatibility": "Compatibilité"}

var _title: Label
var _help: Label
var _meter: Label
## Durée d'une période de mesure, en secondes ; 0 : pas de mesure en continu.
var _period: float = 0.0
## Début de la période en cours, en microsecondes, et ce qu'elle a accumulé.
var _started: int = 0
var _frames: int = 0
var _gpu_ms: float = 0.0
var _cpu_ms: float = 0.0
#@ 13+
## La qualité affichée dans la mesure, et ce que la visite en a fait toute seule.
var _quality: String = ""
#@ all


func _ready() -> void:
	_title = _make_label(12.0, 20)
	_help = _make_label(44.0, 15)
	_meter = _make_label(68.0, 15)
	set_process(false)


func set_title(text: String) -> void:
	_title.text = text


func set_help(text: String) -> void:
	_help.text = text
#@ 13+


## La qualité courante, telle qu'elle doit apparaître dans la mesure.
func set_quality(text: String) -> void:
	_quality = text
#@ all


## Mesure en continu, par périodes de « period » secondes.
func start_meter(period: float) -> void:
	_period = period
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_restart(Time.get_ticks_usec())
	set_process(true)


func _process(_delta: float) -> void:
	_accumulate()
	# L'horloge, et non « delta » : le moteur plafonne « delta » quand une image dure trop.
	var now: int = Time.get_ticks_usec()
	var elapsed_ms: float = float(now - _started) / 1000.0
	if elapsed_ms < 1000.0 * _period:
		return
	var frames: float = float(_frames)
	var frame_ms: float = elapsed_ms / frames
	_meter.text = meter_text(_gpu_ms / frames, _cpu_ms / frames, frame_ms)
	_restart(now)
	frame_measured.emit(frame_ms)


## Mesure le temps de rendu sur « frames » images, après « warmup » images écartées (elles
## compilent les shaders et remplissent les caches), synchro verticale coupée. Rend la ligne de
## mesure.
func benchmark(frames: int, warmup: int) -> String:
	set_process(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	for _frame: int in range(warmup):
		await RenderingServer.frame_post_draw
	_restart(Time.get_ticks_usec())
	for _frame: int in range(frames):
		await RenderingServer.frame_post_draw
		_accumulate()
	var frame_ms: float = float(Time.get_ticks_usec() - _started) / 1000.0 / float(frames)
	return "mesure sur %d images\n%s" % [frames, meter_text(_gpu_ms / float(frames), _cpu_ms / float(frames), frame_ms)]


## Ajoute à la période en cours le temps de rendu de la dernière image.
func _accumulate() -> void:
	var viewport_rid: RID = get_viewport().get_viewport_rid()
	_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
	_cpu_ms += RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid) + RenderingServer.get_frame_setup_time_cpu()
	_frames += 1


func _restart(now: int) -> void:
	_started = now
	_frames = 0
	_gpu_ms = 0.0
	_cpu_ms = 0.0


## Une ligne de mesure. « gpu_ms » et « cpu_ms » : temps de rendu par image ; « frame_ms » :
## temps réel entre deux images, attente de l'écran comprise.
func meter_text(gpu_ms: float, cpu_ms: float, frame_ms: float) -> String:
	var viewport: Viewport = get_viewport()
	var rendered: Vector2 = (viewport.get_visible_rect().size * viewport.scaling_3d_scale).round()
	var gpu_text: String = "%.1f ms par image" % gpu_ms if gpu_ms > 0.0 else "non mesurée par ce pilote"
	var capped: String = "" if DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED else ", synchro verticale"
	var method: String = RenderingServer.get_current_rendering_method()
#@ 1-12
	return "Carte graphique : %s   Processeur : %.1f ms   Affiché : %.0f images/s (%.1f ms%s)   Rendu 3D : %d × %d (%d %%)   %s   %s" % [
			gpu_text, cpu_ms, 1000.0 / maxf(frame_ms, 0.001), frame_ms, capped,
			int(rendered.x), int(rendered.y), roundi(100.0 * viewport.scaling_3d_scale),
			RENDERER_NAMES.get(method, method), RenderingServer.get_video_adapter_name()]
#@ 13+
	return "Carte graphique : %s   Processeur : %.1f ms   Affiché : %.0f images/s (%.1f ms%s)   Qualité %s   Rendu 3D : %d × %d (%d %%)   %s   %s\n%s" % [
			gpu_text, cpu_ms, 1000.0 / maxf(frame_ms, 0.001), frame_ms, capped, _quality,
			int(rendered.x), int(rendered.y), roundi(100.0 * viewport.scaling_3d_scale),
			RENDERER_NAMES.get(method, method), RenderingServer.get_video_adapter_name(), _drawn_text()]


## Ce que le moteur a dessiné pendant la dernière image : des objets (un nœud de maillage est un
## objet), des triangles, des appels de dessin ; pour l'image, puis pour les cartes d'ombre.
## Ces nombres ne dépendent pas de la machine : ce sont eux que les niveaux de détail et
## l'occultation font baisser. Le temps par image, lui, dépend de la carte graphique.
func _drawn_text() -> String:
	return "Dessiné : %d objets, %d triangles, %d appels de dessin   Ombres : %d objets, %d triangles, %d appels" % [
			_drawn(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
			_drawn(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
			_drawn(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			_drawn(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
			_drawn(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
			_drawn(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)]


func _drawn(type: Viewport.RenderInfoType, info: Viewport.RenderInfo) -> int:
	return get_viewport().get_render_info(type, info)
#@ all


func _make_label(top: float, font_size: int) -> Label:
	var label: Label = Label.new()
	label.position = Vector2(16.0, top)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)
	return label
