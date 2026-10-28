class_name DistanceLod extends RefCounted
## Les niveaux de détail par distance : 0 de près, puis un niveau de plus à chaque seuil franchi. Une marge
## (hystérésis) empêche un objet posé juste sur un seuil de changer de niveau à chaque image : on ne descend en détail
## qu'un peu après le seuil, on ne remonte qu'un peu avant.


## Le niveau à `distance` mètres : le nombre de seuils de `thresholds` (croissants) déjà dépassés.
static func level(distance: float, thresholds: PackedFloat32Array) -> int:
	var result: int = 0
	for threshold: float in thresholds:
		if distance > threshold:
			result += 1
	return result


## Le niveau à `distance` mètres quand l'objet est au niveau `current` : il ne change que si la distance a franchi le
## seuil concerné de plus de `margin` mètres, dans un sens ou dans l'autre.
static func with_hysteresis(distance: float, current: int, thresholds: PackedFloat32Array, margin: float) -> int:
	var target: int = level(distance, thresholds)
	if target > current and distance <= thresholds[target - 1] + margin:
		return current
	if target < current and distance >= thresholds[current - 1] - margin:
		return current
	return target
