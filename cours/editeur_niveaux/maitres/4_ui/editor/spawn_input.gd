class_name SpawnInput
extends Node
## La souris et le clavier sur la vue en mode « Apparitions » : le départ du héros et les points d'apparition des
## ennemis.
## - tirer le départ du héros ou un point : le déplace (aperçu, puis un seul pas au relâchement) ;
## - Ctrl+clic : un nouveau point d'apparition, de rôle « tous » ;
## - R : change le rôle du point choisi (au contact, à distance, tous) ;
## - Suppr : retire le point choisi (le départ du héros reste).
## Le script écoute `gui_input` de la vue, et ne fait rien quand il n'est pas `active`.

## Le point choisi ou l'aperçu viennent de changer : le calque des apparitions doit se redessiner.
signal overlay_changed
## Une modification a été refusée, pour la raison `reason`.
signal refused(reason: String)

## Ce qu'on désigne par `chosen` quand c'est le départ du héros.
const HERO: int = -2
## Le rôle d'un point neuf.
const NEW_ROLE: String = "tous"

## Vrai en mode « Apparitions » ; sinon, le script laisse passer tous les événements.
var active: bool = false
## Le point choisi : son indice, `HERO` pour le départ du héros, -1 pour rien.
var chosen: int = -1
var _view: RoomView
var _document: RoomDocument
var _settings: EditorSettingsDef
var _dragging: bool = false
var _preview: Vector3 = Vector3.ZERO


## Écoute la vue `view` et modifie les apparitions de `document`, selon les réglages (rayon de prise).
func setup(view: RoomView, document: RoomDocument, settings: EditorSettingsDef) -> void:
	_view = view
	_document = document
	_settings = settings
	view.gui_input.connect(handle)
	document.changed.connect(_forget_missing)


## Le départ du héros à montrer (avec l'aperçu s'il est en cours de déplacement).
func shown_hero() -> Vector3:
	return _preview if _dragging and chosen == HERO else _document.room_value(&"hero_start")


## Les points d'apparition à montrer (avec l'aperçu du point qu'on tire).
func shown_spawns() -> PackedVector3Array:
	var points: PackedVector3Array = _document.room_value(&"spawn_positions")
	if _dragging and chosen >= 0 and chosen < points.size():
		points[chosen] = _preview
	return points


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
		_preview = _world(motion.position)
		overlay_changed.emit()
		done = true
	elif key != null and key.pressed and chosen >= 0:
		if key.keycode == KEY_DELETE:
			done = _remove(chosen)
		elif key.keycode == KEY_R:
			done = _cycle_role(chosen)
	if done:
		_view.accept_event()
	return done


func _on_button(button: InputEventMouseButton) -> bool:
	var point: Vector3 = _world(button.position)
	if not button.pressed:
		if _dragging:
			_dragging = false
			_commit_move(chosen, _preview)
		return true
	var radius: float = _settings.point_pick_px / _view.view_transform.pixels_per_meter()
	if button.ctrl_pressed:
		var points: PackedVector3Array = _document.room_value(&"spawn_positions")
		var roles: PackedStringArray = _document.room_value(&"spawn_roles")
		points.append(point)
		roles.append(NEW_ROLE)
		if _commit({&"spawn_positions": points, &"spawn_roles": roles}):
			chosen = points.size() - 1
		return true
	chosen = -1
	if _flat(shown_hero()).distance_to(_flat(point)) <= radius:
		chosen = HERO
	else:
		var points: PackedVector3Array = shown_spawns()
		for index: int in points.size():
			if _flat(points[index]).distance_to(_flat(point)) <= radius:
				chosen = index
	if chosen != -1:
		_dragging = true
		_preview = shown_hero() if chosen == HERO else shown_spawns()[chosen]
	overlay_changed.emit()
	return true


func _commit_move(index: int, place: Vector3) -> void:
	if index == HERO:
		_commit({&"hero_start": place})
		return
	var points: PackedVector3Array = _document.room_value(&"spawn_positions")
	points[index] = place
	_commit({&"spawn_positions": points})


func _remove(index: int) -> bool:
	var points: PackedVector3Array = _document.room_value(&"spawn_positions")
	var roles: PackedStringArray = _document.room_value(&"spawn_roles")
	points.remove_at(index)
	roles.remove_at(index)
	if _commit({&"spawn_positions": points, &"spawn_roles": roles}):
		chosen = -1
	return true


func _cycle_role(index: int) -> bool:
	var roles: PackedStringArray = _document.room_value(&"spawn_roles")
	var next: int = (RoomData.SPAWN_ROLES.find(roles[index]) + 1) % RoomData.SPAWN_ROLES.size()
	roles[index] = RoomData.SPAWN_ROLES[next]
	_commit({&"spawn_roles": roles})
	return true


func _commit(changes: Dictionary[StringName, Variant]) -> bool:
	var done: bool = _document.set_room_fields(changes)
	if not done:
		refused.emit("; ".join(_document.errors))
	overlay_changed.emit()
	return done


func _forget_missing() -> void:
	if not _document.is_open() or chosen >= (_document.room_value(&"spawn_positions") as PackedVector3Array).size():
		chosen = -1


func _world(screen: Vector2) -> Vector3:
	return _view.view_transform.screen_to_world(screen)


func _flat(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)
