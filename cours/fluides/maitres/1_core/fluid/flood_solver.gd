class_name FloodSolver extends RefCounted
## L'eau peu profonde : une profondeur par case, posée sur un sol. Entre deux cases voisines, un tuyau : l'écart des niveaux y pousse
## l'eau, et le débit a de l'élan. C'est la méthode des tuyaux virtuels : chaque goutte qui quitte une case arrive dans une autre, et
## l'eau ne se perd jamais.

## Les réglages de l'eau.
var settings: FloodSettings
## La hauteur du sol.
var ground: FluidField
## La profondeur de l'eau.
var depth: FluidField

var _next: FluidField
var _right: FluidField
var _left: FluidField
var _down: FluidField
var _up: FluidField


func _init(flood_settings: FloodSettings, terrain: FluidField) -> void:
	settings = flood_settings
	ground = terrain
	depth = FluidField.new(settings.width, settings.height)
	_next = FluidField.new(settings.width, settings.height)
	_right = FluidField.new(settings.width, settings.height)
	_left = FluidField.new(settings.width, settings.height)
	_down = FluidField.new(settings.width, settings.height)
	_up = FluidField.new(settings.width, settings.height)


## Le niveau de l'eau en (`x`, `y`) : c'est lui qui fait couler, pas le sol.
func level(x: int, y: int) -> float:
	return depth.at(x, y) + ground.at(x, y)


## Verse `amount` d'eau dans le disque de rayon `radius` : le plus au centre, rien au bord.
func add_water(center_x: float, center_y: float, radius: float, amount: float) -> void:
	depth.add_disc(center_x, center_y, radius, amount)


## Avance de `delta` secondes. Une onde va à la racine de `pull` : c'est la même limite que pour les vagues.
func step(delta: float) -> void:
	var count: int = WaveSolver.substeps(delta, sqrt(settings.pull))
	var part: float = delta / count
	for _i: int in count:
		_update_flows(part)
		_move_water(part)


## Les débits sortants de chaque case. Une case ne peut pas donner plus d'eau qu'elle n'en a : au-delà, ses débits sont réduits d'autant.
func _update_flows(delta: float) -> void:
	for y: int in depth.height:
		for x: int in depth.width:
			var here: float = level(x, y)
			var right: float = _pushed(_right.at(x, y), here, x + 1, y, delta)
			var left: float = _pushed(_left.at(x, y), here, x - 1, y, delta)
			var down: float = _pushed(_down.at(x, y), here, x, y + 1, delta)
			var up: float = _pushed(_up.at(x, y), here, x, y - 1, delta)
			var leaving: float = (right + left + down + up) * delta
			var share: float = 1.0
			if leaving > depth.at(x, y):
				share = depth.at(x, y) / leaving
			_right.put(x, y, right * share)
			_left.put(x, y, left * share)
			_down.put(x, y, down * share)
			_up.put(x, y, up * share)


## Le débit vers la voisine (`x`, `y`) : il garde son élan, et l'écart des niveaux le pousse. Rien ne sort de la grille, et un tuyau ne
## coule que dans un sens : le débit inverse est celui de la voisine.
func _pushed(kept: float, here: float, x: int, y: int, delta: float) -> float:
	if x < 0 or y < 0 or x >= depth.width or y >= depth.height:
		return 0.0
	return maxf(0.0, kept * settings.friction + delta * settings.pull * (here - level(x, y)))


## Chaque case reçoit ce que ses voisines lui envoient, et perd ce qu'elle leur donne.
func _move_water(delta: float) -> void:
	for y: int in depth.height:
		for x: int in depth.width:
			var arriving: float = _flow_at(_right, x - 1, y) + _flow_at(_left, x + 1, y) + _flow_at(_down, x, y - 1) + _flow_at(_up, x, y + 1)
			var leaving: float = _right.at(x, y) + _left.at(x, y) + _down.at(x, y) + _up.at(x, y)
			_next.put(x, y, depth.at(x, y) + delta * (arriving - leaving))
	var kept: FluidField = depth
	depth = _next
	_next = kept


## Le débit de `flow` en (`x`, `y`) ; rien hors de la grille.
func _flow_at(flow: FluidField, x: int, y: int) -> float:
	if x < 0 or y < 0 or x >= depth.width or y >= depth.height:
		return 0.0
	return flow.at(x, y)
