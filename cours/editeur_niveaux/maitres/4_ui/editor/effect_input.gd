class_name EffectInput
extends Node
## La souris et le clavier sur la vue en mode « Effets » : tirer un effet placé le déplace (aperçu, puis un seul pas au
## relâchement) ; Ctrl+clic place l'effet choisi dans le panneau (`current_fx`) ; Suppr retire l'effet choisi.
## Le script écoute `gui_input` de la vue, et ne fait rien quand il n'est pas `active`.

## L'effet choisi ou l'aperçu viennent de changer : le calque des effets doit se redessiner.
signal overlay_changed
## Une modification a été refusée, pour la raison `reason`.
signal refused(reason: String)

## Vrai en mode « Effets » ; sinon, le script laisse passer tous les événements.
var active: bool = false
## L'effet que Ctrl+clic place.
var current_fx: StringName = &""
## L'indice de l'effet placé choisi (-1 : aucun).
var chosen: int = -1
var _view: RoomView
var _document: RoomDocument
var _settings: EditorSettingsDef
var _dragging: bool = false
var _preview: Vector3 = Vector3.ZERO


## Écoute la vue `view` et modifie les effets placés de `document`, selon les réglages (rayon de prise).
func setup(view: RoomView, document: RoomDocument, settings: EditorSettingsDef) -> void:
	_view = view
	_document = document
	_settings = settings
	view.gui_input.connect(handle)
	document.changed.connect(_forget_missing)


## Les positions des effets placés à montrer (avec l'aperçu de celui qu'on tire).
func shown_positions() -> PackedVector3Array:
	var points: PackedVector3Array = _document.room_value(&"effect_positions")
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
		_preview = _view.view_transform.screen_to_world(motion.position)
		overlay_changed.emit()
		done = true
	elif key != null and key.pressed and key.keycode == KEY_DELETE and chosen >= 0:
		var ids: PackedStringArray = _document.room_value(&"effect_ids")
		var points: PackedVector3Array = _document.room_value(&"effect_positions")
		ids.remove_at(chosen)
		points.remove_at(chosen)
		if _commit({&"effect_ids": ids, &"effect_positions": points}):
			chosen = -1
		done = true
	if done:
		_view.accept_event()
	return done


func _on_button(button: InputEventMouseButton) -> bool:
	var point: Vector3 = _view.view_transform.screen_to_world(button.position)
	if not button.pressed:
		if _dragging:
			_dragging = false
			var moved: PackedVector3Array = _document.room_value(&"effect_positions")
			moved[chosen] = _preview
			_commit({&"effect_positions": moved})
		return true
	var points: PackedVector3Array = _document.room_value(&"effect_positions")
	if button.ctrl_pressed:
		if String(current_fx).is_empty():
			refused.emit("Choisir d'abord un effet dans la liste")
			return true
		var ids: PackedStringArray = _document.room_value(&"effect_ids")
		ids.append(String(current_fx))
		points.append(point)
		if _commit({&"effect_ids": ids, &"effect_positions": points}):
			chosen = points.size() - 1
		return true
	var radius: float = _settings.point_pick_px / _view.view_transform.pixels_per_meter()
	chosen = -1
	for index: int in points.size():
		if Vector2(points[index].x, points[index].z).distance_to(Vector2(point.x, point.z)) <= radius:
			chosen = index
	if chosen >= 0:
		_dragging = true
		_preview = points[chosen]
	overlay_changed.emit()
	return true


func _commit(changes: Dictionary[StringName, Variant]) -> bool:
	var done: bool = _document.set_room_fields(changes)
	if not done:
		refused.emit("; ".join(_document.errors))
	overlay_changed.emit()
	return done


func _forget_missing() -> void:
	if not _document.is_open() or chosen >= (_document.room_value(&"effect_ids") as PackedStringArray).size():
		chosen = -1
