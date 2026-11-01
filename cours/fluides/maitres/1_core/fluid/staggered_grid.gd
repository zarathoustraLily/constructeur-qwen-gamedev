class_name StaggeredGrid extends RefCounted
## La grille décalée : la pression reste au centre des cases, mais chaque vitesse vit sur la face qu'elle traverse. `u` a une colonne
## de plus que la grille, `v` une ligne de plus. La divergence et la pente lisent alors des faces voisines, à la même distance que la
## pression : les trois formules s'emboîtent exactement, et la projection annule vraiment la divergence, là où `FluidProjection` garde
## un résidu que le nombre de passes ne change pas.

## La largeur de la grille, en cases.
var width: int = 0
## La hauteur de la grille, en cases.
var height: int = 0
## La vitesse à travers les faces verticales : `width + 1` colonnes, `height` lignes.
var u: FluidField
## La vitesse à travers les faces horizontales : `width` colonnes, `height + 1` lignes.
var v: FluidField
## La pression, au centre des cases.
var pressure: FluidField

var _next_u: FluidField
var _next_v: FluidField


func _init(columns: int, rows: int) -> void:
	width = columns
	height = rows
	u = FluidField.new(columns + 1, rows)
	v = FluidField.new(columns, rows + 1)
	pressure = FluidField.new(columns, rows)
	_next_u = FluidField.new(columns + 1, rows)
	_next_v = FluidField.new(columns, rows + 1)


## Ce qui sort de la case (x, y), moins ce qui y entre : ses quatre faces, à une case de distance.
func divergence_at(x: int, y: int) -> float:
	return u.at(x + 1, y) - u.at(x, y) + v.at(x, y + 1) - v.at(x, y)


## La plus grande divergence de la grille, signe oublié.
func largest_divergence() -> float:
	var largest: float = 0.0
	for y: int in height:
		for x: int in width:
			largest = maxf(largest, absf(divergence_at(x, y)))
	return largest


## Ferme le tour de la grille : aucune vitesse à travers ses faces extérieures.
func close_border() -> void:
	for y: int in height:
		u.put(0, y, 0.0)
		u.put(width, y, 0.0)
	for x: int in width:
		v.put(x, 0, 0.0)
		v.put(x, height, 0.0)


## Remplit `pressure` : `iterations` passes rouge-noir, surrelaxées de `relaxation`. Une case du bord a moins de voisines, et la
## moyenne se fait sur celles qui existent : un mur n'échange rien.
func solve_pressure(iterations: int, relaxation: float) -> void:
	for _pass: int in iterations:
		for color: int in 2:
			for y: int in height:
				for x: int in range((y + color) % 2, width, 2):
					pressure.put(x, y, lerpf(pressure.at(x, y), _settled(x, y), relaxation))


## La pression que vise la case (x, y) : la moyenne de ses voisines, moins sa divergence partagée entre elles.
func _settled(x: int, y: int) -> float:
	var around: float = 0.0
	var neighbours: int = 0
	if x > 0:
		around += pressure.at(x - 1, y)
		neighbours += 1
	if x < width - 1:
		around += pressure.at(x + 1, y)
		neighbours += 1
	if y > 0:
		around += pressure.at(x, y - 1)
		neighbours += 1
	if y < height - 1:
		around += pressure.at(x, y + 1)
		neighbours += 1
	return (around - divergence_at(x, y)) / neighbours


## Retire à chaque face intérieure l'écart de pression entre ses deux cases.
func subtract_gradient() -> void:
	for y: int in height:
		for x: int in range(1, width):
			u.put(x, y, u.at(x, y) - (pressure.at(x, y) - pressure.at(x - 1, y)))
	for y: int in range(1, height):
		for x: int in width:
			v.put(x, y, v.at(x, y) - (pressure.at(x, y) - pressure.at(x, y - 1)))


#@ 25+
## Remplit `pressure` pour un liquide : seules les cases de `full` comptent. L'air ne pousse pas : une case vide compte pour une pression
## nulle, alors qu'un mur n'échange rien. `pressure` doit être vide au départ.
func solve_water_pressure(full: PackedByteArray, iterations: int, relaxation: float) -> void:
	for _pass: int in iterations:
		for color: int in 2:
			for y: int in height:
				for x: int in range((y + color) % 2, width, 2):
					if full[y * width + x] != 0:
						pressure.put(x, y, lerpf(pressure.at(x, y), _settled_in_water(full, x, y), relaxation))


## La pression que vise une case d'eau : ses voisines d'eau comptent, l'air compte pour zéro, et un mur ne compte pas.
func _settled_in_water(full: PackedByteArray, x: int, y: int) -> float:
	var around: float = 0.0
	var neighbours: int = 0
	for side: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var other: Vector2i = Vector2i(x, y) + side
		if other.x >= 0 and other.y >= 0 and other.x < width and other.y < height:
			neighbours += 1
			if full[other.y * width + other.x] != 0:
				around += pressure.at(other.x, other.y)
	return (around - divergence_at(x, y)) / neighbours


## Retire la pente de la pression aux faces qui touchent de l'eau ; les autres gardent leur vitesse.
func subtract_water_gradient(full: PackedByteArray) -> void:
	for y: int in height:
		for x: int in range(1, width):
			if full[y * width + x] != 0 or full[y * width + x - 1] != 0:
				u.put(x, y, u.at(x, y) - (pressure.at(x, y) - pressure.at(x - 1, y)))
	for y: int in range(1, height):
		for x: int in width:
			if full[y * width + x] != 0 or full[(y - 1) * width + x] != 0:
				v.put(x, y, v.at(x, y) - (pressure.at(x, y) - pressure.at(x, y - 1)))


#@ all
## Rend la vitesse sans divergence.
func project(iterations: int, relaxation: float) -> void:
	close_border()
	solve_pressure(iterations, relaxation)
	subtract_gradient()


## La vitesse au point (x, y), le centre de la case (0, 0) étant au point (0, 0) : `u` est décalée d'une demi-case en x, `v` en y.
func velocity_at(x: float, y: float) -> Vector2:
	return Vector2(u.sample(x + 0.5, y), v.sample(x, y + 0.5))


## Transporte la vitesse par elle-même pendant `delta` secondes : chaque face remonte le courant depuis sa propre place.
func transport(delta: float) -> void:
	for y: int in height:
		for x: int in width + 1:
			var from_x: Vector2 = Vector2(x - 0.5, y) - delta * velocity_at(x - 0.5, y)
			_next_u.put(x, y, u.sample(from_x.x + 0.5, from_x.y))
	for y: int in height + 1:
		for x: int in width:
			var from_y: Vector2 = Vector2(x, y - 0.5) - delta * velocity_at(x, y - 0.5)
			_next_v.put(x, y, v.sample(from_y.x, from_y.y + 0.5))
	var kept_u: FluidField = u
	var kept_v: FluidField = v
	u = _next_u
	v = _next_v
	_next_u = kept_u
	_next_v = kept_v
