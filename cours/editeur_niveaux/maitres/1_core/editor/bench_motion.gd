class_name BenchMotion
extends RefCounted
## Le déplacement du modèle sur le banc d'essai, en géométrie pure : une position au sol, une orientation, et l'état
## d'animation qui en découle (au repos, ou en déplacement). Le banc ne joue pas : il n'y a ni collision ni physique,
## seulement de quoi voir un clip de course tourner dans le sens de la marche.

## La position du modèle, en mètres.
var position: Vector3 = Vector3.ZERO
## L'orientation du modèle autour de l'axe vertical, en radians (0 : il regarde vers -z).
var facing: float = 0.0
## L'état d'animation : `idle` au repos, `move` en déplacement.
var state: StringName = &"idle"


## Avance d'un pas de `delta` secondes, dans la direction `direction` (x, z : un vecteur de longueur 1 au plus), à
## `speed_mps` mètres par seconde.
func step(direction: Vector2, delta: float, speed_mps: float) -> void:
	var length: float = minf(direction.length(), 1.0)
	if is_zero_approx(length):
		state = &"idle"
		return
	var heading: Vector2 = direction.normalized()
	position += Vector3(heading.x, 0.0, heading.y) * length * speed_mps * delta
	facing = atan2(-heading.x, -heading.y)
	state = &"move"
