class_name Aim extends RefCounted
## Le point visé, sans nœud : le centre de l'écran est l'avant de la caméra (son -Z) ; un rayon part de la caméra dans
## cette direction, et le premier obstacle touché est le point visé. Les projectiles partent de l'arme vers ce point :
## ils arrivent là où le joueur voit le centre de l'écran, même si l'arme est décalée de la caméra.
#@ 14+
## La requête du rayon est créée une fois et réutilisée : en créer une à chaque appel, à chaque image où l'on tire,
## faisait une allocation par image.

static var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
#@ all


## Ce que touche le rayon parti de `from` dans la direction `forward` (longueur 1), jusqu'à `max_distance`, sur les
## couches de `mask` (zones comprises) ; rien touché : le bout du rayon.
static func point(space: PhysicsDirectSpaceState3D, from: Vector3, forward: Vector3, max_distance: float, mask: int) -> Vector3:
#@ 5-13
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, from + forward * max_distance, mask)
#@ 14+
	var query: PhysicsRayQueryParameters3D = _query
	query.from = from
	query.to = from + forward * max_distance
	query.collision_mask = mask
#@ all
	query.collide_with_areas = true
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return query.to
	var touched: Vector3 = hit["position"]
	return touched
