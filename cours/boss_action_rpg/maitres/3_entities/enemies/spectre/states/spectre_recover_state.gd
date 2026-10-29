class_name SpectreRecoverState extends State
## L'état Recover d'un spectre : après sa plongée, il remonte vers sa place sur le cercle pendant `recover_time`
## (le moment de le tirer), puis plane de nouveau (Hover).

## Le spectre piloté.
@export var spectre: Spectre

## Le temps écoulé depuis la fin de la plongée, en secondes.
var elapsed: float = 0.0


## La remontée commence.
func enter(_previous: StringName) -> void:
	elapsed = 0.0


## Il rejoint sa place ; remonté, il plane.
func physics_update(delta: float) -> void:
	elapsed += delta
	spectre.glide_to(spectre.hover_point(), delta)
	if elapsed >= spectre.settings.recover_time:
		finish(&"Hover")
