class_name StateMachine extends Node
## Une machine à états : ses enfants State sont ses états, un seul est actif à la fois. Elle entre dans l'état
## initial au départ, passe d'un état à l'autre sur demande (transition_to) ou quand l'état actif émet `finished`,
## et ne fait tourner que l'état actif.

## La machine est passée de l'état `from` à l'état `to`.
signal state_changed(from: StringName, to: StringName)

## L'état actif au départ.
@export var initial_state: State

## L'état actif.
var current: State

var _states: Dictionary[StringName, State] = {}


func _ready() -> void:
	process_physics_priority = ProcessOrder.ENTITIES
	for child: Node in get_children():
		var state: State = child as State
		if state != null:
			_states[state.name] = state
			state.finished.connect(transition_to)
	current = initial_state
	current.enter(&"")


func _physics_process(delta: float) -> void:
	current.physics_update(delta)


## Passe à l'état `state_name` : l'état actif sort, le nouveau entre, `state_changed` part. Rend faux, sans rien
## changer, si l'état n'existe pas ou s'il est déjà actif.
func transition_to(state_name: StringName) -> bool:
	if not _states.has(state_name) or current.name == state_name:
		return false
	var previous: StringName = current.name
	current.exit()
	current = _states[state_name]
	current.enter(previous)
	state_changed.emit(previous, state_name)
	return true


## Les noms des états de la machine.
func state_names() -> Array[StringName]:
	var names: Array[StringName] = []
	names.assign(_states.keys())
	return names
