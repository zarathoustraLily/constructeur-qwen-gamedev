class_name SpectreHoverState extends State
## L'état Hover d'un spectre : il plane sur un cercle autour de sa cible, au-dessus d'elle, et tourne avec lui ; après
## `hover_time`, il annonce une plongée (Windup), sauf si sa cible est abattue : il plane alors autour d'elle.

## Le spectre piloté.
@export var spectre: Spectre

## Le temps passé à planer, en secondes.
var elapsed: float = 0.0


## La planée recommence.
func enter(_previous: StringName) -> void:
	elapsed = 0.0


## Il tourne sur son cercle et rejoint sa place ; sa planée finie, l'annonce.
func physics_update(delta: float) -> void:
	elapsed += delta
	spectre.orbit_angle = wrapf(spectre.orbit_angle + spectre.settings.orbit_speed * delta, -PI, PI)
	spectre.glide_to(spectre.hover_point(), delta)
	if elapsed >= spectre.settings.hover_time and spectre.prey_alive():
		finish(&"Windup")
