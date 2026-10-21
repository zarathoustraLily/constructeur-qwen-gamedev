extends PlayerState
## Course (et repos) : le joueur marche selon ses commandes ; sans sol sous les pieds, il tombe.

## L'état de chute.
@export var fall_state: PlayerState


## Sans sol, passe à la chute ; sinon, marche selon les commandes.
func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		finished.emit(fall_state.name)
		return
	core_movement(delta, player.settings.movement_speed)
	player.move_and_slide()
