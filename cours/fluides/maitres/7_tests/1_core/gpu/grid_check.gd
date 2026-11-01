class_name GridCheck extends RefCounted
## Ce que partagent les suites du GPU : passer d'un champ à une texture, des champs qui ne doivent rien au hasard, et l'écart
## entre deux grilles.


## Une texture de la carte, remplie avec `field`.
static func texture_of(device: ComputeDevice, field: FluidField) -> RID:
	var texture: RID = device.new_texture(field.width, field.height)
	device.upload(texture, field)
	return texture


## Le champ que contient `texture`, de `width` × `height` cases, une fois la carte arrêtée.
static func read(device: ComputeDevice, texture: RID, width: int, height: int) -> FluidField:
	device.finish()
	var field: FluidField = FluidField.new(width, height)
	device.download(texture, field)
	return field


## Le plus grand écart entre deux champs de la même taille.
static func largest_gap(a: FluidField, b: FluidField) -> float:
	var gap: float = 0.0
	for i: int in a.data.size():
		gap = maxf(gap, absf(a.data[i] - b.data[i]))
	return gap
#@ 13+


## La taille moyenne des valeurs de `field`, signe oublié.
static func mean_size(field: FluidField) -> float:
	var sum_of_sizes: float = 0.0
	for value: float in field.data:
		sum_of_sizes += absf(value)
	return sum_of_sizes / field.data.size()
#@ all


## Un champ en vagues, entre -`strength` et `strength`, où aucune case ne ressemble à sa voisine.
static func waves(width: int, height: int, strength: float) -> FluidField:
	var field: FluidField = FluidField.new(width, height)
	for y: int in height:
		for x: int in width:
			field.put(x, y, strength * sin(0.73 * x + 0.21) * cos(0.41 * y - 0.17))
	return field


## Un champ de la taille de `other`, rempli de `value`.
static func filled(other: FluidField, value: float) -> FluidField:
	var field: FluidField = FluidField.new(other.width, other.height)
	field.fill(value)
	return field
