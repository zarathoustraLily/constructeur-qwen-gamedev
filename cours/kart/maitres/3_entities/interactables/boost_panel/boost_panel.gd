extends Node3D
## Plaque d'accélération : un kart qui passe dessus reçoit 2 s de boost (sans raccourcir un boost
## plus long) et lance sa traînée fantôme (GhostTrail).


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Kart:
		body.set_boost(2.0)
		# Traînée d'images fantômes : 1 s à pleine intensité, puis 1 s de disparition (réglable sur GhostTrail)
		var ghost_trail := body.get_node_or_null("GhostTrail") as GhostTrail
		if ghost_trail:
			ghost_trail.start()
