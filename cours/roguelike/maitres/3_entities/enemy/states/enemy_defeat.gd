extends EnemyState
## Défaite : l'ennemi s'arrête et joue l'animation de sa chute. Il n'en sort plus.


## Lance l'animation de défaite.
func enter(_previous_state: StringName) -> void:
	enemy.animation_tree.change_immediate(&"Defeat")


## Reste sur place.
func physics_update(_delta: float) -> void:
	enemy.velocity = Vector3.ZERO
	enemy.move_and_slide()
