class_name SavesView extends Control
## La vue des sauvegardes : trois panneaux, dont un seul se voit à la fois. La liste des emplacements ; les actions de
## l'emplacement choisi ; la question avant d'effacer, avec « Non » mis en avant. Elle ne décide rien : l'écran lui
## dit quoi montrer, et elle lui dit ce que le joueur a validé.

## Un emplacement vient d'être validé.
signal slot_chosen(slot: int)
## Une action vient d'être validée.
signal action_chosen(action: StringName)
## La confirmation vient d'être répondue (`yes` : effacer).
signal confirm_chosen(yes: bool)

var _slot_buttons: Array[Button] = []
var _action_buttons: Dictionary[StringName, Button] = {}

@onready var _title: Label = $Titre
@onready var _slots_box: VBoxContainer = $Emplacements
@onready var _actions_box: VBoxContainer = $Actions
@onready var _confirm_box: VBoxContainer = $Confirmation
@onready var _question: Label = $Confirmation/Question
@onready var _yes: Button = $Confirmation/Choix/Oui
@onready var _no: Button = $Confirmation/Choix/Non


## Construit le titre et un bouton par emplacement.
func setup(title: String, slot_count: int) -> void:
	_title.text = title
	for slot: int in slot_count:
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void: slot_chosen.emit(slot))
		_slots_box.add_child(button)
		_slot_buttons.append(button)
	var column: Array[Control] = []
	column.assign(_slot_buttons)
	FocusChain.link_column(column)
	_yes.focus_neighbor_right = _yes.get_path_to(_no)
	_no.focus_neighbor_left = _no.get_path_to(_yes)
	_yes.pressed.connect(func() -> void: confirm_chosen.emit(true))
	_no.pressed.connect(func() -> void: confirm_chosen.emit(false))


## Montre la liste, avec le texte de chaque emplacement, et met `focus_slot` en avant.
func show_slots(texts: Array[String], focus_slot: int) -> void:
	for slot: int in texts.size():
		_slot_buttons[slot].text = texts[slot]
	_show_panel(_slots_box)
	_slot_buttons[focus_slot].grab_focus()


## Montre les actions `actions`, avec leurs textes ; la première a le focus.
func show_actions(actions: Array[StringName], labels: Dictionary[StringName, String]) -> void:
	for button: Button in _action_buttons.values():
		_actions_box.remove_child(button)
		button.queue_free()
	_action_buttons.clear()
	var column: Array[Control] = []
	for action: StringName in actions:
		var button := Button.new()
		button.text = labels[action]
		button.pressed.connect(func() -> void: action_chosen.emit(action))
		_actions_box.add_child(button)
		_action_buttons[action] = button
		column.append(button)
	FocusChain.link_column(column)
	_show_panel(_actions_box)
	_action_buttons[actions[0]].grab_focus()


## Montre la question avant d'effacer ; « Non » a le focus.
func show_confirm(question: String, yes_text: String, no_text: String) -> void:
	_question.text = question
	_yes.text = yes_text
	_no.text = no_text
	_show_panel(_confirm_box)
	_no.grab_focus()


## Le panneau visible : &"emplacements", &"actions" ou &"confirmation".
func visible_panel() -> StringName:
	if _actions_box.visible:
		return &"actions"
	if _confirm_box.visible:
		return &"confirmation"
	return &"emplacements"


## Le texte montré par l'emplacement `slot`.
func slot_text(slot: int) -> String:
	return _slot_buttons[slot].text


## Les actions montrées, dans l'ordre.
func shown_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	actions.assign(_action_buttons.keys())
	return actions


func _show_panel(panel: Control) -> void:
	for box: Control in [_slots_box, _actions_box, _confirm_box]:
		box.visible = box == panel
