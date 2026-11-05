class_name CollisionTools
extends RefCounted
## La géométrie des formes de collision d'une salle, sans nœud : un polygone est une suite de sommets en mètres (x, z),
## fermée (le dernier sommet rejoint le premier). On y vérifie qu'un polygone est simple (aucun côté n'en croise un
## autre), on trouve le sommet ou le côté le plus proche d'un point, et l'on produit les polygones modifiés : sommet
## déplacé, ajouté ou retiré, nouvelle forme carrée. Rien n'est modifié sur place : chaque fonction rend un nouveau
## polygone, que le document validera.

## Le nombre minimal de sommets d'une forme.
const MIN_POINTS: int = 3


## Vrai si aucun côté de `polygon` n'en croise un autre (deux côtés voisins partagent seulement leur sommet commun).
static func is_simple(polygon: PackedVector2Array) -> bool:
	var count: int = polygon.size()
	if count < MIN_POINTS:
		return false
	for i: int in count:
		for j: int in range(i + 1, count):
			if j == i + 1 or (i == 0 and j == count - 1):
				continue
			var a: Vector2 = polygon[i]
			var b: Vector2 = polygon[(i + 1) % count]
			var c: Vector2 = polygon[j]
			var d: Vector2 = polygon[(j + 1) % count]
			if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
				return false
	return true


## L'indice du sommet de `polygon` le plus proche de `point`, s'il est à moins de `radius` ; sinon -1.
static func nearest_point(polygon: PackedVector2Array, point: Vector2, radius: float) -> int:
	var best: int = -1
	var best_distance: float = radius
	for index: int in polygon.size():
		var distance: float = polygon[index].distance_to(point)
		if distance <= best_distance:
			best = index
			best_distance = distance
	return best


## L'indice du côté de `polygon` (du sommet i au suivant) le plus proche de `point`, s'il est à moins de `radius` ;
## sinon -1.
static func nearest_edge(polygon: PackedVector2Array, point: Vector2, radius: float) -> int:
	var best: int = -1
	var best_distance: float = radius
	for index: int in polygon.size():
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, polygon[index],
				polygon[(index + 1) % polygon.size()])
		var distance: float = closest.distance_to(point)
		if distance <= best_distance:
			best = index
			best_distance = distance
	return best


## `polygon` avec son sommet `index` amené en `point`.
static func moved_point(polygon: PackedVector2Array, index: int, point: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = polygon.duplicate()
	result[index] = point
	return result


## `polygon` avec un sommet en `point`, inséré après le sommet `edge` (sur le côté `edge`).
static func inserted_point(polygon: PackedVector2Array, edge: int, point: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = polygon.duplicate()
	result.insert(edge + 1, point)
	return result


## `polygon` sans son sommet `index` ; le polygone tel quel s'il n'a plus que le minimum de sommets.
static func removed_point(polygon: PackedVector2Array, index: int) -> PackedVector2Array:
	var result: PackedVector2Array = polygon.duplicate()
	if result.size() > MIN_POINTS:
		result.remove_at(index)
	return result


## Une forme carrée de côté `side`, centrée sur `center`.
static func square(center: Vector2, side: float) -> PackedVector2Array:
	var half: float = side / 2.0
	return PackedVector2Array([center + Vector2(-half, -half), center + Vector2(half, -half),
			center + Vector2(half, half), center + Vector2(-half, half)])


## L'indice du dernier polygone de `polygons` (le plus haut) qui contient `point`, ou -1.
static func polygon_at(polygons: Array[PackedVector2Array], point: Vector2) -> int:
	for index: int in range(polygons.size() - 1, -1, -1):
		if Geometry2D.is_point_in_polygon(point, polygons[index]):
			return index
	return -1
