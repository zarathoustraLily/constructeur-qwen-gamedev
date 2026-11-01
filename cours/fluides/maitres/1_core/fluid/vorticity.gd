class_name Vorticity extends RefCounted
## Les tourbillons. La grille arrondit tout : à chaque pas, les petits tourbillons s'effacent et la fumée devient molle. Le
## confinement les rend : il mesure où le fluide tourne, et pousse chaque case vers le centre de sa rotation.


## Remplit `out` avec la rotation de la vitesse (`u`, `v`) : positive quand le fluide tourne dans le sens de x vers y.
static func curl(out: FluidField, u: FluidField, v: FluidField) -> void:
	for y: int in out.height:
		for x: int in out.width:
			out.put(x, y, 0.5 * (v.at(x + 1, y) - v.at(x - 1, y) - u.at(x, y + 1) + u.at(x, y - 1)))


## Ajoute à (`u`, `v`) la force du confinement pendant `delta` secondes, d'après la rotation `spin`, à la force `strength`.
static func confine(u: FluidField, v: FluidField, spin: FluidField, strength: float, delta: float) -> void:
	for y: int in u.height:
		for x: int in u.width:
			var toward: Vector2 = Vector2(absf(spin.at(x + 1, y)) - absf(spin.at(x - 1, y)),
					absf(spin.at(x, y + 1)) - absf(spin.at(x, y - 1)))
			if toward.length_squared() < 0.000001:
				continue
			toward = toward.normalized()
			var turn: float = spin.at(x, y)
			u.put(x, y, u.at(x, y) + strength * toward.y * turn * delta)
			v.put(x, y, v.at(x, y) - strength * toward.x * turn * delta)
