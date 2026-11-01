class_name GpuSph extends RefCounted
## SPH sur la carte : le même pas que `SphSolver`, avec des tampons au lieu de tableaux. La grille de voisinage reste faite de listes
## chaînées, mais toutes les particules s'y rangent en même temps, par un échange atomique. Les réglages et les particules de départ
## ne changent pas : le processeur reste le juge.

const GROUP := 64
const CLEAR := "res://1_core/gpu/shaders/sph_clear.glsl"
const LINK := "res://1_core/gpu/shaders/sph_link.glsl"
const DENSITY := "res://1_core/gpu/shaders/sph_density.glsl"
const FORCE := "res://1_core/gpu/shaders/sph_force.glsl"
const MOVE := "res://1_core/gpu/shaders/sph_move.glsl"

## Les réglages de ce liquide.
var settings: SphSettings
## La place des particules.
var positions: RID
## La vitesse des particules.
var velocities: RID
## La densité de chaque particule.
var densities: RID
## La pression de chaque particule.
var pressures: RID
## La première particule de chaque case de la grille de voisinage.
var heads: RID
## La suivante de chaque particule dans sa case.
var links: RID
## La force sur chaque particule.
var forces: RID

var _mass: float = 0.0
var _columns: int = 0
var _rows: int = 0
var _particle_groups: Vector3i
var _cell_groups: Vector3i
var _clear: ComputePass
var _link: ComputePass
var _density: ComputePass
var _force: ComputePass
var _move: ComputePass


func _init(device: ComputeDevice, sph_settings: SphSettings, start: PackedVector2Array) -> void:
	settings = sph_settings
	_mass = settings.rest_density * settings.spacing * settings.spacing
	_columns = ceili(settings.width / settings.radius)
	_rows = ceili(settings.height / settings.radius)
	var count: int = start.size()
	var still: PackedVector2Array = PackedVector2Array()
	still.resize(count)
	var nothing: PackedFloat32Array = PackedFloat32Array()
	nothing.resize(count)
	positions = device.new_vector_buffer(start)
	velocities = device.new_vector_buffer(still)
	forces = device.new_vector_buffer(still)
	densities = device.new_buffer(nothing)
	pressures = device.new_buffer(nothing)
	heads = device.new_int_buffer(_columns * _rows)
	links = device.new_int_buffer(count)
	_particle_groups = Vector3i(ComputePass.groups_for(count, GROUP), 1, 1)
	_cell_groups = Vector3i(ComputePass.groups_for(_columns * _rows, GROUP), 1, 1)
	_clear = ComputePass.new(device, CLEAR)
	_link = ComputePass.new(device, LINK)
	_density = ComputePass.new(device, DENSITY)
	_force = ComputePass.new(device, FORCE)
	_move = ComputePass.new(device, MOVE)


## Range les particules dans leurs cases.
func rebuild_neighbours() -> void:
	_clear.run([heads], PackedFloat32Array(), _cell_groups)
	_link.run([positions, heads, links], PackedFloat32Array([settings.radius, _columns, _rows]), _particle_groups)


## Remplit `densities` et `pressures`.
func update_densities() -> void:
	var constants: PackedFloat32Array = PackedFloat32Array([settings.radius, _columns, _rows, _mass, settings.rest_density,
			settings.stiffness])
	_density.run([positions, heads, links, densities, pressures], constants, _particle_groups)


## Remplit `forces`.
func update_forces() -> void:
	var constants: PackedFloat32Array = PackedFloat32Array([settings.radius, _columns, _rows, _mass, settings.viscosity])
	_force.run([positions, velocities, densities, pressures, heads, links, forces], constants, _particle_groups)


## Avance de `delta` secondes, en `settings.substeps` petits pas.
func step(delta: float) -> void:
	var small: float = delta / settings.substeps
	var constants: PackedFloat32Array = PackedFloat32Array([small, _mass, settings.gravity, settings.bounce, settings.width,
			settings.height])
	for _pas: int in settings.substeps:
		rebuild_neighbours()
		update_densities()
		update_forces()
		_move.run([positions, velocities, forces], constants, _particle_groups)
