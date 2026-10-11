extends State
## Se rapproche du joueur jusqu'à la portée de tir ; le perd au-delà de la détection.


func physics_update(_delta: float) -> void:
	var drone := actor as Drone
	var distance := drone.distance_to_target()
	if distance > drone.stats.detection_range:
		transition_requested.emit(&"idle")
		return
	if distance <= drone.stats.attack_range:
		transition_requested.emit(&"attack")
		return
	drone.velocity = drone.direction_to_target() * drone.stats.speed
	drone.move_and_slide()
