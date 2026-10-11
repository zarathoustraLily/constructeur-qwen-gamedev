extends State
## Joueur en marche.


func physics_update(_delta: float) -> void:
	var player := actor as Player
	if player.wants_dash and player.can_dash():
		transition_requested.emit(&"dash")
		return
	if player.move_input.is_zero_approx():
		transition_requested.emit(&"idle")
		return
	player.velocity = player.walk_velocity(player.move_input)
	player.move_and_slide()
