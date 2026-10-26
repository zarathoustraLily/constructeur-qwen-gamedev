extends State
## Étourdi : le robot ne fait rien pendant stats.stun_duration, puis revient au repos. Le décompte avance dans
## physics_update : il s'arrête quand l'arbre est en pause.

var _time_left: float = 0.0


func enter() -> void:
	_time_left = (actor as Robot).stats.stun_duration


func physics_update(delta: float) -> void:
	_time_left -= delta
	# 0,5 s ôtées par pas de 1/60 laissent un reste infime au-dessus de 0 : sans is_zero_approx, une image de trop.
	if _time_left <= 0.0 or is_zero_approx(_time_left):
		transition_requested.emit(&"idle")
