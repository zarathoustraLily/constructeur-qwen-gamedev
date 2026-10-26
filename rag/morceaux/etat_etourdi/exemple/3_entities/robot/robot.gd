class_name Robot
extends Node3D
## Le robot (simulation). Comportements : états (states/). Réglages : 5_data/actors/robot.tres.
## Entrées : take_hit(). Émet : stunned.

## Émis quand un coup l'étourdit ; sa vue (robot_view.gd) l'écoute pour le montrer.
signal stunned

@export var stats: RobotStats

@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	if stats == null:
		push_error("Robot : stats n'est pas posé dans la scène")
		return
	for message in stats.validate():
		push_error("Robot : %s" % message)


## Un coup reçu : appeler vers le bas (la machine), signaler vers le haut (stunned).
func take_hit() -> void:
	state_machine.transition_to(&"stunned")
	stunned.emit()
