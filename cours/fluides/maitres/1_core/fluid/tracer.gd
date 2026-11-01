class_name Tracer extends RefCounted
## Une particule que le courant emporte. Le shader `tracers.glsl` fait le même calcul pour chaque particule : ces fonctions lui servent de
## juge. Une case vaut une unité, et son centre est sur les entiers, comme dans `FluidField.sample`.


## Le courant au point `point`, en cases par seconde.
static func current_at(point: Vector2, u: FluidField, v: FluidField) -> Vector2:
	return Vector2(u.sample(point.x, point.y), v.sample(point.x, point.y))


## Où arrive une particule partie de `point`, après `delta` secondes. On lit le courant à mi-chemin : sur une trajectoire courbe, une ligne
## droite tirée depuis le départ sort du virage, et la particule s'éloigne à chaque pas.
static func moved(point: Vector2, u: FluidField, v: FluidField, delta: float) -> Vector2:
	var middle: Vector2 = point + current_at(point, u, v) * delta * 0.5
	return point + current_at(middle, u, v) * delta
