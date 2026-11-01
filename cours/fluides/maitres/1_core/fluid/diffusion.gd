class_name Diffusion extends RefCounted
## La diffusion : chaque case échange avec ses quatre voisines, ce qui étale les bosses et épaissit le fluide. Écrit en avant,
## ce calcul explose dès que `rate * delta` dépasse un quart. On cherche donc l'état futur qui, diffusé à l'envers, redonne
## l'état présent : une équation qu'on résout par passes successives (Gauss-Seidel), stable pour toute valeur.


## Remplit `target` avec `source` diffusé `delta` secondes au taux `rate` (en cases² par seconde), en `iterations` passes.
static func solve(target: FluidField, source: FluidField, rate: float, delta: float, iterations: int) -> void:
	var exchange: float = rate * delta
	target.copy_from(source)
	for _pass: int in iterations:
		for y: int in target.height:
			for x: int in target.width:
				var around: float = target.at(x - 1, y) + target.at(x + 1, y) + target.at(x, y - 1) + target.at(x, y + 1)
				target.put(x, y, (source.at(x, y) + exchange * around) / (1.0 + 4.0 * exchange))
