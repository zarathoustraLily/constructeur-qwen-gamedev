extends Node
## Le chef d'orchestre : lit la séquence (2_sequence/sequence.tres) et charge l'étape suivante.
## Il ne connaît aucune étape en particulier : chacune respecte le contrat Step.

const SEQUENCE_PATH := "res://2_sequence/sequence.tres"

signal step_started(index: int, step: Step)

var sequence: Sequence
var index: int = -1
var current_step: Step


func _ready() -> void:
	sequence = load(SEQUENCE_PATH) as Sequence


func start() -> void:
	GameState.reset()
	goto(0)


func next_step() -> void:
	goto(index + 1 if index + 1 < sequence.steps.size() else 0)


func goto(new_index: int) -> void:
	index = new_index
	var step := sequence.steps[index].instantiate() as Step
	var tree := get_tree()
	var previous := tree.current_scene
	tree.root.add_child(step)
	tree.current_scene = step
	if previous != null:
		previous.queue_free()
	current_step = step
	step.finished.connect(_on_step_finished, CONNECT_ONE_SHOT)
	Trace.event(self, "étape %d : %s" % [index, step.name])
	step_started.emit(index, step)


func _on_step_finished(outcome: StringName) -> void:
	match outcome:
		&"retry":
			goto(index)
		&"restart":
			start()
		_:
			next_step()
