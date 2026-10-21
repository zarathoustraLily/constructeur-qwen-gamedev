extends Node
## Scène de démarrage : elle donne au chef d'orchestre (GameFlow) la séquence du jeu, posée dans boot.tscn. Elle
## ne charge aucune scène elle-même : GameFlow charge la première étape, puis toutes les suivantes.

## La séquence du jeu (2_sequence/sequence.tres).
@export var sequence: Sequence


func _ready() -> void:
	if sequence == null:
		push_error("Boot : la séquence (sequence) n'est pas posée dans boot.tscn")
		return
	# La scène de démarrage est encore en train d'entrer dans l'arbre : le chargement attend la fin de l'image.
	GameFlow.start.call_deferred(sequence)
