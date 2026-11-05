class_name EffectView
extends Control
## Les effets placés, en aperçu animé par-dessus la vue : les particules de chaque effet (`EffectPreview`), à leur
## couleur, plus un repère et le nom de l'effet ; l'effet choisi est cerclé. Le calque laisse passer la souris à la vue ;
## il ne se montre qu'en mode « Effets », et ne s'anime que visible.

## Le rayon du repère d'un effet, en pixels.
const MARK_RADIUS: float = 6.0

## Le temps de l'aperçu, en secondes.
var time: float = 0.0
var _document: RoomDocument
var _transform: ViewTransform
var _input: EffectInput
var _effects: Dictionary[StringName, FxDef] = {}


## Dessine les effets placés de `document`, au cadrage `transform`, d'après les définitions `effects`.
func setup(document: RoomDocument, transform: ViewTransform, input: EffectInput, effects: Array[FxDef]) -> void:
	_document = document
	_transform = transform
	_input = input
	for effect: FxDef in effects:
		_effects[effect.id] = effect
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_document.changed.connect(queue_redraw)
	_transform.changed.connect(queue_redraw)
	_input.overlay_changed.connect(queue_redraw)


func _process(delta: float) -> void:
	if visible:
		time += delta
		queue_redraw()


func _draw() -> void:
	if _document == null or not _document.is_open():
		return
	var ids: PackedStringArray = _document.room_value(&"effect_ids")
	var points: PackedVector3Array = _input.shown_positions()
	var ppm: float = _transform.pixels_per_meter()
	for index: int in mini(ids.size(), points.size()):
		var effect: FxDef = _effects.get(StringName(ids[index]))
		var screen: Vector2 = _transform.world_to_screen(points[index])
		if effect == null:
			draw_circle(screen, MARK_RADIUS, Color.MAGENTA)
			continue
		for particle: Dictionary in EffectPreview.particles(effect, Vector2(points[index].x, points[index].z), time):
			var position_m: Vector2 = particle[&"position"]
			draw_circle(_transform.world_to_screen(Vector3(position_m.x, 0.0, position_m.y)),
					maxf(float(particle[&"radius"]) * ppm, 1.0), Color(effect.color, float(particle[&"alpha"])))
		draw_circle(screen, MARK_RADIUS, effect.color)
		draw_string(get_theme_default_font(), screen + Vector2(MARK_RADIUS * 2.0, 0.0), effect.display_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_default_font_size())
		if index == _input.chosen:
			draw_arc(screen, MARK_RADIUS * 2.0, 0.0, TAU, 24, effect.color, 2.0)
