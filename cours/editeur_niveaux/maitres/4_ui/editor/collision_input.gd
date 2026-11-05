class_name CollisionInput
extends Node
## La souris et le clavier sur la vue en mode « Collisions », traduits en modifications des formes de collision :
## - clic dans une forme : la choisit (le contour de la salle est la forme 0, sous toutes les autres) ;
## - tirer un sommet de la forme choisie : le déplace (aperçu pendant le glisser, un seul pas au relâchement) ;
## - double-clic sur un côté de la forme choisie : y ajoute un sommet ;
## - Suppr : retire le sommet choisi, ou la forme choisie si aucun sommet ne l'est (jamais le contour) ;
## - Ctrl+clic : une nouvelle forme carrée sous la souris.
## Une modification que le document refuse (des côtés qui se croiseraient) est annoncée par `refused`.
## Le script écoute `gui_input` de la vue, et ne fait rien quand il n'est pas `active`.

## La forme choisie, ses sommets ou l'aperçu viennent de changer : le calque des collisions doit se redessiner.
signal overlay_changed
## Une modification a été refusée, pour la raison `reason`.
signal refused(reason: String)

## Vrai en mode « Collisions » ; sinon, le script laisse passer tous les événements.
var active: bool = false
## L'indice de la forme choisie (-1 : aucune).
var chosen: int = -1
## L'indice du sommet choisi dans la forme choisie (-1 : aucun).
var chosen_point: int = -1
var _view: RoomView
var _document: RoomDocument
var _settings: EditorSettingsDef
var _dragging: bool = false
var _preview: PackedVector2Array = PackedVector2Array()


## Écoute la vue `view` et modifie les formes de `document`, selon les réglages (rayon de prise, côté d'une forme neuve).
func setup(view: RoomView, document: RoomDocument, settings: EditorSettingsDef) -> void:
	_view = view
	_document = document
	_settings = settings
	view.gui_input.connect(handle)
	document.changed.connect(_forget_missing)


## Les formes à dessiner : celles du document, avec l'aperçu du sommet qu'on tire.
func shown_polygons() -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	polygons.assign(_document.room_value(&"collisions"))
	if _dragging and chosen >= 0 and chosen < polygons.size():
		polygons[chosen] = _preview
	return polygons


## Traduit l'événement `event` ; rend true s'il a servi.
func handle(event: InputEvent) -> bool:
	if not active or not _document.is_open():
		return false
	var done: bool = false
	var button: InputEventMouseButton = event as InputEventMouseButton
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	var key: InputEventKey = event as InputEventKey
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		done = _on_button(button)
	elif motion != null and _dragging:
		_preview = CollisionTools.moved_point(shown_polygons()[chosen], chosen_point, _world(motion.position))
		overlay_changed.emit()
		done = true
	elif key != null and key.pressed and key.keycode == KEY_DELETE and chosen >= 0:
		done = _delete()
	if done:
		_view.accept_event()
	return done


func _on_button(button: InputEventMouseButton) -> bool:
	var point: Vector2 = _world(button.position)
	var polygons: Array[PackedVector2Array] = shown_polygons()
	if not button.pressed:
		if _dragging:
			_dragging = false
			_replace(chosen, _preview)
		return true
	if button.ctrl_pressed:
		polygons.append(CollisionTools.square(point, _settings.collision_square_m))
		if _commit(polygons):
			chosen = polygons.size() - 1
			chosen_point = -1
		return true
	if chosen >= 0 and button.double_click:
		var edge: int = CollisionTools.nearest_edge(polygons[chosen], point, _pick_radius())
		if edge >= 0:
			_replace(chosen, CollisionTools.inserted_point(polygons[chosen], edge, point))
			chosen_point = edge + 1
		return true
	if chosen >= 0:
		var vertex: int = CollisionTools.nearest_point(polygons[chosen], point, _pick_radius())
		if vertex >= 0:
			chosen_point = vertex
			_dragging = true
			_preview = polygons[chosen]
			overlay_changed.emit()
			return true
	chosen = CollisionTools.polygon_at(polygons, point)
	chosen_point = -1
	overlay_changed.emit()
	return true


func _delete() -> bool:
	var polygons: Array[PackedVector2Array] = shown_polygons()
	if chosen_point >= 0:
		if polygons[chosen].size() <= CollisionTools.MIN_POINTS:
			refused.emit("Une forme garde au moins %d sommets" % CollisionTools.MIN_POINTS)
			return true
		_replace(chosen, CollisionTools.removed_point(polygons[chosen], chosen_point))
		chosen_point = -1
		return true
	if chosen == 0:
		refused.emit("Le contour de la salle ne se supprime pas")
		return true
	polygons.remove_at(chosen)
	if _commit(polygons):
		chosen = -1
	return true


func _replace(index: int, polygon: PackedVector2Array) -> void:
	var polygons: Array[PackedVector2Array] = []
	polygons.assign(_document.room_value(&"collisions"))
	polygons[index] = polygon
	_commit(polygons)


func _commit(polygons: Array[PackedVector2Array]) -> bool:
	var done: bool = _document.set_room_fields({&"collisions": polygons})
	if not done:
		refused.emit("; ".join(_document.errors))
	overlay_changed.emit()
	return done


func _forget_missing() -> void:
	var count: int = (_document.room_value(&"collisions") as Array).size() if _document.is_open() else 0
	if chosen >= count:
		chosen = -1
		chosen_point = -1


func _world(screen: Vector2) -> Vector2:
	var world: Vector3 = _view.view_transform.screen_to_world(screen)
	return Vector2(world.x, world.z)


func _pick_radius() -> float:
	return _settings.point_pick_px / _view.view_transform.pixels_per_meter()
