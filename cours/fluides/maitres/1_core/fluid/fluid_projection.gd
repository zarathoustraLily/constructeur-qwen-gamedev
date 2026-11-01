class_name FluidProjection extends RefCounted
## La projection : ce qui fait d'un champ de vitesse un fluide. Un fluide comme l'air ou l'eau ne s'entasse pas : ce qui entre
## dans une case doit en sortir. La divergence mesure ce qui ne sort pas ; la pression est le champ dont la pente l'annule.
## On la cherche par passes rouge-noir, surrelaxées : une case sur deux, comme un damier, ce qui se transpose tel quel sur la
## carte graphique ; puis on retire sa pente à la vitesse.
#@ 6+
## Un mur ne laisse rien passer : sa vitesse compte pour nulle, et sa pression pour celle de la case qui le touche.
#@ all


#@ 4-5
## Remplit `out` avec la divergence de la vitesse (`u`, `v`) : ce qui sort de chaque case, moins ce qui y entre.
static func divergence(out: FluidField, u: FluidField, v: FluidField) -> void:
	for y: int in out.height:
		for x: int in out.width:
			out.put(x, y, 0.5 * (u.at(x + 1, y) - u.at(x - 1, y) + v.at(x, y + 1) - v.at(x, y - 1)))
#@ 6+
## Remplit `out` avec la divergence de la vitesse (`u`, `v`) : ce qui sort de chaque case, moins ce qui y entre, les murs de
## `walls` comptant pour une vitesse nulle.
static func divergence(out: FluidField, u: FluidField, v: FluidField, walls: ObstacleMask) -> void:
	for y: int in out.height:
		for x: int in out.width:
			var east: float = 0.0 if walls.is_solid(x + 1, y) else u.at(x + 1, y)
			var west: float = 0.0 if walls.is_solid(x - 1, y) else u.at(x - 1, y)
			var south: float = 0.0 if walls.is_solid(x, y + 1) else v.at(x, y + 1)
			var north: float = 0.0 if walls.is_solid(x, y - 1) else v.at(x, y - 1)
			out.put(x, y, 0.5 * (east - west + south - north))
#@ all


#@ 4-5
## Remplit `pressure` : `iterations` passes rouge-noir sur `divergence`, surrelaxées de `relaxation` (1 : sans, 1,7 : plus vite).
static func solve_pressure(pressure: FluidField, divergence_field: FluidField, iterations: int, relaxation: float) -> void:
	for _pass: int in iterations:
		for color: int in 2:
			for y: int in pressure.height:
				for x: int in range((y + color) % 2, pressure.width, 2):
					var around: float = (pressure.at(x - 1, y) + pressure.at(x + 1, y) + pressure.at(x, y - 1)
							+ pressure.at(x, y + 1))
					var settled: float = (around - divergence_field.at(x, y)) * 0.25
					pressure.put(x, y, lerpf(pressure.at(x, y), settled, relaxation))
#@ 6+
## Remplit `pressure` : `iterations` passes rouge-noir sur `divergence`, surrelaxées de `relaxation` (1 : sans, 1,7 : plus vite) ;
## un mur prend la pression de la case qui le touche, et n'est pas calculé.
static func solve_pressure(pressure: FluidField, divergence_field: FluidField, walls: ObstacleMask, iterations: int,
		relaxation: float) -> void:
	for _pass: int in iterations:
		for color: int in 2:
			for y: int in pressure.height:
				for x: int in range((y + color) % 2, pressure.width, 2):
					if walls.is_solid(x, y):
						continue
					var here: float = pressure.at(x, y)
					var around: float = (_seen(pressure, walls, x - 1, y, here) + _seen(pressure, walls, x + 1, y, here)
							+ _seen(pressure, walls, x, y - 1, here) + _seen(pressure, walls, x, y + 1, here))
					var settled: float = (around - divergence_field.at(x, y)) * 0.25
					pressure.put(x, y, lerpf(here, settled, relaxation))


## La pression vue depuis une case voisine de (x, y) : celle de la case, ou `here` si c'est un mur.
static func _seen(pressure: FluidField, walls: ObstacleMask, x: int, y: int, here: float) -> float:
	return here if walls.is_solid(x, y) else pressure.at(x, y)
#@ all


#@ 4-5
## Retire à la vitesse (`u`, `v`) la pente de `pressure` : il reste un écoulement sans divergence.
static func subtract_gradient(u: FluidField, v: FluidField, pressure: FluidField) -> void:
	for y: int in u.height:
		for x: int in u.width:
			u.put(x, y, u.at(x, y) - 0.5 * (pressure.at(x + 1, y) - pressure.at(x - 1, y)))
			v.put(x, y, v.at(x, y) - 0.5 * (pressure.at(x, y + 1) - pressure.at(x, y - 1)))
#@ 6+
## Retire à la vitesse (`u`, `v`) la pente de `pressure`, les murs comptant pour la pression de la case ; leur vitesse reste nulle.
static func subtract_gradient(u: FluidField, v: FluidField, pressure: FluidField, walls: ObstacleMask) -> void:
	for y: int in u.height:
		for x: int in u.width:
			if walls.is_solid(x, y):
				continue
			var here: float = pressure.at(x, y)
			u.put(x, y, u.at(x, y) - 0.5 * (_seen(pressure, walls, x + 1, y, here) - _seen(pressure, walls, x - 1, y, here)))
			v.put(x, y, v.at(x, y) - 0.5 * (_seen(pressure, walls, x, y + 1, here) - _seen(pressure, walls, x, y - 1, here)))
#@ all
