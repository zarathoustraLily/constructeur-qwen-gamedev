class_name Advection extends RefCounted
## Le transport : le fluide emporte ce qu'il contient. On ne pousse pas les valeurs vers l'avant, ce qui laisserait des trous
## et s'emballerait à grande vitesse : pour chaque case, on remonte le courant et on lit ce qui s'y trouvait. Une valeur lue
## ne dépasse jamais celles qui l'entourent : le calcul reste stable, quelle que soit la vitesse.


## Remplit `target` : chaque case reçoit la valeur de `source` à l'endroit d'où vient le courant (`u`, `v`, en cases par
## seconde) `delta` secondes plus tôt.
static func semi_lagrangian(target: FluidField, source: FluidField, u: FluidField, v: FluidField, delta: float) -> void:
	for y: int in target.height:
		for x: int in target.width:
			var from_x: float = x - delta * u.at(x, y)
			var from_y: float = y - delta * v.at(x, y)
			target.put(x, y, source.sample(from_x, from_y))
#@ 7+


## Le transport de MacCormack : il corrige l'étalement du transport simple. On transporte en avant (`forward`), on revient en
## arrière (`backward`) : l'écart à `source` est l'erreur commise, lue là d'où vient le courant, et on en retire la moitié.
static func mac_cormack(target: FluidField, source: FluidField, u: FluidField, v: FluidField, delta: float,
		forward: FluidField, backward: FluidField) -> void:
	semi_lagrangian(forward, source, u, v, delta)
	semi_lagrangian(backward, forward, u, v, -delta)
	for y: int in target.height:
		for x: int in target.width:
			var from_x: float = x - delta * u.at(x, y)
			var from_y: float = y - delta * v.at(x, y)
			var corrected: float = forward.at(x, y) + 0.5 * (source.sample(from_x, from_y) - backward.sample(from_x, from_y))
			target.put(x, y, _limited(corrected, source, from_x, from_y))


## `value` ramenée entre la plus petite et la plus grande des quatre cases de `source` autour de (x, y) : sans cette borne, la
## correction crée des valeurs qui n'existaient pas, et le calcul s'emballe.
static func _limited(value: float, source: FluidField, x: float, y: float) -> float:
	var left: int = floori(x)
	var top: int = floori(y)
	var a: float = source.at(left, top)
	var b: float = source.at(left + 1, top)
	var c: float = source.at(left, top + 1)
	var d: float = source.at(left + 1, top + 1)
	return clampf(value, minf(minf(a, b), minf(c, d)), maxf(maxf(a, b), maxf(c, d)))
#@ all
