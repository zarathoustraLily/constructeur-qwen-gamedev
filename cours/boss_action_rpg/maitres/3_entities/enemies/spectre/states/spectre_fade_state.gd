class_name SpectreFadeState extends State
## L'état Fade d'un spectre : abattu, il se dissipe pendant `fade_time` (sa vue éteint sa lueur), puis disparaît pour
## de bon (Spectre.vanish).

## Le spectre piloté.
@export var spectre: Spectre

## Le temps écoulé depuis qu'il a été abattu, en secondes.
var elapsed: float = 0.0


## La dissipation commence.
func enter(_previous: StringName) -> void:
	elapsed = 0.0


## Il reste en place ; dissipé, il disparaît.
func physics_update(delta: float) -> void:
	elapsed += delta
	if elapsed >= spectre.settings.fade_time:
		spectre.vanish()
