extends PlayerState
## Esquive : un bond très rapide dans la direction de la marche, pendant dash_duration, puis la course reprend.
## La recharge du joueur (DashCooldown) part au début de l'esquive. Le joueur signale l'esquive (dashed) : sa vue
## en joue la traînée et le son.

## L'état de course.
@export var run_state: PlayerState

@onready var _duration: Timer = $DashDuration


## Part dans la direction de la marche, ramenée à une longueur de 1 (un stick à moitié esquive aussi loin), et
## lance l'animation d'esquive.
func enter(_previous_state: StringName) -> void:
	player.start_dash(player.get_movement_direction().normalized())
	_duration.start(player.settings.dash_duration)
	player.animation_tree.change_immediate(&"DodgeForward")


## Esquive jusqu'à la fin de sa durée, puis reprend la course.
func physics_update(_delta: float) -> void:
	if _duration.is_stopped():
		finished.emit(run_state.name)
		return
	player.move_and_slide()
