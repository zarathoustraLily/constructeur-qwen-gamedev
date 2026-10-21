class_name StateMachine extends Node
## Machine à états : ses enfants sont des State, et un seul est actif. Elle lui donne chaque image physique,
## et change d'état quand l'état actif émet finished. Elle entre dans initial_state (à défaut, son premier
## enfant) quand son propriétaire est prêt. Elle ne connaît aucun acteur : chaque état connaît le sien.

## Émis à chaque changement d'état, avec le nom de l'état quitté et celui de l'état atteint.
signal state_changed(from: StringName, to: StringName)

## État de départ ; à défaut, le premier enfant.
@export var initial_state: State

## L'état actif.
var state: State


func _ready() -> void:
	for child: Node in get_children():
		var child_state := child as State
		if child_state != null:
			child_state.finished.connect(transition_to)
	state = initial_state
	if state == null and get_child_count() > 0:
		state = get_child(0) as State
	if state == null:
		push_error("StateMachine %s : aucun état" % name)
		set_physics_process(false)
		return
	# Les états se servent de leur acteur : on attend qu'il soit prêt (il l'est après ses enfants).
	if owner != null and not owner.is_node_ready():
		await owner.ready
	state.enter(&"")


func _physics_process(delta: float) -> void:
	state.physics_update(delta)


## Passe à l'état nommé `target` (un nœud enfant) : sortie de l'état actif, entrée dans le nouveau. Un nom
## inconnu ne change rien et le signale.
func transition_to(target: StringName) -> void:
	var next := get_node_or_null(NodePath(target)) as State
	if next == null:
		push_error("StateMachine %s : état inconnu « %s »" % [name, target])
		return
	var previous := state.name
	state.exit()
	state = next
	state.enter(previous)
	state_changed.emit(previous, state.name)
