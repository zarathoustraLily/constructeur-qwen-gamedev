extends State
## Attend que le joueur entre dans sa zone de détection.


func physics_update(_delta: float) -> void:
	var drone := actor as Drone
	if drone.distance_to_target() <= drone.stats.detection_range:
		transition_requested.emit(&"chase")
