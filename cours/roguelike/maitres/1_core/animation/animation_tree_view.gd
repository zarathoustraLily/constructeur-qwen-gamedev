class_name AnimationTreeView extends AnimationTree
## Arbre d'animation d'un personnage : une machine à états d'animation, dont l'état WalkSpace mêle le repos et
## la course (un BlendSpace1D, de -1 au repos à 1 en course). Le personnage donne la cible du mélange
## (blend_target) ; l'arbre s'en approche en douceur, de blend_speed par seconde. change_immediate() lance un
## état d'animation tout de suite (un coup, une esquive), sans attendre une transition. C'est de la
## présentation : un script _view, qui peut se servir de _process.

## Vitesse du mélange repos-course, en unités de mélange par seconde.
@export var blend_speed: float = 6.0
## Le paramètre du mélange repos-course.
@export var blend_parameter: StringName = &"parameters/WalkSpace/blend_position"

## Cible du mélange : -1 au repos, 1 en course.
var blend_target: float = -1.0

@onready var _playback: AnimationNodeStateMachinePlayback = get("parameters/playback")


func _process(delta: float) -> void:
	var current: float = get(blend_parameter)
	set(blend_parameter, move_toward(current, blend_target, delta * blend_speed))


## Passe tout de suite à l'état d'animation `state_name`.
func change_immediate(state_name: StringName) -> void:
	_playback.start(state_name)


## L'état d'animation en cours.
func current_state() -> StringName:
	return _playback.get_current_node()
