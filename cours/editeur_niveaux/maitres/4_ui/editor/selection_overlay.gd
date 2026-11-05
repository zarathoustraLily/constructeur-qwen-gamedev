class_name SelectionOverlay
extends Control
## Le calque de dessin posé sur la vue : le cadre bleu de la sélection, ses quatre poignées d'angle, sa poignée ronde de
## rotation reliée au haut du cadre, et le rectangle de sélection pendant un glisser dans le vide. Il laisse passer la
## souris à la vue (`mouse_filter` : ignorer) et redessine quand `SelectionInput` le lui dit.

## L'épaisseur des traits du cadre, en pixels.
const LINE_WIDTH: float = 2.0
## L'opacité du fond du rectangle de sélection.
const BAND_ALPHA: float = 0.15

var _input: SelectionInput
var _settings: EditorSettingsDef


## Dessine ce que montre `input`, aux couleurs des réglages.
func setup(input: SelectionInput, settings: EditorSettingsDef) -> void:
	_input = input
	_settings = settings
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_input.overlay_changed.connect(queue_redraw)


func _draw() -> void:
	if _input == null:
		return
	var color: Color = _settings.selection_color
	var gizmo: TransformGizmo = _input.gizmo
	if gizmo.box.has_area():
		draw_rect(gizmo.box, color, false, LINE_WIDTH)
		var top_middle: Vector2 = Vector2(gizmo.box.get_center().x, gizmo.box.position.y)
		draw_line(top_middle, gizmo.point_of(TransformGizmo.Handle.ROTATE), color, LINE_WIDTH)
		draw_circle(gizmo.point_of(TransformGizmo.Handle.ROTATE), _settings.handle_size_px / 2.0, color)
		for handle: TransformGizmo.Handle in [TransformGizmo.Handle.TOP_LEFT, TransformGizmo.Handle.TOP_RIGHT,
				TransformGizmo.Handle.BOTTOM_RIGHT, TransformGizmo.Handle.BOTTOM_LEFT]:
			draw_rect(gizmo.rect_of(handle), color)
	if _input.band.has_area():
		draw_rect(_input.band, Color(color, BAND_ALPHA))
		draw_rect(_input.band, color, false, LINE_WIDTH / 2.0)
