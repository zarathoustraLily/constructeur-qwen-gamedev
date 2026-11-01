class_name SphSolver extends RefCounted
## Un liquide sans grille : chaque particule porte un peu de masse. Sa densité vient de ses voisines, sa pression de sa densité, et ses
## forces de la pression et de la vitesse de ses voisines. Comparer chaque particule à toutes les autres coûterait n² : une grille de
## voisinage, faite de listes chaînées, ne regarde que les neuf cases autour.

## Les réglages de ce liquide.
var settings: SphSettings
## La place des particules.
var positions: PackedVector2Array = PackedVector2Array()
## La vitesse des particules.
var velocities: PackedVector2Array = PackedVector2Array()
## La densité de chaque particule, au dernier calcul.
var densities: PackedFloat32Array = PackedFloat32Array()
## La pression de chaque particule, au dernier calcul.
var pressures: PackedFloat32Array = PackedFloat32Array()

var _mass: float = 0.0
var _columns: int = 0
var _rows: int = 0
var _heads: PackedInt32Array = PackedInt32Array()
var _links: PackedInt32Array = PackedInt32Array()
var _forces: PackedVector2Array = PackedVector2Array()


func _init(sph_settings: SphSettings) -> void:
	settings = sph_settings
	_mass = settings.rest_density * settings.spacing * settings.spacing
	_columns = ceili(settings.width / settings.radius)
	_rows = ceili(settings.height / settings.radius)
	_heads.resize(_columns * _rows)


## Remplit de liquide immobile le rectangle de `first` à `last`, à l'écart `settings.spacing`.
func add_block(first: Vector2, last: Vector2) -> void:
	var y: float = first.y
	while y <= last.y:
		var x: float = first.x
		while x <= last.x:
			positions.append(Vector2(x, y))
			velocities.append(Vector2.ZERO)
			x += settings.spacing
		y += settings.spacing
	densities.resize(positions.size())
	pressures.resize(positions.size())
	_links.resize(positions.size())
	_forces.resize(positions.size())


## La case de la grille de voisinage où tombe le point `place`.
func cell_of(place: Vector2) -> Vector2i:
	return Vector2i(clampi(floori(place.x / settings.radius), 0, _columns - 1), clampi(floori(place.y / settings.radius), 0, _rows - 1))


## Range les particules dans leurs cases : `_heads` donne la première de chaque case, `_links` la suivante de la même case, -1 à la fin.
func rebuild_neighbours() -> void:
	_heads.fill(-1)
	for i: int in positions.size():
		var cell: Vector2i = cell_of(positions[i])
		var slot: int = cell.y * _columns + cell.x
		_links[i] = _heads[slot]
		_heads[slot] = i


## Les particules à portée de `place`, dont elle-même si elle en est une, trouvées dans les neuf cases autour d'elle.
func neighbours_of(place: Vector2) -> PackedInt32Array:
	var found: PackedInt32Array = PackedInt32Array()
	var center: Vector2i = cell_of(place)
	var reach: float = settings.radius * settings.radius
	for y: int in range(maxi(center.y - 1, 0), mini(center.y + 2, _rows)):
		for x: int in range(maxi(center.x - 1, 0), mini(center.x + 2, _columns)):
			var j: int = _heads[y * _columns + x]
			while j != -1:
				if place.distance_squared_to(positions[j]) < reach:
					found.append(j)
				j = _links[j]
	return found


## Remplit `densities` : la somme des masses voisines, pesée par la distance, et `pressures` : l'écart à la densité de repos. Une
## pression négative tirerait les particules les unes vers les autres, et les ferait s'agglutiner : elle reste à zéro.
func update_densities() -> void:
	for i: int in positions.size():
		var density: float = 0.0
		for j: int in neighbours_of(positions[i]):
			density += _mass * SphKernels.density_weight(positions[i].distance_squared_to(positions[j]), settings.radius)
		densities[i] = density
		pressures[i] = maxf(settings.stiffness * (density - settings.rest_density), 0.0)


## Remplit `_forces` : la pression pousse les voisines, la viscosité rapproche leurs vitesses. Une paire exerce des forces opposées :
## la formule partage la pression des deux particules, et la quantité de mouvement se conserve.
func update_forces() -> void:
	for i: int in positions.size():
		var force: Vector2 = Vector2.ZERO
		for j: int in neighbours_of(positions[i]):
			if j != i:
				force += _force_between(i, j)
		_forces[i] = force


## La force que `j` exerce sur `i`.
func _force_between(i: int, j: int) -> Vector2:
	var offset: Vector2 = positions[i] - positions[j]
	var distance: float = maxf(offset.length(), 0.0001)
	var shared: float = (pressures[i] + pressures[j]) / (2.0 * densities[i] * densities[j])
	var push: Vector2 = -_mass * _mass * shared * SphKernels.pressure_slope(distance, settings.radius) * offset / distance
	var pull: float = settings.viscosity * _mass * _mass / (densities[i] * densities[j]) * SphKernels.viscosity_curve(distance, settings.radius)
	return push + pull * (velocities[j] - velocities[i])


## Avance de `delta` secondes, en `settings.substeps` petits pas.
func step(delta: float) -> void:
	var small: float = delta / settings.substeps
	for _pas: int in settings.substeps:
		rebuild_neighbours()
		update_densities()
		update_forces()
		_integrate(small)


## Applique les forces et la gravité, déplace les particules, et les fait rebondir sur les parois de la cuve.
func _integrate(delta: float) -> void:
	var limit: Vector2 = Vector2(settings.width, settings.height)
	for i: int in positions.size():
		var speed: Vector2 = velocities[i] + delta * (_forces[i] / _mass + Vector2(0.0, settings.gravity))
		var place: Vector2 = positions[i] + delta * speed
		if place.x < 0.0 or place.x > limit.x:
			speed.x *= -settings.bounce
		if place.y < 0.0 or place.y > limit.y:
			speed.y *= -settings.bounce
		velocities[i] = speed
		positions[i] = place.clamp(Vector2.ZERO, limit)
