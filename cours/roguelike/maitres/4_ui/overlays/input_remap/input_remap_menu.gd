class_name InputRemapMenu extends PanelContainer
## Le menu des contrôles : une ligne par action (settings), avec ses liaisons au clavier et à la souris, puis à la
## manette. Choisir un bouton d'une ligne attend la nouvelle entrée de cet appareil : une touche ou un bouton de
## souris, ou un bouton, un stick ou une gâchette de la manette. Pendant l'attente, le menu garde toutes les
## entrées pour lui ; la pause (Échap, Start) l'annule, et ne se lie donc jamais. Chaque liaison est sauvegardée
## aussitôt ; une entrée déjà liée à une autre action est signalée. Hors de l'attente, B ou Échap ferme le menu.
## L'interface ne connaît pas les données (règle des dossiers) : celui qui pose le menu lui donne ses réglages
## (setup).

## Émis quand le menu se ferme.
signal closed

## Une ligne du menu (binding_row.tscn).
@export var row_scene: PackedScene

## Les actions à lier et le fichier de sauvegarde, donnés par setup().
var settings: BindingSettings

var _capture_action: StringName = &""
var _capture_device: InputBindings.Device = InputBindings.Device.NONE
var _held_axis: JoyAxis = JOY_AXIS_INVALID

@onready var _rows: VBoxContainer = $VBoxContainer/Rows
@onready var _status: Label = $VBoxContainer/Status
@onready var _reset: Button = $VBoxContainer/Buttons/Reset
@onready var _back: Button = $VBoxContainer/Buttons/Back


func _ready() -> void:
	_reset.pressed.connect(_on_reset_pressed)
	_back.pressed.connect(close)


## Pose une ligne par action de `new_settings`, qui donne aussi le fichier de sauvegarde.
func setup(new_settings: BindingSettings) -> void:
	if new_settings == null or row_scene == null:
		push_error("InputRemapMenu : une dépendance manque (réglages des liaisons, row_scene)")
		return
	settings = new_settings
	for action: StringName in settings.actions():
		var row := row_scene.instantiate() as BindingRow
		_rows.add_child(row)
		row.show_action(action, settings.titles[action])
		row.capture_requested.connect(_on_capture_requested)


## Montre le menu avec les liaisons actuelles, le focus sur la première ligne.
func open() -> void:
	show()
	_refresh()
	_status.text = "Choisir une liaison, puis appuyer sur la nouvelle touche ou le nouveau bouton."
	(_rows.get_child(0) as BindingRow).keyboard.grab_focus()


## Cache le menu ; une attente en cours est annulée.
func close() -> void:
	_capture_action = &""
	_capture_device = InputBindings.Device.NONE
	hide()
	closed.emit()


## Vrai pendant l'attente d'une nouvelle liaison.
func is_capturing() -> bool:
	return _capture_action != &""


## La ligne de `action`, ou null.
func row_of(action: StringName) -> BindingRow:
	for row: Node in _rows.get_children():
		if (row as BindingRow).action == action:
			return row as BindingRow
	return null


# Le menu est un enfant du menu de pause : il reçoit chaque entrée avant lui, et la garde quand il s'en sert.
# Caché avec le menu de pause, il ne garde plus rien.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if _swallow_held_axis(event):
		get_viewport().set_input_as_handled()
	elif is_capturing():
		get_viewport().set_input_as_handled()
		_capture(event)
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _capture(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_end_capture("Annulé : la liaison n'a pas changé.")
		return
	var binding := InputBindings.binding_from(event, _capture_device)
	if binding == null:
		return
	var motion := binding as InputEventJoypadMotion
	if motion != null:
		_held_axis = motion.axis
	InputBindings.bind(_capture_action, binding)
	var message := "%s : %s." % [settings.titles[_capture_action], BindingNames.of(binding)]
	var others := PackedStringArray()
	for other: StringName in settings.actions():
		if other != _capture_action and InputMap.action_has_event(other, binding):
			others.append(settings.titles[other])
	if not others.is_empty():
		message += " Attention, aussi lié à : %s." % ", ".join(others)
	if InputBindings.save_to(settings.save_path, settings.actions()) != OK:
		message += " La sauvegarde a échoué : la liaison ne durera que cette partie."
	_end_capture(message)


func _end_capture(message: String) -> void:
	var button := row_of(_capture_action).button_for(_capture_device)
	_capture_action = &""
	_capture_device = InputBindings.Device.NONE
	_refresh()
	_status.text = message
	button.grab_focus()


# Un stick qu'on vient de lier envoie encore des mouvements en revenant au repos : jusque-là, ils ne déplacent
# pas le focus.
func _swallow_held_axis(event: InputEvent) -> bool:
	var motion := event as InputEventJoypadMotion
	if _held_axis == JOY_AXIS_INVALID or motion == null or motion.axis != _held_axis:
		return false
	if absf(motion.axis_value) < InputBindings.AXIS_RELEASE:
		_held_axis = JOY_AXIS_INVALID
	return true


func _refresh() -> void:
	for row: Node in _rows.get_children():
		(row as BindingRow).refresh()


func _on_capture_requested(action: StringName, device: InputBindings.Device) -> void:
	_capture_action = action
	_capture_device = device
	row_of(action).button_for(device).text = "…"
	if device == InputBindings.Device.PAD:
		_status.text = "Appuyer sur un bouton de la manette, ou pousser un stick ou une gâchette (Start : annuler)."
	else:
		_status.text = "Appuyer sur une touche ou un bouton de la souris (Échap : annuler)."


func _on_reset_pressed() -> void:
	InputBindings.reset(settings.save_path)
	_refresh()
	_status.text = "Liaisons du jeu remises."
