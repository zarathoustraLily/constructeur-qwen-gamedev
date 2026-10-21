class_name KnockbackComponent extends Node
## Composant de recul, enfant direct de sa racine et nommé KnockbackComponent : il accumule les poussées reçues
## (add_knockback) en une vitesse qui s'amortit à chaque image physique. Tant qu'il est actif (plus de 1 m/s), le
## personnage suit cette vitesse au lieu de la sienne.

## Amortissement du recul, par seconde : plus grand, il s'arrête plus vite.
@export var decay: float = 8.0
## Vitesse de recul maximale, en m/s.
@export var max_knockback: float = 50.0

## Vitesse de recul actuelle, bornée à max_knockback.
var magnitude: Vector3 = Vector3.ZERO:
	set(value):
		magnitude = value.limit_length(max_knockback)


func _physics_process(delta: float) -> void:
	magnitude = magnitude.lerp(Vector3.ZERO, 1.0 - exp(-decay * delta))


## Ajoute la poussée `push` (en m/s) au recul.
func add_knockback(push: Vector3) -> void:
	magnitude += push


## Vrai tant que le recul dépasse 1 m/s.
func is_active() -> bool:
	return magnitude.length() > 1.0
