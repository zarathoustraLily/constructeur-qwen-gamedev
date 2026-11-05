class_name TransformGizmo
extends RefCounted
## Le cadre bleu autour de la sélection, en géométrie pure : où sont ses poignées à l'écran, quelle poignée se trouve
## sous la souris, et ce que donne un glisser sur une poignée (un déplacement, un angle, un facteur d'échelle). Le dessin
## est dans `4_ui/editor/selection_overlay.gd`, la souris dans `4_ui/editor/selection_input.gd`.
## Les poignées d'angle agrandissent autour du centre du cadre ; la poignée ronde, au-dessus du cadre, le fait tourner
## autour de son centre ; l'intérieur du cadre le déplace.

## Ce qui se trouve sous la souris.
enum Handle { NONE, BODY, TOP_LEFT, TOP_RIGHT, BOTTOM_RIGHT, BOTTOM_LEFT, ROTATE }

## Le cadre de la sélection à l'écran (vide s'il n'y a pas de sélection).
var box: Rect2 = Rect2()
var _settings: EditorSettingsDef
var _handle: Handle = Handle.NONE
var _start: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2.ZERO


## Prend les réglages (taille des poignées, distance de la poignée de rotation).
func setup(settings: EditorSettingsDef) -> void:
	_settings = settings


## Le point de l'écran de la poignée `handle`.
func point_of(handle: Handle) -> Vector2:
	match handle:
		Handle.TOP_LEFT:
			return box.position
		Handle.TOP_RIGHT:
			return Vector2(box.end.x, box.position.y)
		Handle.BOTTOM_RIGHT:
			return box.end
		Handle.BOTTOM_LEFT:
			return Vector2(box.position.x, box.end.y)
		Handle.ROTATE:
			return Vector2(box.get_center().x, box.position.y - _settings.rotate_handle_offset_px)
		_:
			return box.get_center()


## Le carré de la poignée `handle`, à l'écran.
func rect_of(handle: Handle) -> Rect2:
	var side: float = _settings.handle_size_px
	return Rect2(point_of(handle) - Vector2(side, side) / 2.0, Vector2(side, side))


## Ce qui se trouve sous `point` : une poignée d'angle, la poignée de rotation, l'intérieur du cadre, ou rien.
func hit_test(point: Vector2) -> Handle:
	if not box.has_area():
		return Handle.NONE
	for handle: Handle in [Handle.TOP_LEFT, Handle.TOP_RIGHT, Handle.BOTTOM_RIGHT, Handle.BOTTOM_LEFT, Handle.ROTATE]:
		if rect_of(handle).has_point(point):
			return handle
	return Handle.BODY if box.has_point(point) else Handle.NONE


## Commence à tirer la poignée `handle`, depuis `point`.
func begin(handle: Handle, point: Vector2) -> void:
	_handle = handle
	_start = point
	_center = box.get_center()


## La poignée qu'on tire (`NONE` si aucune).
func dragging() -> Handle:
	return _handle


## Le point où le glisser a commencé.
func start() -> Vector2:
	return _start


## L'angle parcouru par la poignée de rotation, de son départ à `point`, en degrés, autour du centre du cadre.
func angle_to(point: Vector2) -> float:
	return rad_to_deg((_start - _center).angle_to(point - _center))


## Le facteur d'échelle d'une poignée d'angle amenée en `point` : le rapport des distances au centre du cadre.
func factor_to(point: Vector2) -> float:
	var from_center: float = (_start - _center).length()
	return 1.0 if is_zero_approx(from_center) else (point - _center).length() / from_center


## Arrête le glisser.
func finish() -> void:
	_handle = Handle.NONE
