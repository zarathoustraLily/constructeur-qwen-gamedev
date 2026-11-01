class_name Combustion extends RefCounted
## Le feu, en trois champs de plus : le carburant, la température, la suie. Le carburant brûle au-dessus d'une température :
## il chauffe, il laisse de la suie, et le gaz brûlé prend de la place : c'est cette dilatation qui gonfle une flamme. L'air
## chaud monte, la suie pèse, et tout refroidit.


## Brûle pendant `delta` secondes : là où `temperature` atteint `settings.ignition`, le carburant se change en chaleur et en
## suie, et `expansion` reçoit la dilatation de chaque case, que la projection laissera sortir.
static func burn(fuel: FluidField, temperature: FluidField, soot: FluidField, expansion: FluidField, settings: FireSettings,
		delta: float) -> void:
	for i: int in fuel.data.size():
		var burned: float = 0.0
		if temperature.data[i] >= settings.ignition:
			burned = minf(fuel.data[i], settings.burn_rate * delta)
		fuel.data[i] -= burned
		temperature.data[i] += burned * settings.heat
		soot.data[i] += burned * settings.soot_yield
		expansion.data[i] = burned * settings.expansion / delta


## Pousse la vitesse verticale `v` : la chaleur monte (vers les y négatifs), la suie pèse.
static func lift(v: FluidField, temperature: FluidField, soot: FluidField, settings: FireSettings, delta: float) -> void:
	for i: int in v.data.size():
		v.data[i] += (settings.soot_weight * soot.data[i] - settings.buoyancy * temperature.data[i]) * delta


## Refroidit `field` : il perd la part `rate` de sa valeur par seconde, quelle que soit la cadence.
static func cool(field: FluidField, rate: float, delta: float) -> void:
	var kept: float = exp(-rate * delta)
	for i: int in field.data.size():
		field.data[i] *= kept
