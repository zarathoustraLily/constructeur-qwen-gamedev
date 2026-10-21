extends EnemyState
## Étourdissement : touché, l'ennemi joue l'animation du coup reçu ; il suit son recul, puis reprend.

## L'état qui suit l'étourdissement.
@export var next_state: EnemyState


## Lance l'animation du coup reçu et écoute sa fin.
func enter(_previous_state: StringName) -> void:
	enemy.animation_tree.change_immediate(&"Stun")
	enemy.animation_tree.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


## Suit son recul, sinon reste sur place.
func physics_update(_delta: float) -> void:
	move_enemy(enemy.settings.speed, Vector3.ZERO)


## Un étourdissement interrompu n'écoute plus la fin de son animation.
func exit() -> void:
	if enemy.animation_tree.animation_finished.is_connected(_on_animation_finished):
		enemy.animation_tree.animation_finished.disconnect(_on_animation_finished)


func _on_animation_finished(_animation_name: StringName) -> void:
	finished.emit(next_state.name)
