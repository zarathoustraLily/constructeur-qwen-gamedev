class_name RayMarch extends RefCounted
## Ce qu'un rayon traverse, sur le processeur. Le shader `smoke_view.gdshader` fait le même calcul pour chaque pixel : ces fonctions
## lui servent de juge, parce qu'une image ne se lit pas à l'œil dans un test.


## Où le rayon entre dans la boîte centrée de demi-taille `half_size`, et où il en sort : deux distances le long de `direction`, ou
## (-1, -1) s'il la manque. Une boîte est trois paires de plans : le rayon est dedans après le dernier plan d'entrée, et jusqu'au
## premier plan de sortie. S'il part de l'intérieur, l'entrée vaut 0.
static func box_hits(origin: Vector3, direction: Vector3, half_size: Vector3) -> Vector2:
	var first: Vector3 = (-half_size - origin) / direction
	var second: Vector3 = (half_size - origin) / direction
	var entry: float = maxf(maxf(minf(first.x, second.x), minf(first.y, second.y)), minf(first.z, second.z))
	var leave: float = minf(minf(maxf(first.x, second.x), maxf(first.y, second.y)), maxf(first.z, second.z))
	if leave < maxf(entry, 0.0):
		return Vector2(-1.0, -1.0)
	return Vector2(maxf(entry, 0.0), leave)


## La part de lumière qui traverse les valeurs `densities`, lues tous les `spacing` : la loi de Beer-Lambert. Chaque longueur de
## matière retire la même part de ce qui reste : la lumière suit une exponentielle, pas une droite.
static func transmittance(densities: PackedFloat32Array, spacing: float, absorption: float) -> float:
	var matter: float = 0.0
	for value: float in densities:
		matter += value
	return exp(-absorption * matter * spacing)
