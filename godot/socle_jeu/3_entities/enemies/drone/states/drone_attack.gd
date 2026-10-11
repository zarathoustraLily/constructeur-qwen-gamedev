extends State
## Immobile, tire vers le joueur à la cadence de son arme ; reprend la poursuite s'il s'éloigne.


func physics_update(_delta: float) -> void:
	var drone := actor as Drone
	if drone.distance_to_target() > drone.stats.attack_range * 1.2:
		transition_requested.emit(&"chase")
		return
	drone.velocity = Vector3.ZERO
	drone.weapon.fire(drone.direction_to_target())
