class_name RoomView
extends Control
## La vue de dessus : la salle du document, dessinée depuis la planche du catalogue, dans l'ordre de `DrawOrder`.
## Chaque chose occupe à l'écran son emprise au sol (la taille de son asset, en mètres, fois son échelle), tournée
## autour de son point d'ancrage. Une chose inactive est dessinée en transparence. Seules les choses dont l'emprise
## touche la vue sont dessinées. La vue ne modifie rien : elle redessine quand le document ou le cadrage change.
#@ 7+
## Pendant un geste du cadre bleu, la vue montre les choses sélectionnées comme elles seront au relâchement (l'aperçu),
## sans toucher au document ; elle sait aussi dire quelle chose est sous la souris.
#@ all

## La couleur d'une chose dont l'asset n'a pas d'image (« non récupérée »).
const MISSING_COLOR: Color = Color(1.0, 0.0, 1.0, 0.6)
## L'opacité d'une chose inactive.
const INACTIVE_ALPHA: float = 0.35

## Le cadrage de la vue (zoom, déplacement).
var view_transform: ViewTransform
#@ 7+
## Les calques qu'un clic ou un rectangle ne sélectionne pas (le sol, par défaut).
var locked_layers: PackedStringArray = PackedStringArray(["sol"])
#@ all
var _document: RoomDocument
var _catalog: AssetCatalogDef
#@ 7+
var _preview: Dictionary = {}
#@ all


## Branche la vue sur `document`, `catalog` et `transform`.
func setup(document: RoomDocument, catalog: AssetCatalogDef, transform: ViewTransform) -> void:
	_document = document
	_catalog = catalog
	view_transform = transform
	_document.changed.connect(queue_redraw)
	view_transform.changed.connect(queue_redraw)
	queue_redraw()
#@ 7+


## Montre les choses `preview.ids` déplacées de `preview.move` (en mètres), puis tournées de `preview.angle` degrés
## et agrandies de `preview.factor` autour de `preview.pivot`, sans modifier le document.
func set_preview(preview: Dictionary) -> void:
	_preview = preview
	queue_redraw()


## Revient au document tel qu'il est.
func clear_preview() -> void:
	_preview = {}
	queue_redraw()
#@ all


## Les quatre coins de l'emprise de la chose `thing_id` à l'écran.
func corners_of(thing_id: int) -> PackedVector2Array:
	var asset: AssetDef = _catalog.find(StringName(_document.value(thing_id, &"asset")))
	var size_m: Vector2 = Vector2.ONE if asset == null else asset.size_m
	var anchor: Vector2 = Vector2(0.5, 0.5) if asset == null else asset.anchor
#@ 6
	var size_px: Vector2 = size_m * float(_document.value(thing_id, &"scale")) * view_transform.pixels_per_meter()
#@ 7+
	var size_px: Vector2 = size_m * float(_shown(thing_id)[&"scale"]) * view_transform.pixels_per_meter()
#@ all
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
#@ 7+


## Le rectangle qui contient toutes les choses `ids` (vide si `ids` est vide) : le cadre bleu.
func selection_rect(ids: Array[int]) -> Rect2:
	var rect: Rect2 = Rect2()
	for index: int in ids.size():
		rect = screen_rect_of(ids[index]) if index == 0 else rect.merge(screen_rect_of(ids[index]))
	return rect


## La chose la plus haute sous le point `screen` (hors des calques verrouillés), ou 0.
func thing_at(screen: Vector2) -> int:
	var shown: PackedInt32Array = visible_ids()
	for index: int in range(shown.size() - 1, -1, -1):
		var thing_id: int = shown[index]
		if _pickable(thing_id) and Geometry2D.is_point_in_polygon(screen, corners_of(thing_id)):
			return thing_id
	return 0


## Les choses (hors des calques verrouillés) dont l'emprise touche le rectangle `screen_rect`.
func things_in(screen_rect: Rect2) -> Array[int]:
	var found: Array[int] = []
	for thing_id: int in visible_ids():
		if _pickable(thing_id) and screen_rect.intersects(screen_rect_of(thing_id)):
			found.append(thing_id)
	return found
#@ all


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
#@ 6
		var size_px: Vector2 = (Vector2.ONE if asset == null else asset.size_m) \
				* float(_document.value(thing_id, &"scale")) * view_transform.pixels_per_meter()
#@ 7+
		var size_px: Vector2 = (Vector2.ONE if asset == null else asset.size_m) \
				* float(_shown(thing_id)[&"scale"]) * view_transform.pixels_per_meter()
#@ all
		var anchor: Vector2 = Vector2(0.5, 0.5) if asset == null else asset.anchor
		draw_set_transform_matrix(_placement(thing_id))
		var target: Rect2 = Rect2(-anchor * size_px, size_px)
		if asset == null or asset.atlas == null:
			draw_rect(target, MISSING_COLOR)
		else:
			draw_texture_rect_region(asset.atlas, target, Rect2(asset.region), color)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _placement(thing_id: int) -> Transform2D:
#@ 6
	var screen: Vector2 = view_transform.world_to_screen(_document.value(thing_id, &"position"))
	return Transform2D(deg_to_rad(float(_document.value(thing_id, &"rotation"))), screen)
#@ 7+
	var shown: Dictionary = _shown(thing_id)
	var screen: Vector2 = view_transform.world_to_screen(shown[&"position"])
	return Transform2D(deg_to_rad(float(shown[&"rotation"])), screen)


# La position, la rotation et l'échelle à montrer pour `thing_id` : celles du document, ou l'aperçu du geste en cours.
func _shown(thing_id: int) -> Dictionary:
	# Pas de variables nommées position, rotation ou scale : elles masqueraient celles du Control (une erreur, ici).
	var place_m: Vector3 = _document.value(thing_id, &"position")
	var turn_deg: float = _document.value(thing_id, &"rotation")
	var factor_now: float = _document.value(thing_id, &"scale")
	if _preview.is_empty() or not (_preview[&"ids"] as Array).has(thing_id):
		return {&"position": place_m, &"rotation": turn_deg, &"scale": factor_now}
	var pivot: Vector3 = _preview[&"pivot"]
	var factor: float = _preview[&"factor"]
	var angle: float = _preview[&"angle"]
	var moved: Vector3 = place_m + Vector3(_preview[&"move"])
	var offset: Vector2 = Vector2(moved.x - pivot.x, moved.z - pivot.z).rotated(deg_to_rad(angle)) * factor
	return {&"position": Vector3(pivot.x + offset.x, moved.y, pivot.z + offset.y), &"rotation": turn_deg + angle,
			&"scale": factor_now * factor}


func _pickable(thing_id: int) -> bool:
	return not locked_layers.has(String(_document.value(thing_id, &"layer")))
#@ all
