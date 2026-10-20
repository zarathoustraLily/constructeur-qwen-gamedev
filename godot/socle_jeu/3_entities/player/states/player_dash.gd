extends State
## Dash : vitesse élevée et invincibilité pendant stats.dash_duration, puis recharge.

var _direction: Vector3 = Vector3.FORWARD
var _time_left: float = 0.0


func enter() -> void:
	var player := actor as Player
	_direction = player.move_input.normalized() if not player.move_input.is_zero_approx() else player.aim
	_time_left = player.stats.dash_duration
	player.health.set_invulnerable(true)


func exit() -> void:
	var player := actor as Player
	player.health.set_invulnerable(false)
	player.start_dash_cooldown()


func physics_update(delta: float) -> void:
	var player := actor as Player
	player.velocity = _direction * player.stats.dash_speed
	player.move_and_slide()
	_time_left -= delta
	if _time_left <= 0.0:
		transition_requested.emit(&"move" if not player.move_input.is_zero_approx() else &"idle")
