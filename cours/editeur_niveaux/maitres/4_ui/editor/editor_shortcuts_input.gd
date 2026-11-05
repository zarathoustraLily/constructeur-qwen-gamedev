class_name EditorShortcutsInput
extends Node
## Les raccourcis clavier de l'éditeur, traduits en commandes : Ctrl+Z annule ; Ctrl+Y ou Ctrl+Maj+Z refait ; Suppr
## supprime la sélection ; Ctrl+D la duplique et sélectionne les doubles ; les flèches la déplacent d'un pas de grille
## (avec Maj : de quatre pas). Les touches qu'aucun champ de saisie n'a prises arrivent ici
## (`_unhandled_key_input`) : taper un nom dans l'inspecteur ne supprime rien.
#@ 9+
## Ctrl+S demande l'enregistrement : la coquille s'en charge, après validation.

## Ctrl+S vient d'être pressé.
signal save_requested
#@ all

## Le nombre de pas de grille d'un déplacement aux flèches avec Maj.
const FAST_STEPS: float = 4.0

var _document: RoomDocument
var _selection: SelectionModel
var _actions: EditorActions
var _settings: EditorSettingsDef


## Branche les raccourcis sur `document`, `selection` et `actions`, avec le pas de grille des réglages.
func setup(document: RoomDocument, selection: SelectionModel, actions: EditorActions,
		settings: EditorSettingsDef) -> void:
	_document = document
	_selection = selection
	_actions = actions
	_settings = settings


func _unhandled_key_input(event: InputEvent) -> void:
	if handle(event):
		get_viewport().set_input_as_handled()


## Traduit l'événement `event` ; rend true s'il a servi.
func handle(event: InputEvent) -> bool:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or _document == null:
		return false
	var ctrl: bool = key.ctrl_pressed or key.meta_pressed
	if ctrl and key.keycode == KEY_Z and not key.shift_pressed:
		return _document.undo()
	if ctrl and (key.keycode == KEY_Y or (key.keycode == KEY_Z and key.shift_pressed)):
		return _document.redo()
#@ 9+
	if ctrl and key.keycode == KEY_S:
		save_requested.emit()
		return true
#@ all
	if _selection.is_empty():
		return false
	var ids: Array[int] = _selection.ids()
	if key.keycode == KEY_DELETE:
		return _actions.delete(ids)
	if ctrl and key.keycode == KEY_D:
		var copies: Array[int] = _actions.duplicate(ids)
		_selection.replace(copies)
		return not copies.is_empty()
	var direction: Vector3 = Vector3.ZERO
	match key.keycode:
		KEY_LEFT:
			direction = Vector3.LEFT
		KEY_RIGHT:
			direction = Vector3.RIGHT
		KEY_UP:
			direction = Vector3.FORWARD
		KEY_DOWN:
			direction = Vector3.BACK
		_:
			return false
	var step: float = _settings.snap_m * (FAST_STEPS if key.shift_pressed else 1.0)
	return _actions.move(ids, direction * step)
