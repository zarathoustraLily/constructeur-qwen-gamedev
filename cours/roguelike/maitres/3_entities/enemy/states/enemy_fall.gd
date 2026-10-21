extends EnemyState
## Chute : l'ennemi tombe ; à l'atterrissage, il passe à land_state (étourdi par le choc).

## L'état à l'atterrissage.
@export var land_state: EnemyState


## Tombe ; au sol, atterrit.
func physics_update(_delta: float) -> void:
	# Comme le joueur : la gravité sert de vitesse de chute, constante.
	enemy.velocity = enemy.get_gravity()
	enemy.move_and_slide()
	if enemy.is_on_floor():
		finished.emit(land_state.name)
