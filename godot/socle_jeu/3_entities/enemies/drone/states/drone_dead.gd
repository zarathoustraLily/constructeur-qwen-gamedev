extends State
## Mort : quitte le groupe des ennemis, ne touche plus rien, puis disparaît après
## stats.death_duration. Le niveau, qui écoute la vie du drone, compte les points.

var _time_left: float = 0.0


func enter() -> void:
	var drone := actor as Drone
	drone.remove_from_group(&"enemies")
	drone.velocity = Vector3.ZERO
	drone.get_node(^"Collision").set_deferred(&"disabled", true)
	drone.get_node(^"Hurtbox").set_deferred(&"monitorable", false)
	_time_left = drone.stats.death_duration


func physics_update(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		actor.queue_free()
