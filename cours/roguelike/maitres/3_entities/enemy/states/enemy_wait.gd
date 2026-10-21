extends EnemyState
## Attente : l'ennemi s'arrête, au repos, pendant wait_time, puis se tourne vers sa cible et passe à l'état
## suivant.

## L'état qui suit l'attente.
@export var next_state: EnemyState

var _timer: SceneTreeTimer


## Lance l'attente (un minuteur qui s'arrête en pause) et l'animation de repos.
func enter(_previous_state: StringName) -> void:
	_timer = get_tree().create_timer(enemy.settings.wait_time, false)
	_timer.timeout.connect(_on_timeout)
	enemy.animation_tree.change_immediate(&"WalkSpace")
	enemy.animation_tree.blend_target = -1.0


## Ralentit jusqu'à l'arrêt.
func physics_update(_delta: float) -> void:
	move_enemy(enemy.settings.speed, Vector3.ZERO)


## Une attente interrompue (un coup reçu) ne doit plus finir : on n'écoute plus son minuteur.
func exit() -> void:
	if _timer != null and _timer.timeout.is_connected(_on_timeout):
		_timer.timeout.disconnect(_on_timeout)


func _on_timeout() -> void:
	look_at_target()
	finished.emit(next_state.name)
