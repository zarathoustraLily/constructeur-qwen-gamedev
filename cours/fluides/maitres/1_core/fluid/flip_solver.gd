class_name FlipSolver extends RefCounted
## De l'eau en particules. Une grille efface les détails et perd de la matière ; des particules, non, mais elles ne savent pas rester
## incompressibles. FLIP prend le meilleur des deux : les particules portent l'eau, et la grille ne sert qu'un instant, à chaque pas.
## On y dépose leur vitesse, on la rend sans divergence, et chaque particule ne reprend que ce qui a changé sur la grille.

## Les réglages de cette eau.
var settings: FlipSettings
## La grille du pas en cours.
var grid: StaggeredGrid
## La place des particules, en cases.
var positions: PackedVector2Array = PackedVector2Array()
## La vitesse des particules, en cases par seconde.
var velocities: PackedVector2Array = PackedVector2Array()

var _full: PackedByteArray = PackedByteArray()
var _weight_u: FluidField
var _weight_v: FluidField
var _before_u: FluidField
var _before_v: FluidField


func _init(flip_settings: FlipSettings) -> void:
	settings = flip_settings
	grid = StaggeredGrid.new(settings.width, settings.height)
	_full.resize(settings.width * settings.height)
	_weight_u = FluidField.new(settings.width + 1, settings.height)
	_weight_v = FluidField.new(settings.width, settings.height + 1)
	_before_u = FluidField.new(settings.width + 1, settings.height)
	_before_v = FluidField.new(settings.width, settings.height + 1)


## Remplit d'eau immobile le rectangle de `first` à `last`, une particule tous les `spacing` cases.
func add_block(first: Vector2, last: Vector2, spacing: float) -> void:
	var y: float = first.y
	while y <= last.y:
		var x: float = first.x
		while x <= last.x:
			positions.append(Vector2(x, y))
			velocities.append(Vector2.ZERO)
			x += spacing
		y += spacing


## Vrai si la case (x, y) contient de l'eau, au dernier pas.
func is_full(x: int, y: int) -> bool:
	return _full[y * settings.width + x] != 0


## Avance de `delta` secondes.
func step(delta: float) -> void:
	_to_grid()
	_mark_water()
	_before_u.copy_from(grid.u)
	_before_v.copy_from(grid.v)
	for i: int in grid.v.data.size():
		grid.v.data[i] += settings.gravity * delta
	grid.close_border()
	grid.pressure.fill(0.0)
	grid.solve_water_pressure(_full, settings.iterations, settings.relaxation)
	grid.subtract_water_gradient(_full)
	grid.close_border()
	_to_particles()
	_move(delta)


## Dépose la vitesse des particules sur les faces : chaque face reçoit la moyenne de ce qui l'entoure, pesée par la distance.
func _to_grid() -> void:
	grid.u.fill(0.0)
	grid.v.fill(0.0)
	_weight_u.fill(0.0)
	_weight_v.fill(0.0)
	for i: int in positions.size():
		_splat(grid.u, _weight_u, positions[i].x + 0.5, positions[i].y, velocities[i].x)
		_splat(grid.v, _weight_v, positions[i].x, positions[i].y + 0.5, velocities[i].y)
	_average(grid.u, _weight_u)
	_average(grid.v, _weight_v)


## Ajoute `value` aux quatre valeurs de `field` autour du point (x, y), et leur poids à `weights`.
func _splat(field: FluidField, weights: FluidField, x: float, y: float, value: float) -> void:
	var left: int = clampi(floori(x), 0, field.width - 2)
	var top: int = clampi(floori(y), 0, field.height - 2)
	var across: float = clampf(x - left, 0.0, 1.0)
	var down: float = clampf(y - top, 0.0, 1.0)
	_add(field, weights, left, top, value, (1.0 - across) * (1.0 - down))
	_add(field, weights, left + 1, top, value, across * (1.0 - down))
	_add(field, weights, left, top + 1, value, (1.0 - across) * down)
	_add(field, weights, left + 1, top + 1, value, across * down)


func _add(field: FluidField, weights: FluidField, x: int, y: int, value: float, weight: float) -> void:
	field.put(x, y, field.at(x, y) + value * weight)
	weights.put(x, y, weights.at(x, y) + weight)


## Divise `field` par `weights`, là où quelque chose s'est déposé.
func _average(field: FluidField, weights: FluidField) -> void:
	for i: int in field.data.size():
		if weights.data[i] > 0.0:
			field.data[i] /= weights.data[i]


## Note les cases qui contiennent au moins une particule : les autres sont de l'air.
func _mark_water() -> void:
	_full.fill(0)
	for place: Vector2 in positions:
		var x: int = clampi(roundi(place.x), 0, settings.width - 1)
		var y: int = clampi(roundi(place.y), 0, settings.height - 1)
		_full[y * settings.width + x] = 1


## Rend la vitesse aux particules. PIC reprend la vitesse de la grille, et l'amortit ; FLIP n'ajoute que ce qui a changé sur la grille.
func _to_particles() -> void:
	for i: int in positions.size():
		var place: Vector2 = positions[i]
		var now: Vector2 = grid.velocity_at(place.x, place.y)
		var before: Vector2 = Vector2(_before_u.sample(place.x + 0.5, place.y), _before_v.sample(place.x, place.y + 0.5))
		velocities[i] = now.lerp(velocities[i] + now - before, settings.flip_ratio)


## Déplace les particules dans le courant de la grille, en lisant la vitesse à mi-chemin, et les garde dans la cuve.
func _move(delta: float) -> void:
	var low: Vector2 = Vector2(-0.45, -0.45)
	var high: Vector2 = Vector2(settings.width - 0.55, settings.height - 0.55)
	for i: int in positions.size():
		var start: Vector2 = positions[i]
		var middle: Vector2 = start + 0.5 * delta * grid.velocity_at(start.x, start.y)
		positions[i] = (start + delta * grid.velocity_at(middle.x, middle.y)).clamp(low, high)
