extends State
## Mort : quitte le groupe des ennemis, prévient le jeu, rétrécit puis disparaît.

const SHRINK_TIME := 0.25


func enter() -> void:
	var drone := actor as Drone
	drone.remove_from_group(&"enemies")
	drone.velocity = Vector3.ZERO
	drone.get_node(^"Collision").set_deferred(&"disabled", true)
	drone.get_node(^"Hurtbox").set_deferred(&"monitorable", false)
	EventBus.enemy_killed.emit(drone, drone.stats.score_value)
	var tween := drone.create_tween()
	tween.tween_property(drone, ^"scale", Vector3.ONE * 0.01, SHRINK_TIME)
	tween.tween_callback(drone.queue_free)
