extends PlayerState
## Chute : le joueur garde la main sur sa marche et tombe ; au sol, il reprend sa course.

## L'état de course.
@export var run_state: PlayerState


## Au sol, reprend la course ; sinon, marche selon les commandes et tombe.
func physics_update(delta: float) -> void:
	if player.is_on_floor():
		finished.emit(run_state.name)
		return
	core_movement(delta, player.settings.movement_speed)
	# Comme dans le jeu d'origine, la gravité (9,8 m/s²) sert de vitesse de chute : on tombe à vitesse
	# constante, sans accélérer.
	player.velocity += player.get_gravity()
	player.move_and_slide()
