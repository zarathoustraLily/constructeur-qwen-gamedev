class_name LightningStrike extends Node3D

## Éclair procédural qui frappe une cible (le kart), d'après le tutoriel
## « Godot 4 - 3D Electric Lightning Shader for beginners » :
## - forme en zigzag par déplacement de points médians, avec des ramifications ;
## - régénérée toutes les `flicker_interval` secondes pour scintiller ;
## - dessinée en rubans face caméra avec lightning.gdshader (cœur blanc + halo) ;
## - à l'impact : flash de lumière, éclat, gerbe d'étincelles, puis arcs électriques autour de la cible.
## Le bas de l'éclair suit la cible, même lancée à pleine vitesse.

## Nœud frappé (fixé avant l'ajout à la scène)
var target : Node3D

## Matériau des rubans de l'éclair (lightning.gdshader).
@export var bolt_material : Material
## Hauteur (m) du point de départ dans le ciel
@export var height : float = 30.0
## Décalage horizontal aléatoire (m) du point de départ
@export var sky_spread : float = 6.0
## Point d'impact par rapport à la cible
@export var target_offset : Vector3 = Vector3(0.0, 0.6, 0.0)
## Subdivisions du zigzag (2^n segments)
@export var generations : int = 6
## Amplitude du zigzag (par rapport à la longueur de l'éclair)
@export var jaggedness : float = 0.12
## Nombre de ramifications de l'éclair principal.
@export var branch_count : int = 5
## Largeur du ruban, halo compris (m)
@export var bolt_width : float = 1.2
## Durée de l'éclair principal (s)
@export var strike_duration : float = 0.4
## Durée des arcs électriques autour de la cible (s)
@export var arcs_duration : float = 0.75
## Nombre d'arcs électriques autour de la cible.
@export var arc_count : int = 5
## Délai entre deux formes d'éclair (scintillement)
@export var flicker_interval : float = 0.05
## Énergie de la lumière du flash à l'impact.
@export var flash_energy : float = 12.0

@onready var _bolt : MeshInstance3D = $Bolt
@onready var _light : OmniLight3D = $Flash/Light
@onready var _glow : MeshInstance3D = $Flash/Glow
@onready var _sparks : GPUParticles3D = $Sparks

var _rng := RandomNumberGenerator.new()
var _mesh := ImmediateMesh.new()
var _time : float = 0.0
var _regen : float = 0.0
var _flicker : float = 1.0
var _sky : Vector3
var _gen_target : Vector3
var _main := PackedVector3Array()
var _branches : Array[PackedVector3Array] = []
var _arcs : Array[PackedVector3Array] = []

func _ready() -> void:
	_rng.randomize()
	_bolt.mesh = _mesh
	_bolt.top_level = true
	_bolt.global_transform = Transform3D.IDENTITY
	restart()

## (Re)lance la frappe : nouveau point de départ, flash et étincelles.
func restart() -> void:
	_time = 0.0
	_regen = 0.0
	var t := _target_position()
	global_position = t
	_sky = t + Vector3(_rng.randf_range(-sky_spread, sky_spread), height, _rng.randf_range(-sky_spread, sky_spread))
	_sparks.restart()

func _target_position() -> Vector3:
	return target.global_position + target_offset if is_instance_valid(target) else global_position

func _process(delta: float) -> void:
	_time += delta
	if _time > maxf(arcs_duration, _sparks.lifetime) + 0.05:
		queue_free()
		return
	var target_pos := _target_position()
	global_position = target_pos

	_regen -= delta
	if _regen <= 0.0:
		_regen = flicker_interval
		_flicker = _rng.randf_range(0.45, 1.0)
		_generate()

	var bolt_level := 0.0
	if _time < strike_duration:
		bolt_level = _flicker * (1.0 - smoothstep(strike_duration * 0.3, strike_duration, _time))
	var arc_level := _flicker * (1.0 - smoothstep(arcs_duration * 0.4, arcs_duration, _time))

	_light.light_energy = flash_energy * maxf(bolt_level, arc_level * 0.2)
	_glow.set_instance_shader_parameter("flash_strength", bolt_level)
	_glow.scale = Vector3.ONE * (1.0 + _time * 2.5)
	_build_mesh(target_pos, bolt_level, arc_level)

# ---------------------------------------------------------------------------
# Forme de l'éclair
# ---------------------------------------------------------------------------

## Zigzag par déplacement de points médians : chaque génération coupe les segments en deux et
## décale le milieu perpendiculairement, avec une amplitude divisée par deux à chaque fois.
func _make_bolt(from: Vector3, to: Vector3, jag: float, gens: int) -> PackedVector3Array:
	var points := PackedVector3Array([from, to])
	var offset := from.distance_to(to) * jag
	for g in gens:
		var refined := PackedVector3Array()
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var dir := (b - a).normalized()
			var perp := dir.cross(_random_direction()).normalized()
			refined.append(a)
			refined.append((a + b) * 0.5 + perp * _rng.randf_range(-offset, offset))
		refined.append(points[points.size() - 1])
		points = refined
		offset *= 0.5
	return points

func _generate() -> void:
	_gen_target = _target_position()
	_main = _make_bolt(_sky, _gen_target, jaggedness, generations)
	_branches.clear()
	var n := _main.size()
	for b in branch_count:
		var i := _rng.randi_range(int(n * 0.1), int(n * 0.75))
		var start := _main[i]
		var down := (_main[mini(i + 1, n - 1)] - start).normalized()
		var lateral := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)).normalized()
		var length := start.distance_to(_gen_target) * _rng.randf_range(0.15, 0.35)
		_branches.append(_make_bolt(start, start + (down + lateral * 0.9).normalized() * length, jaggedness * 1.3, 4))
	_arcs.clear()
	for a in arc_count:
		var p0 := _gen_target + _random_direction() * 0.7
		var p1 := _gen_target + _random_direction() * 1.3 - Vector3.UP * 0.3
		_arcs.append(_make_bolt(p0, p1, 0.25, 3))

func _random_direction() -> Vector3:
	return Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)).normalized()

# ---------------------------------------------------------------------------
# Rendu : rubans face caméra
# ---------------------------------------------------------------------------

## Affinement d'un ruban : aucun, vers son extrémité, ou aux deux bouts.
enum Taper { NONE, END, BOTH }

func _build_mesh(target_pos: Vector3, bolt_level: float, arc_level: float) -> void:
	_mesh.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var camera_pos := camera.global_position
	var target_shift := target_pos - _gen_target
	if bolt_level > 0.01:
		_add_strip(_main, bolt_width, bolt_level, camera_pos, target_shift, true, Taper.NONE)
		for branch in _branches:
			_add_strip(branch, bolt_width * 0.5, bolt_level * 0.6, camera_pos, target_shift, true, Taper.END)
	if arc_level > 0.01:
		for arc in _arcs:
			_add_strip(arc, bolt_width * 0.35, arc_level, camera_pos, target_shift, false, Taper.BOTH)

## Part du déplacement de la cible appliquée à un point : 0 dans le ciel, 1 au point d'impact
func _follow_weight(p: Vector3) -> float:
	return clampf(1.0 - (p.y - _gen_target.y) / maxf(_sky.y - _gen_target.y, 0.001), 0.0, 1.0)

func _add_strip(points: PackedVector3Array, width: float, level: float, camera_pos: Vector3,
		target_shift: Vector3, weighted_follow: bool, taper: Taper) -> void:
	var n := points.size()
	if n < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, bolt_material)
	for i in n:
		var follow := _follow_weight(points[i]) if weighted_follow else 1.0
		var p := points[i] + target_shift * follow
		var tangent := (points[mini(i + 1, n - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side := tangent.cross((camera_pos - p).normalized()).normalized() * width * 0.5
		var t := float(i) / (n - 1)
		var a := level
		match taper:
			Taper.END:
				a *= 1.0 - t
			Taper.BOTH:
				a *= sin(t * PI)
		var color := Color(1.0, 1.0, 1.0, a)
		_mesh.surface_set_color(color)
		_mesh.surface_set_uv(Vector2(0.0, t))
		_mesh.surface_add_vertex(p - side)
		_mesh.surface_set_color(color)
		_mesh.surface_set_uv(Vector2(1.0, t))
		_mesh.surface_add_vertex(p + side)
	_mesh.surface_end()
