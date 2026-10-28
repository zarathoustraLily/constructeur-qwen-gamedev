class_name StickFilter extends RefCounted
## Le stick et les gâchettes d'une manette, filtrés. Sous la zone morte, ils valent zéro : un stick au repos ne
## revient jamais tout à fait au centre. Au-delà, la course restante est remise à l'échelle de 0 à 1, pour qu'une
## légère poussée donne une petite valeur au lieu de sauter d'un coup à la valeur de la zone morte.


## Le stick `raw` filtré par une zone morte ronde de rayon `deadzone` (de 0 à 1) : la même direction, une longueur
## remise entre 0 et 1. Une zone morte ronde ne favorise aucune direction, contrairement à deux zones par axe.
static func radial(raw: Vector2, deadzone: float) -> Vector2:
	var length: float = raw.length()
	if length <= deadzone:
		return Vector2.ZERO
	var scaled: float = inverse_lerp(deadzone, 1.0, minf(length, 1.0))
	return raw / length * scaled


## La gâchette `raw` (de 0 à 1) filtrée par la zone morte `deadzone` : 0 en dessous, puis de 0 à 1.
static func trigger(raw: float, deadzone: float) -> float:
	if raw <= deadzone:
		return 0.0
	return clampf(inverse_lerp(deadzone, 1.0, raw), 0.0, 1.0)


## Le stick lu sur quatre actions (gauche, droite, haut, bas), sans la zone morte des actions (0), puis filtré par
## `radial` : la zone morte se règle à un seul endroit.
static func from_actions(left: StringName, right: StringName, up: StringName, down: StringName,
		deadzone: float) -> Vector2:
	return radial(Input.get_vector(left, right, up, down, 0.0), deadzone)
