extends State
## Joueur à l'arrêt : freine, puis part en marche ou en dash.


func physics_update(_delta: float) -> void:
	var player := actor as Player
	player.velocity = Vector3.ZERO
	player.move_and_slide()
	if player.wants_dash and player.can_dash():
		transition_requested.emit(&"dash")
	elif not player.move_input.is_zero_approx():
		transition_requested.emit(&"move")
