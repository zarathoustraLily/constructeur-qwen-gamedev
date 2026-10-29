class_name SpectreWindupState extends State
## L'état Windup d'un spectre : il s'arrête, se tourne vers sa cible et s'illumine (sa vue fait monter l'éclat)
## pendant `windup_time` : c'est l'annonce, le moment pour le héros de rouler ; puis il plonge (Dive).

## Le spectre piloté.
@export var spectre: Spectre

## Le temps écoulé depuis le début de l'annonce, en secondes.
var elapsed: float = 0.0


## L'annonce commence.
func enter(_previous: StringName) -> void:
	elapsed = 0.0


## Il fait face à sa cible ; l'annonce finie, la plongée.
func physics_update(delta: float) -> void:
	elapsed += delta
	spectre.face_target()
	if elapsed >= spectre.settings.windup_time:
		finish(&"Dive")
