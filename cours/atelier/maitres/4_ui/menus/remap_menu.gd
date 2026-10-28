class_name RemapMenu extends Control
## Le menu des commandes : une ligne par action remappable, avec son bouton actuel. Choisir une ligne (A) la met en
## écoute ; le prochain bouton de manette pressé devient le sien. Si une autre action l'avait, les deux échangent
## leurs boutons : aucune action ne reste sans bouton. B ou Échap annule l'écoute, ou ferme le menu.

## L'action `action` a reçu le bouton `button`.
signal rebound(action: StringName, button: JoyButton)
## Le joueur ferme le menu.
signal closed

## Les actions remappables et leurs noms.
@export var settings: GamepadSettings

## L'action en écoute ; vide quand aucune ne l'est.
var listening: StringName = &""

var _buttons: Dictionary[StringName, Button] = {}

@onready var _rows: VBoxContainer = $Center/Rows


func _ready() -> void:
	build_rows()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if is_listening():
		var joy: InputEventJoypadButton = event as InputEventJoypadButton
		if joy != null and joy.pressed:
			get_viewport().set_input_as_handled()
			apply(listening, joy.button_index)
		elif event.is_action_pressed(&"ui_cancel"):
			get_viewport().set_input_as_handled()
			stop_listening()
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


## Crée une ligne par action remappable (son nom, puis un bouton qui montre son bouton de manette) et relie le
## focus de haut en bas.
func build_rows() -> void:
	var focusables: Array[Control] = []
	for action: StringName in settings.remappable_actions:
		var row: HBoxContainer = HBoxContainer.new()
		var title: Label = Label.new()
		title.text = settings.action_names.get(action, String(action))
		title.custom_minimum_size = Vector2(160, 0)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(160, 0)
		button.pressed.connect(start_listening.bind(action))
		row.add_child(title)
		row.add_child(button)
		_rows.add_child(row)
		_buttons[action] = button
		focusables.append(button)
	MenuFocus.chain(focusables, true)
	refresh()


## Met l'action `action` en écoute du prochain bouton de manette.
func start_listening(action: StringName) -> void:
	listening = action
	refresh()


## Arrête l'écoute sans rien changer.
func stop_listening() -> void:
	listening = &""
	refresh()


## Vrai si une action attend son nouveau bouton.
func is_listening() -> bool:
	return listening != &""


## Donne `button` à `action` ; l'action qui l'avait reçoit l'ancien bouton de `action`. Arrête l'écoute.
func apply(action: StringName, button: JoyButton) -> void:
	var previous: Array[JoyButton] = ActionRemap.joypad_buttons(action)
	for other: StringName in ActionRemap.conflicts(button, settings.remappable_actions, action):
		if not previous.is_empty():
			ActionRemap.rebind(other, previous[0])
			rebound.emit(other, previous[0])
	ActionRemap.rebind(action, button)
	rebound.emit(action, button)
	stop_listening()


## Montre le bouton actuel de chaque action ; celle en écoute affiche « Appuyez sur un bouton… ».
func refresh() -> void:
	for action: StringName in _buttons:
		var buttons: Array[JoyButton] = ActionRemap.joypad_buttons(action)
		var text: String = ActionRemap.label(buttons[0]) if not buttons.is_empty() else "—"
		_buttons[action].text = "Appuyez sur un bouton…" if action == listening else text


## Montre le menu, le focus sur la première ligne.
func open() -> void:
	show()
	stop_listening()
	var rows: Array[Control] = []
	for button: Button in _buttons.values():
		rows.append(button)
	var first: Control = MenuFocus.first_focusable(rows)
	if first != null:
		first.grab_focus()
