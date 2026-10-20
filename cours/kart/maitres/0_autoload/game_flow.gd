extends Node
## Le chef d'orchestre (singleton GameFlow) : c'est lui, et lui seul, qui charge les scènes du jeu. Il garde la
## séquence reçue (start(), appelé par la scène de démarrage 2_sequence/boot.tscn) et charge ses étapes dans
## l'ordre ; après la dernière, il revient à la première. Il ne connaît aucune étape en particulier : chacune
## respecte le contrat Step (1_core/step/step.gd) et émet « finished », qu'il écoute. L'interface posée par-
## dessus le jeu (la pause) appelle quit().

## Émis quand une étape vient d'être chargée.
signal step_started(index: int, step: Step)

## La séquence jouée.
var sequence: Sequence
## Rang de l'étape en cours, ou -1 avant le départ.
var index: int = -1
## L'étape en cours.
var current_step: Step


## Reçoit la séquence du jeu et charge sa première étape.
func start(new_sequence: Sequence) -> void:
	if new_sequence == null or new_sequence.steps.is_empty():
		push_error("GameFlow.start : séquence vide")
		return
	sequence = new_sequence
	goto(0)


## Charge l'étape suivante ; après la dernière, la première.
func next_step() -> void:
	goto(index + 1 if index + 1 < sequence.steps.size() else 0)


## Charge l'étape de rang `new_index` : elle remplace la scène courante.
func goto(new_index: int) -> void:
	index = new_index
	var step := sequence.steps[index].instantiate() as Step
	if step == null:
		push_error("GameFlow.goto : l'étape %d ne respecte pas le contrat Step" % index)
		return
	var tree := get_tree()
	var previous := tree.current_scene
	if previous != null:
		# Retirée de l'arbre d'abord : une étape rejouée garde son nom, au lieu d'être renommée à côté de l'ancienne.
		previous.get_parent().remove_child(previous)
		previous.queue_free()
	tree.root.add_child(step)
	tree.current_scene = step
	current_step = step
	step.finished.connect(_on_step_finished, CONNECT_ONE_SHOT)
	step_started.emit(index, step)


## Quitte le jeu.
func quit() -> void:
	get_tree().quit()


func _on_step_finished(outcome: StringName) -> void:
	match outcome:
		&"retry":
			goto(index)
		&"restart":
			goto(0)
		_:
			next_step()
