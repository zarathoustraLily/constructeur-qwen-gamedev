class_name RoomView
extends Control
## La vue de dessus : la salle du document, dessinée depuis la planche du catalogue, dans l'ordre de `DrawOrder`.
## Chaque chose occupe à l'écran son emprise au sol (la taille de son asset, en mètres, fois son échelle), tournée
## autour de son point d'ancrage. Une chose inactive est dessinée en transparence. Seules les choses dont l'emprise
## touche la vue sont dessinées. La vue ne modifie rien : elle redessine quand le document ou le cadrage change.

## La couleur d'une chose dont l'asset n'a pas d'image (« non récupérée »).
const MISSING_COLOR: Color = Color(1.0, 0.0, 1.0, 0.6)
## L'opacité d'une chose inactive.
const INACTIVE_ALPHA: float = 0.35

## Le cadrage de la vue (zoom, déplacement).
var view_transform: ViewTransform
var _document: RoomDocument
var _catalog: AssetCatalogDef


## Branche la vue sur `document`, `catalog` et `transform`.
func setup(document: RoomDocument, catalog: AssetCatalogDef, transform: ViewTransform) -> void:
	_document = document
	_catalog = catalog
	view_transform = transform
	_document.changed.connect(queue_redraw)
	view_transform.changed.connect(queue_redraw)
	queue_redraw()


## Les quatre coins de l'emprise de la chose `thing_id` à l'écran.
func corners_of(thing_id: int) -> PackedVector2Array:
	var asset: AssetDef = _catalog.find(StringName(_document.value(thing_id, &"asset")))
	var size_m: Vector2 = Vector2.ONE if asset == null else asset.size_m
	var anchor: Vector2 = Vector2(0.5, 0.5) if asset == null else asset.anchor
	var size_px: Vector2 = size_m * float(_document.value(thing_id, &"scale")) * view_transform.pixels_per_meter()
	var place: Transform2D = _placement(thing_id)
	var top_left: Vector2 = -anchor * size_px
	return PackedVector2Array([place * top_left, place * (top_left + Vector2(size_px.x, 0)),
			place * (top_left + size_px), place * (top_left + Vector2(0, size_px.y))])


## Le rectangle (aligné sur l'écran) qui contient l'emprise de la chose `thing_id`.
func screen_rect_of(thing_id: int) -> Rect2:
	var points: PackedVector2Array = corners_of(thing_id)
	var rect: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		rect = rect.expand(point)
	return rect


## Les choses à dessiner, dans l'ordre : celles dont l'emprise touche la vue.
func visible_ids() -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	if _document == null or not _document.is_open():
		return result
	var view_rect: Rect2 = Rect2(Vector2.ZERO, size)
	for thing_id: int in DrawOrder.sorted(_document, _catalog.layers):
		if view_rect.intersects(screen_rect_of(thing_id)):
			result.append(thing_id)
	return result


func _draw() -> void:
	for thing_id: int in visible_ids():
		var asset: AssetDef = _catalog.find(StringName(_document.value(thing_id, &"asset")))
		var color: Color = _document.value(thing_id, &"color")
		if int(_document.value(thing_id, &"active")) == 0:
			color.a *= INACTIVE_ALPHA
		var size_px: Vector2 = (Vector2.ONE if asset == null else asset.size_m) \
				* float(_document.value(thing_id, &"scale")) * view_transform.pixels_per_meter()
		var anchor: Vector2 = Vector2(0.5, 0.5) if asset == null else asset.anchor
		draw_set_transform_matrix(_placement(thing_id))
		var target: Rect2 = Rect2(-anchor * size_px, size_px)
		if asset == null or asset.atlas == null:
			draw_rect(target, MISSING_COLOR)
		else:
			draw_texture_rect_region(asset.atlas, target, Rect2(asset.region), color)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _placement(thing_id: int) -> Transform2D:
	var screen: Vector2 = view_transform.world_to_screen(_document.value(thing_id, &"position"))
	return Transform2D(deg_to_rad(float(_document.value(thing_id, &"rotation"))), screen)
