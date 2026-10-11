extends Node
## Le déroulement : garde la séquence reçue et charge l'étape suivante. Il ne connaît aucune
## étape en particulier : chacune respecte le contrat Step (1_core).
## Entrées : start(sequence, rules), appelé par 2_sequence/boot. Dépend de : Step, Sequence,
## GameRules (1_core), GameState, Trace. Émet : step_started.

signal step_started(index: int, step: Step)

var sequence: Sequence
var rules: GameRules
var index: int = -1
var current_step: Step


func start(new_sequence: Sequence, new_rules: GameRules) -> void:
	if new_sequence == null or new_sequence.steps.is_empty() or new_rules == null:
		push_error("GameFlow.start : séquence vide ou règles absentes")
		return
	for message in new_rules.validate():
		push_error("GameFlow.start : %s" % message)
	sequence = new_sequence
	rules = new_rules
	GameState.reset(rules.start_lives)
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
			start(sequence, rules)
		_:
			next_step()
