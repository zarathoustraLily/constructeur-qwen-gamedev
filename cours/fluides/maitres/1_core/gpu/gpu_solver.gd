class_name GpuSolver extends RefCounted
## Le fluide complet sur la carte : le même pas que `FluidSolver`, passe après passe, sur les mêmes réglages. Chaque champ est une
## texture, avec son double de travail échangé après chaque passe. `step` ne fait que préparer le travail : `ComputeDevice.finish`
## ou une lecture le fait exécuter.
#@ 15+
## Avec un feu (`fire`), le carburant brûle, chauffe, laisse de la suie et dilate le gaz.
#@ all

## Les réglages du fluide.
var settings: FluidSettings
## La carte.
var device: ComputeDevice
## Les murs : à modifier ici, puis à envoyer par `update_walls`.
var walls: ObstacleMask
## La matière transportée.
var density: RID
## La vitesse horizontale, en cases par seconde.
var u: RID
## La vitesse verticale, en cases par seconde (les y vont vers le bas).
var v: RID
#@ 15+
## Les réglages du feu ; sans eux, le solveur ne fait que de la fumée.
var fire: FireSettings
## Le carburant.
var fuel: RID
## La température.
var temperature: RID
## La suie.
var soot: RID
#@ all

var _next: RID
var _next_u: RID
var _next_v: RID
var _pressure: RID
var _divergence: RID
var _forward: RID
var _backward: RID
var _spin: RID
var _mask: RID
#@ 15+
var _expansion: RID
var _combustion: GpuCombustion
#@ all
var _ops: GpuFieldOps
var _advection: GpuAdvection
var _projection: GpuProjection
var _diffusion: GpuDiffusion
var _vorticity: GpuVorticity


func _init(compute: ComputeDevice, fluid_settings: FluidSettings) -> void:
	device = compute
	settings = fluid_settings
	var width: int = settings.width
	var height: int = settings.height
	walls = ObstacleMask.new(width, height)
	_mask = device.new_mask(walls)
	density = device.new_texture(width, height)
	u = device.new_texture(width, height)
	v = device.new_texture(width, height)
	_next = device.new_texture(width, height)
	_next_u = device.new_texture(width, height)
	_next_v = device.new_texture(width, height)
	_pressure = device.new_texture(width, height)
	_divergence = device.new_texture(width, height)
	_forward = device.new_texture(width, height)
	_backward = device.new_texture(width, height)
	_spin = device.new_texture(width, height)
#@ 15+
	fuel = device.new_texture(width, height)
	temperature = device.new_texture(width, height)
	soot = device.new_texture(width, height)
	_expansion = device.new_texture(width, height)
	_combustion = GpuCombustion.new(device, width, height)
#@ all
	_ops = GpuFieldOps.new(device, width, height)
	_advection = GpuAdvection.new(device, width, height)
	_projection = GpuProjection.new(device, width, height)
	_diffusion = GpuDiffusion.new(device, width, height)
	_vorticity = GpuVorticity.new(device, width, height)


## Envoie à la carte les murs modifiés.
func update_walls() -> void:
	device.rd.texture_update(_mask, 0, walls.solid)


## Avance de `delta` secondes.
func step(delta: float) -> void:
#@ 15+
	if fire != null:
		_step_fire(delta)
#@ all
	_step_velocity(delta)
	_step_matter(delta)


## Ajoute `amount` à `field` dans le disque de centre (`x`, `y`).
func add_matter(field: RID, x: float, y: float, radius: float, amount: float) -> void:
	_ops.add_disc(field, x, y, radius, amount)


## Pousse le fluide : ajoute (`force_x`, `force_y`) à la vitesse dans le disque de centre (`x`, `y`).
func add_force(x: float, y: float, radius: float, force_x: float, force_y: float) -> void:
	_ops.add_disc(u, x, y, radius, force_x)
	_ops.add_disc(v, x, y, radius, force_y)


## La vitesse d'un pas, dans l'ordre de `FluidSolver._step_velocity`.
func _step_velocity(delta: float) -> void:
	if settings.vortex_strength > 0.0:
		_vorticity.curl(_spin, u, v)
		_vorticity.confine(u, v, _spin, settings.vortex_strength, delta)
	if settings.viscosity > 0.0:
		_diffusion.solve(_next_u, u, settings.viscosity, delta, settings.iterations)
		_diffusion.solve(_next_v, v, settings.viscosity, delta, settings.iterations)
		_swap_velocity()
	_project()
	_transport(_next_u, u, delta)
	_transport(_next_v, v, delta)
	_swap_velocity()
	_project()


## La matière d'un pas : transportée, étalée si le fluide l'étale, puis un peu perdue.
func _step_matter(delta: float) -> void:
	_transport(_next, density, delta)
	_swap_density()
	if settings.diffusion > 0.0:
		_diffusion.solve(_next, density, settings.diffusion, delta, settings.iterations)
		_swap_density()
	_ops.scale(density, exp(-settings.dissipation * delta))
	_ops.clear_walls(density, _mask)
#@ 15+
	if fire != null:
		_transport_fire(delta)
#@ all


## Remplit `target` avec `source` transporté par la vitesse.
func _transport(target: RID, source: RID, delta: float) -> void:
	if settings.sharp_transport:
		_advection.mac_cormack(target, source, u, v, delta, _forward, _backward)
	else:
		_advection.semi_lagrangian(target, source, u, v, delta)


## Rend la vitesse sans divergence, et l'arrête aux murs.
func _project() -> void:
	_projection.divergence(_divergence, u, v, _mask)
#@ 15+
	_ops.add_scaled(_divergence, _expansion, -1.0)
#@ all
	_projection.solve_pressure(_pressure, _divergence, _mask, settings.iterations, settings.relaxation)
	_projection.subtract_gradient(u, v, _pressure, _mask)
	_ops.clear_walls(u, _mask)
	_ops.clear_walls(v, _mask)
	_ops.stop_at_walls(u, v, _mask)


## Échange la vitesse et son double de travail.
func _swap_velocity() -> void:
	var kept_u: RID = u
	var kept_v: RID = v
	u = _next_u
	v = _next_v
	_next_u = kept_u
	_next_v = kept_v


## Échange la matière et son double de travail.
func _swap_density() -> void:
	var kept: RID = density
	density = _next
	_next = kept
#@ 15+


## Le feu avant la vitesse : ce qui brûle, ce qui monte.
func _step_fire(delta: float) -> void:
	_combustion.burn(fuel, temperature, soot, _expansion, fire, delta)
	_combustion.lift(v, temperature, soot, fire, delta)


## Le feu après la vitesse : carburant, chaleur et suie suivent le courant, puis la chaleur se perd.
func _transport_fire(delta: float) -> void:
	fuel = _carried(fuel, delta)
	temperature = _carried(temperature, delta)
	soot = _carried(soot, delta)
	_ops.scale(temperature, exp(-fire.cooling * delta))
	_ops.clear_walls(fuel, _mask)
	_ops.clear_walls(temperature, _mask)
	_ops.clear_walls(soot, _mask)


## `field` transporté, dans le double de travail ; `field` devient le nouveau double.
func _carried(field: RID, delta: float) -> RID:
	_transport(_next, field, delta)
	var moved: RID = _next
	_next = field
	return moved
#@ all
