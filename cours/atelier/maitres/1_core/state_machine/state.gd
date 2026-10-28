class_name State extends Node
## Un état d'une machine à états (StateMachine) : il fait ce qu'il a à faire tant qu'il est actif, et demande le
## suivant par `finish` (signal `finished`). Les états concrets redéfinissent enter, exit et physics_update.

## L'état a fini : la machine passe à l'état nommé `next`.
signal finished(next: StringName)


## Appelé quand la machine entre dans cet état ; `previous` : le nom de l'état quitté (vide au départ).
func enter(_previous: StringName) -> void:
	pass


## Appelé quand la machine quitte cet état.
func exit() -> void:
	pass


## Appelé à chaque image de physique tant que l'état est actif.
func physics_update(_delta: float) -> void:
	pass


## Demande à la machine de passer à l'état `next`.
func finish(next: StringName) -> void:
	finished.emit(next)
