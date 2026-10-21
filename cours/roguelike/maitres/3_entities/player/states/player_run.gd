extends PlayerState
#@ 2-4
## Course (et repos) : le joueur marche selon ses commandes ; sans sol sous les pieds, il tombe.
#@ 5
## Course (et repos) : le joueur marche selon ses commandes ; sans sol sous les pieds, il tombe ; une
## esquive demandée, et permise, le fait esquiver.
#@ 6+
## Course (et repos) : le joueur marche selon ses commandes ; sans sol sous les pieds, il tombe ; une
## esquive demandée, et permise, le fait esquiver ; un coup demandé lance le premier coup de l'enchaînement.
#@ all

## L'état de chute.
@export var fall_state: PlayerState
#@ 5+
## L'état d'esquive.
@export var dash_state: PlayerState
#@ 6+
## Le premier coup de l'enchaînement.
@export var attack_state: PlayerState
#@ all


#@ 2-4
## Sans sol, passe à la chute ; sinon, marche selon les commandes.
#@ 5
## Sans sol, passe à la chute ; une esquive demandée et permise, à l'esquive ; sinon, marche selon les
## commandes.
#@ 6+
## Sans sol, passe à la chute ; une esquive demandée et permise, à l'esquive ; un coup demandé, au premier coup ;
## sinon, marche selon les commandes.
#@ all
func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		finished.emit(fall_state.name)
		return
#@ 5+
	if player.commands.dash and player.can_dash():
		finished.emit(dash_state.name)
		return
#@ 6+
	if player.commands.attack:
		finished.emit(attack_state.name)
		return
#@ all
	core_movement(delta, player.settings.movement_speed)
#@ 3+
	# L'animation mêle le repos (-1) et la course (1).
	player.animation_tree.blend_target = -1.0 if player.get_movement_direction().is_zero_approx() else 1.0
#@ all
	player.move_and_slide()
