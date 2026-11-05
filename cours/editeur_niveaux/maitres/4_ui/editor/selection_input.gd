class_name SelectionInput
extends Node
## Le bouton gauche de la souris et les touches de profondeur, sur la vue de dessus, traduits en sélection et en gestes.
## - Clic : sélectionne la chose la plus haute sous la souris (Maj : l'ajoute ou la retire) ; clic dans le vide : vide
##   la sélection.
## - Glisser dans le vide : un rectangle de sélection.
## - Glisser le cadre bleu : l'intérieur déplace, une poignée d'angle agrandit, la poignée ronde fait tourner ; Ctrl
##   aimante. Pendant le glisser, la vue montre un aperçu ; au relâchement, un seul geste est confié à `EditorActions`.
## - Page haut / Page bas : avance ou recule la sélection d'un rang (avec Ctrl : devant ou derrière tout le calque).
## Le script écoute le signal `gui_input` de la vue : il ne lit pas l'état global des appareils.

## Le cadre, ses poignées ou le rectangle de sélection viennent de changer : le calque de dessin doit se redessiner.
signal overlay_changed

## Ce que fait le bouton gauche en ce moment : rien, un clic encore indécis, le glisser du cadre, un rectangle.
enum Mode { IDLE, PENDING_CLICK, DRAG_GIZMO, BAND }

## Le cadre bleu de la sélection, et ses poignées.
var gizmo: TransformGizmo = TransformGizmo.new()
## Le rectangle de sélection en cours, à l'écran (vide hors d'un glisser dans le vide).
var band: Rect2 = Rect2()
#@ 10+
## Vrai en mode « Choses » ; sinon, le script laisse passer tous les événements.
var active: bool = true
#@ all
var _view: RoomView
var _document: RoomDocument
var _selection: SelectionModel
var _actions: EditorActions
var _settings: EditorSettingsDef
var _mode: Mode = Mode.IDLE
var _press: Vector2 = Vector2.ZERO
var _shift: bool = false


## Écoute la vue `view` ; agit sur `selection` et, par `actions`, sur le document `document`.
func setup(view: RoomView, document: RoomDocument, selection: SelectionModel, actions: EditorActions,
		settings: EditorSettingsDef) -> void:
	_view = view
	_document = document
	_selection = selection
	_actions = actions
	_settings = settings
	gizmo.setup(settings)
	# Les touches de profondeur n'arrivent qu'à une vue qui a le focus ; et grab_focus() sur une vue qui ne peut pas
	# le prendre écrirait un avertissement à chaque clic.
	view.focus_mode = Control.FOCUS_ALL
	view.gui_input.connect(handle)
	selection.changed.connect(refresh)
	document.changed.connect(refresh)
	view.view_transform.changed.connect(refresh)


## Recalcule le cadre bleu autour de la sélection (en tenant compte de l'aperçu en cours).
func refresh() -> void:
	gizmo.box = _view.selection_rect(_selection.ids())
	overlay_changed.emit()


## Traduit l'événement `event` ; rend true s'il a servi.
func handle(event: InputEvent) -> bool:
#@ 10+
	if not active:
		return false
#@ all
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_press_at(button.position, button.shift_pressed)
		else:
			_release_at(button.position, button.ctrl_pressed)
		return true
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _mode != Mode.IDLE:
		_drag_to(motion.position)
		return true
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not _selection.is_empty():
		if key.keycode == KEY_PAGEUP or key.keycode == KEY_PAGEDOWN:
			var forward: bool = key.keycode == KEY_PAGEUP
			if key.ctrl_pressed:
				_actions.to_extreme_depth(_selection.ids(), forward)
			else:
				_actions.shift_depth(_selection.ids(), 1 if forward else -1)
			return true
	return false


func _press_at(point: Vector2, shift: bool) -> void:
	_view.grab_focus()
	_press = point
	_shift = shift
	var handle_under: TransformGizmo.Handle = gizmo.hit_test(point)
	if handle_under != TransformGizmo.Handle.NONE and not shift:
		gizmo.begin(handle_under, point)
		_mode = Mode.DRAG_GIZMO
	else:
		_mode = Mode.PENDING_CLICK


func _drag_to(point: Vector2) -> void:
	var far: bool = point.distance_to(_press) > _settings.drag_threshold_px
	if _mode == Mode.DRAG_GIZMO and far:
		_view.set_preview(_preview_for(point))
		refresh()
	elif _mode == Mode.PENDING_CLICK and far:
		_mode = Mode.BAND
	if _mode == Mode.BAND:
		band = Rect2(_press, Vector2.ZERO).expand(point)
		overlay_changed.emit()


func _release_at(point: Vector2, snap: bool) -> void:
	var far: bool = point.distance_to(_press) > _settings.drag_threshold_px
	if _mode == Mode.DRAG_GIZMO and far:
		_commit(point, snap)
	elif _mode == Mode.BAND:
		var inside: Array[int] = _view.things_in(band)
		if _shift:
			inside.append_array(_selection.ids())
		_selection.replace(inside)
	else:
		_click(point)
	gizmo.finish()
	_view.clear_preview()
	band = Rect2()
	_mode = Mode.IDLE
	refresh()


func _click(point: Vector2) -> void:
	var picked: int = _view.thing_at(point)
	if _shift:
		if picked != 0:
			_selection.toggle(picked)
	elif picked == 0:
		_selection.clear()
	else:
		_selection.replace([picked])


# Le geste en cours, en aperçu : ce que deviendrait la sélection si l'on relâchait la souris en `point`.
func _preview_for(point: Vector2) -> Dictionary:
	var ids: Array[int] = _selection.ids()
	var preview: Dictionary = {&"ids": ids, &"move": Vector3.ZERO, &"angle": 0.0, &"factor": 1.0,
			&"pivot": _actions.center_of(ids)}
	match gizmo.dragging():
		TransformGizmo.Handle.BODY:
			preview[&"move"] = _world_delta(point)
		TransformGizmo.Handle.ROTATE:
			preview[&"angle"] = gizmo.angle_to(point)
		TransformGizmo.Handle.NONE:
			pass
		_:
			preview[&"factor"] = gizmo.factor_to(point)
	return preview


func _commit(point: Vector2, snap: bool) -> void:
	var ids: Array[int] = _selection.ids()
	match gizmo.dragging():
		TransformGizmo.Handle.BODY:
			_actions.move(ids, _world_delta(point), snap)
		TransformGizmo.Handle.ROTATE:
			_actions.rotate(ids, gizmo.angle_to(point), snap)
		TransformGizmo.Handle.NONE:
			pass
		_:
			_actions.scale_by(ids, gizmo.factor_to(point))


func _world_delta(point: Vector2) -> Vector3:
	return _view.view_transform.screen_to_world(point) - _view.view_transform.screen_to_world(gizmo.start())
