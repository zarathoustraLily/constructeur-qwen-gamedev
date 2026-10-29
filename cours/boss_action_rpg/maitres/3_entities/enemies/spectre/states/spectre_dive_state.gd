class_name SpectreDiveState extends State
## L'état Dive d'un spectre : il plonge en ligne droite vers le torse de sa cible, pris à l'instant du départ (une
## roulade bien placée l'évite), sa zone de coup allumée ; il s'arrête au point visé ou au bout de `dive_max_time`, et
## remonte (Recover).

## Le spectre piloté.
@export var spectre: Spectre

## Le temps écoulé depuis le départ, en secondes.
var elapsed: float = 0.0

var _direction: Vector3 = Vector3.ZERO
var _left: float = 0.0


## Le point est pris, la zone de coup s'allume.
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	var trajet: Vector3 = spectre.dive_point() - spectre.global_position
	_left = trajet.length()
	_direction = trajet.normalized() if _left > 0.0 else Vector3.DOWN
	spectre.hitbox.activate(spectre.settings.damage)


## La zone de coup s'éteint, quoi qu'il arrive.
func exit() -> void:
	spectre.hitbox.deactivate()


## Il avance vers le point ; arrivé, ou trop longtemps, il remonte.
func physics_update(delta: float) -> void:
	elapsed += delta
	var pas: float = minf(spectre.settings.dive_speed * delta, _left)
	spectre.global_position += _direction * pas
	_left -= pas
	if _left <= 0.0 or elapsed >= spectre.settings.dive_max_time:
		finish(&"Recover")
