class_name CollisionView
extends Control
## Les formes de collision de la salle, dessinées par-dessus la vue : un fond rouge transparent et un contour par forme,
## plus de sommets pleins pour la forme choisie. Le calque laisse passer la souris à la vue ; il ne se montre qu'en mode
## « Collisions », et redessine quand le document, le cadrage ou la forme choisie changent.

## La couleur des formes.
const COLOR: Color = Color(1.0, 0.25, 0.2)
## L'opacité du fond d'une forme.
const FILL_ALPHA: float = 0.18
## L'épaisseur des contours, en pixels.
const LINE_WIDTH: float = 2.0
## Le rayon d'un sommet de la forme choisie, en pixels.
const POINT_RADIUS: float = 5.0

var _document: RoomDocument
var _transform: ViewProjection
var _input: CollisionInput


## Dessine les formes de `document`, au cadrage `transform`, avec la forme choisie et l'aperçu de `input`.
func setup(document: RoomDocument, transform: ViewProjection, input: CollisionInput) -> void:
	_document = document
	_transform = transform
	_input = input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_document.changed.connect(queue_redraw)
	_transform.changed.connect(queue_redraw)
	_input.overlay_changed.connect(queue_redraw)


## Les sommets du polygone `polygon` (en mètres) à l'écran.
func to_screen(polygon: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in polygon:
		result.append(_transform.world_to_screen(Vector3(point.x, 0.0, point.y)))
	return result


func _draw() -> void:
	if _document == null or not _document.is_open():
		return
	var polygons: Array[PackedVector2Array] = _input.shown_polygons()
	for index: int in polygons.size():
		var screen: PackedVector2Array = to_screen(polygons[index])
		if screen.size() < CollisionTools.MIN_POINTS:
			continue
		if index > 0:
			draw_colored_polygon(screen, Color(COLOR, FILL_ALPHA))
		var closed: PackedVector2Array = screen.duplicate()
		closed.append(screen[0])
		draw_polyline(closed, COLOR, LINE_WIDTH * (2.0 if index == _input.chosen else 1.0))
		if index == _input.chosen:
			for point: Vector2 in screen:
				draw_circle(point, POINT_RADIUS, COLOR)
