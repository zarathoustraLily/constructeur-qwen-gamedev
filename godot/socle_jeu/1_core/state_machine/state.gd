class_name State
extends Node
## Un état d'une machine à états. Chaque comportement (attente, poursuite, dash…) est un nœud
## enfant de la StateMachine, avec son propre script.

## Demande un changement d'état (nom du nœud de l'état visé, en minuscules).
signal transition_requested(to: StringName)

## Le nœud piloté (le parent de la StateMachine), posé par la machine.
var actor: Node


func enter() -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
