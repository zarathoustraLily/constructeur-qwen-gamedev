extends EnemyState
## Poursuite : l'ennemi court vers sa cible en suivant la navigation du niveau ; à portée, il attaque.

## L'état d'attaque.
@export var attack_state: EnemyState


## Lance la course.
func enter(_previous_state: StringName) -> void:
	enemy.animation_tree.change_immediate(&"WalkSpace")
	enemy.animation_tree.blend_target = 1.0


## À portée, attaque ; sinon, demande le chemin vers la cible et avance vers son prochain point.
func physics_update(_delta: float) -> void:
	if enemy.target == null:
		return
	if enemy.distance_to_target() < enemy.settings.attack_range:
		look_at_target()
		finished.emit(attack_state.name)
		return
	enemy.navigation_agent.target_position = enemy.target.global_position
	var destination := enemy.navigation_agent.get_next_path_position()
	look_at_point(destination)
	var direction := destination - enemy.global_position
	direction.y = 0.0
	move_enemy(enemy.settings.speed, direction.normalized())
