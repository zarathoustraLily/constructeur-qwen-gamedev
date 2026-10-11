extends Node
## Scène de démarrage : donne au déroulement (GameFlow) la séquence et les règles de la partie.
## Dépend de : sequence et rules, posés dans boot.tscn.

@export var sequence: Sequence
@export var rules: GameRules


func _ready() -> void:
	if sequence == null or rules == null:
		push_error("Boot : sequence ou rules n'est pas posé dans boot.tscn")
		return
	GameFlow.start.call_deferred(sequence, rules)
