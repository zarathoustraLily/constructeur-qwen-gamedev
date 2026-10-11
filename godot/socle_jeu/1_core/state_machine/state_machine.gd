class_name StateMachine
extends Node
## Machine à états générique : ses enfants State sont les états, nommés en minuscules.
## Elle ne connaît aucun acteur en particulier ; le journal (Trace) écoute `state_changed`.

signal state_changed(from: StringName, to: StringName)

@export var initial_state: State

var current: State
var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	for child in get_children():
		var state := child as State
		if state == null:
			continue
		_states[StringName(state.name.to_lower())] = state
		state.actor = get_parent()
		state.transition_requested.connect(transition_to)
	if initial_state == null and not _states.is_empty():
		initial_state = _states.values()[0]
	if initial_state != null:
		current = initial_state
		current.enter()


func _process(delta: float) -> void:
	if current != null:
		current.update(delta)


func _physics_process(delta: float) -> void:
	if current != null:
		current.physics_update(delta)


func transition_to(to: StringName) -> void:
	var next: State = _states.get(StringName(String(to).to_lower()))
	if next == null:
		push_error("StateMachine %s : état inconnu %s" % [get_parent().name, to])
		return
	if next == current:
		return
	var from := current_name()
	if current != null:
		current.exit()
	current = next
	current.enter()
	state_changed.emit(from, current_name())


func current_name() -> StringName:
	return StringName(current.name.to_lower()) if current != null else &""
