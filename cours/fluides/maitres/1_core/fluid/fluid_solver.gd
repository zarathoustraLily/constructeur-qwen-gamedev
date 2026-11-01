class_name FluidSolver extends RefCounted
## Le fluide complet, un pas à la fois : on rend la vitesse sans divergence, elle se transporte elle-même, on la projette de
## nouveau ; puis elle emporte la matière. Chaque champ a son double de travail, échangé après chaque passe : un pas ne crée
## aucun objet.
#@ 6+
## Les murs (`walls`) arrêtent le fluide.
#@ 7+
## Le transport peut être celui de MacCormack (`settings.sharp_transport`).
#@ 8+
## Le confinement rend ses tourbillons au fluide.
#@ 9+
## Avec un feu (`fire`), le carburant brûle, chauffe, laisse de la suie et dilate le gaz.
#@ all

## Les réglages de ce fluide.
var settings: FluidSettings
## La matière transportée.
var density: FluidField
## La vitesse horizontale, en cases par seconde.
var u: FluidField
## La vitesse verticale, en cases par seconde (les y vont vers le bas).
var v: FluidField
#@ 6+
## Les murs.
var walls: ObstacleMask
#@ 9+
## Les réglages du feu ; sans eux, le solveur ne fait que de la fumée.
var fire: FireSettings
## Le carburant.
var fuel: FluidField
## La température.
var temperature: FluidField
## La suie.
var soot: FluidField
#@ all

var _next: FluidField
var _next_u: FluidField
var _next_v: FluidField
var _pressure: FluidField
var _divergence: FluidField
#@ 7+
var _forward: FluidField
var _backward: FluidField
#@ 8+
var _spin: FluidField
#@ 9+
var _expansion: FluidField
#@ all


func _init(fluid_settings: FluidSettings) -> void:
	settings = fluid_settings
	density = _grid()
	u = _grid()
	v = _grid()
	_next = _grid()
	_next_u = _grid()
	_next_v = _grid()
	_pressure = _grid()
	_divergence = _grid()
#@ 6+
	walls = ObstacleMask.new(settings.width, settings.height)
#@ 7+
	_forward = _grid()
	_backward = _grid()
#@ 8+
	_spin = _grid()
#@ 9+
	fuel = _grid()
	temperature = _grid()
	soot = _grid()
	_expansion = _grid()
#@ all


## Avance de `delta` secondes.
func step(delta: float) -> void:
#@ 9+
	if fire != null:
		_step_fire(delta)
#@ all
	_step_velocity(delta)
	_step_matter(delta)


## Pousse le fluide : ajoute (`force_x`, `force_y`) à la vitesse dans le disque de centre (`x`, `y`).
func add_force(x: float, y: float, radius: float, force_x: float, force_y: float) -> void:
	u.add_disc(x, y, radius, force_x)
	v.add_disc(x, y, radius, force_y)


## La vitesse d'un pas : diffusée si le fluide est épais, projetée, transportée par elle-même, projetée de nouveau.
func _step_velocity(delta: float) -> void:
#@ 8+
	if settings.vortex_strength > 0.0:
		Vorticity.curl(_spin, u, v)
		Vorticity.confine(u, v, _spin, settings.vortex_strength, delta)
#@ all
	if settings.viscosity > 0.0:
		Diffusion.solve(_next_u, u, settings.viscosity, delta, settings.iterations)
		Diffusion.solve(_next_v, v, settings.viscosity, delta, settings.iterations)
		_swap_velocity()
	_project()
	_transport(_next_u, u, delta)
	_transport(_next_v, v, delta)
	_swap_velocity()
	_project()


## La matière d'un pas : transportée, étalée si le fluide l'étale, puis un peu perdue.
func _step_matter(delta: float) -> void:
	_transport(_next, density, delta)
	var moved: FluidField = density
	density = _next
	_next = moved
	if settings.diffusion > 0.0:
		Diffusion.solve(_next, density, settings.diffusion, delta, settings.iterations)
		moved = density
		density = _next
		_next = moved
	var kept: float = exp(-settings.dissipation * delta)
	for i: int in density.data.size():
		density.data[i] *= kept
#@ 6+
	walls.clear_inside(density)
#@ 9+
	if fire != null:
		_transport_fire(delta)
#@ all


## Remplit `target` avec `source` transporté par la vitesse.
func _transport(target: FluidField, source: FluidField, delta: float) -> void:
#@ 5-6
	Advection.semi_lagrangian(target, source, u, v, delta)
#@ 7+
	if settings.sharp_transport:
		Advection.mac_cormack(target, source, u, v, delta, _forward, _backward)
	else:
		Advection.semi_lagrangian(target, source, u, v, delta)
#@ all


## Rend la vitesse sans divergence.
func _project() -> void:
#@ 5
	FluidProjection.divergence(_divergence, u, v)
	FluidProjection.solve_pressure(_pressure, _divergence, settings.iterations, settings.relaxation)
	FluidProjection.subtract_gradient(u, v, _pressure)
#@ 6+
	FluidProjection.divergence(_divergence, u, v, walls)
#@ 9+
	for i: int in _divergence.data.size():
		_divergence.data[i] -= _expansion.data[i]
#@ 6+
	FluidProjection.solve_pressure(_pressure, _divergence, walls, settings.iterations, settings.relaxation)
	FluidProjection.subtract_gradient(u, v, _pressure, walls)
	walls.clear_inside(u)
	walls.clear_inside(v)
	walls.stop_at_walls(u, v)
#@ all


## Échange la vitesse et son double de travail.
func _swap_velocity() -> void:
	var kept_u: FluidField = u
	var kept_v: FluidField = v
	u = _next_u
	v = _next_v
	_next_u = kept_u
	_next_v = kept_v
#@ 9+


## Le feu avant la vitesse : ce qui brûle, ce qui monte.
func _step_fire(delta: float) -> void:
	Combustion.burn(fuel, temperature, soot, _expansion, fire, delta)
	Combustion.lift(v, temperature, soot, fire, delta)


## Le feu après la vitesse : carburant, chaleur et suie suivent le courant, puis la chaleur se perd.
func _transport_fire(delta: float) -> void:
	fuel = _carried(fuel, delta)
	temperature = _carried(temperature, delta)
	soot = _carried(soot, delta)
	Combustion.cool(temperature, fire.cooling, delta)
	walls.clear_inside(fuel)
	walls.clear_inside(temperature)
	walls.clear_inside(soot)


## `field` transporté, dans le double de travail ; `field` devient le nouveau double.
func _carried(field: FluidField, delta: float) -> FluidField:
	_transport(_next, field, delta)
	var moved: FluidField = _next
	_next = field
	return moved
#@ all


## Un champ vide, à la taille de la grille.
func _grid() -> FluidField:
	return FluidField.new(settings.width, settings.height)
