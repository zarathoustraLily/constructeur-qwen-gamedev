class_name RoomViewInput
extends Node
## Les gestes de la souris sur la vue de dessus, traduits en commandes de cadrage : glisser avec le bouton du milieu
## déplace la vue, la molette zoome autour du curseur. Le script écoute le signal `gui_input` de la vue : il reçoit
## les événements qui la visent, sans lire l'état global des appareils. La vue, elle, ne fait que dessiner.

var _transform: ViewTransform
var _settings: EditorSettingsDef
var _panning: bool = false


## Écoute la vue `view` et commande son cadrage `transform`, selon les réglages (cran de molette).
func setup(view: Control, transform: ViewTransform, settings: EditorSettingsDef) -> void:
	_transform = transform
	_settings = settings
	view.gui_input.connect(handle)


## Traduit l'événement `event` ; rend true s'il a servi.
func handle(event: InputEvent) -> bool:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = button.pressed
			return true
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_transform.zoom_at(button.position, _settings.zoom_step)
			return true
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_transform.zoom_at(button.position, 1.0 / _settings.zoom_step)
			return true
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _panning:
		_transform.pan(motion.relative)
		return true
	return false
