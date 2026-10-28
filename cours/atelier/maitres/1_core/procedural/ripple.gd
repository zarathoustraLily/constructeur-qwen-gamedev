class_name Ripple extends RefCounted
## Une onde circulaire, comme celle d'une pierre dans l'eau : une sinusoïde qui part du point d'impact, dont le front
## avance à vitesse constante, et qui s'amortit avec la distance et avec le temps. Rien n'a encore bougé au-delà du
## front.


## Le nombre d'onde : 2 PI divisé par la longueur d'onde.
static func wave_number(settings: RippleSettings) -> float:
	return TAU / settings.wavelength


## La hauteur de l'eau à `distance` mètres de l'impact, `time` secondes après : nulle au-delà du front (distance
## > vitesse × temps), sinon amplitude × amortissements × sin(k × (vitesse × temps - distance)).
static func height(distance: float, time: float, settings: RippleSettings) -> float:
	var front: float = settings.speed * time
	if time <= 0.0 or distance > front:
		return 0.0
	var damping: float = exp(-settings.distance_damping * distance - settings.time_damping * time)
	return settings.amplitude * damping * sin(wave_number(settings) * (front - distance))


## Les points `points` relevés par l'onde partie de `center` (x, z) il y a `time` secondes : seule leur hauteur
## change.
static func displace(points: PackedVector3Array, center: Vector2, time: float,
		settings: RippleSettings) -> PackedVector3Array:
	var moved: PackedVector3Array = points.duplicate()
	for i: int in moved.size():
		var point: Vector3 = moved[i]
		var distance: float = Vector2(point.x, point.z).distance_to(center)
		moved[i] = Vector3(point.x, height(distance, time, settings), point.z)
	return moved
