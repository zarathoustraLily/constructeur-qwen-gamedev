extends State
## Immobile, tire vers la cible à la cadence de son arme ; reprend la poursuite si elle s'éloigne
## au-delà de stats.attack_leave_range.


func physics_update(_delta: float) -> void:
	var drone := actor as Drone
	if drone.distance_to_target() > drone.stats.attack_leave_range:
		transition_requested.emit(&"chase")
		return
	drone.velocity = Vector3.ZERO
	drone.weapon.fire(drone.direction_to_target())
