#@ 20-23
class_name GolemLightning extends Node3D
## Un éclair du Gardien. D'abord sa marque (`mark`) : un cercle au sol, qui se referme jusqu'au coup : c'est l'annonce, et
## la zone de coup est posée là d'avance. Puis le coup (`strike`) : un ruban en zigzag, de la main du Gardien au cercle,
## tourné vers la caméra et refait plusieurs fois pendant qu'il frappe, pour qu'il scintille ; la zone de coup ne s'allume
## qu'un instant ; une salve (enfant Hit) éclate au point touché. Le ruban est refait dans un ImmediateMesh, sans objet
## créé en combat. L'éclair n'est jamais détruit : il attend le prochain sort.

## L'éclair frappe en `point`.
signal struck(point: Vector3)

## Le nombre de morceaux du ruban.
const SEGMENTS: int = 24

## Rayon, durées, largeur, zigzag.
@export var settings: GolemSpellSettings

## Vrai tant que la marque est au sol.
var marked: bool = false
## Vrai pendant le coup.
var striking: bool = false
## La zone de coup de cet éclair.
var zone: Hitbox

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _points: PackedVector3Array = PackedVector3Array()
var _mesh: ImmediateMesh
var _ring_material: ShaderMaterial
var _from: Vector3 = Vector3.ZERO
var _warn: float = 1.0
var _clock: float = 0.0
var _next_shape: float = 0.0

@onready var _ring: MeshInstance3D = $Ring
@onready var _bolt: MeshInstance3D = $Bolt
@onready var _hit: VfxBurst = $Hit


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	zone = $Zone as Hitbox
	_points.resize(SEGMENTS + 1)
	_rng.seed = String(name).hash()
	_mesh = ImmediateMesh.new()
	_bolt.mesh = _mesh
	_bolt.top_level = true
	_bolt.global_transform = Transform3D.IDENTITY
	_ring_material = (_ring.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_ring.material_override = _ring_material
	var size: float = settings.lightning_radius * 2.0
	_ring.scale = Vector3(size, 1.0, size)
	((zone.get_node("Shape") as CollisionShape3D).shape as SphereShape3D).radius = settings.lightning_radius
	_ring.visible = false
	_bolt.visible = false
	set_process(false)


func _process(delta: float) -> void:
	update(delta)


## Marque le sol en `point` : le coup viendra dans `warn` secondes.
func mark(point: Vector3, warn: float) -> void:
	marked = true
	_warn = maxf(warn, 0.01)
	_clock = 0.0
	global_position = point
	_ring.visible = true
	_ring_material.set_shader_parameter(&"progress", 0.0)
	set_process(true)


## L'éclair part de `from` vers sa marque, avec `damage` dégâts.
func strike(from: Vector3, damage: float) -> void:
	marked = false
	striking = true
	_ring.visible = false
	_from = from
	_clock = 0.0
	_next_shape = 0.0
	_bolt.visible = true
	zone.activate(damage)
	_hit.global_position = global_position
	_hit.play()
	struck.emit(global_position)


## Le sort est interrompu : la marque s'efface.
func cancel() -> void:
	marked = false
	_ring.visible = false
	if not striking:
		set_process(false)


## Fait passer `delta` secondes : la marque se referme, ou l'éclair scintille et s'éteint.
func update(delta: float) -> void:
	_clock += delta
	if marked:
		_ring_material.set_shader_parameter(&"progress", minf(_clock / _warn, 1.0))
		return
	if not striking:
		return
	if zone.active and _clock >= settings.zone_time:
		zone.deactivate()
	if _clock >= settings.bolt_time:
		striking = false
		_bolt.visible = false
		_mesh.clear_surfaces()
		zone.deactivate()
		set_process(false)
		return
	if _clock >= _next_shape:
		_next_shape = _clock + settings.bolt_flicker
		_shape_bolt()
	_draw_bolt(1.0 - _clock / settings.bolt_time)


## Une nouvelle forme : chaque point s'écarte de la ligne droite, de moins en moins vers ses deux bouts.
func _shape_bolt() -> void:
	var to: Vector3 = global_position
	var along: Vector3 = to - _from
	var reach: float = along.length() * settings.bolt_jag
	var side: Vector3 = along.cross(Vector3.UP).normalized()
	var other: Vector3 = along.cross(side).normalized()
	for i: int in SEGMENTS + 1:
		var t: float = float(i) / float(SEGMENTS)
		var edge: float = sin(t * PI) * reach
		_points[i] = _from + along * t + (side * _rng.randf_range(-1.0, 1.0) + other * _rng.randf_range(-1.0, 1.0)) * edge


## Le ruban : une bande tournée vers la caméra, point par point ; `level` (de 1 à 0) dans l'alpha de ses sommets.
func _draw_bolt(level: float) -> void:
	_mesh.clear_surfaces()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var eye: Vector3 = camera.global_position
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in SEGMENTS + 1:
		var point: Vector3 = _points[i]
		var tangent: Vector3 = _points[mini(i + 1, SEGMENTS)] - _points[maxi(i - 1, 0)]
		var edge: Vector3 = tangent.cross(eye - point).normalized() * settings.bolt_width * 0.5
		var along: float = float(i) / float(SEGMENTS)
		_mesh.surface_set_color(Color(1.0, 1.0, 1.0, level))
		_mesh.surface_set_uv(Vector2(0.0, along))
		_mesh.surface_add_vertex(point - edge)
		_mesh.surface_set_color(Color(1.0, 1.0, 1.0, level))
		_mesh.surface_set_uv(Vector2(1.0, along))
		_mesh.surface_add_vertex(point + edge)
	_mesh.surface_end()
#@ 24+
class_name GolemLightning extends Node3D
## Un éclair du Gardien. D'abord sa marque (`mark`) : le sol se charge d'électricité, des filaments gagnent le cercle jusqu'au coup : c'est
## l'annonce, et la zone de coup est posée là d'avance. Puis le coup (`strike`) : une ligne brisée à toutes les échelles, de la main du
## Gardien au sol, avec ses branches, en rubans tournés vers la caméra ; un éclair frappe en plusieurs coups rapprochés, chacun avec sa
## forme ; la zone de coup ne s'allume qu'un instant ; une salve (enfant Hit) éclate au point touché et brûle le sol. Les rubans sont
## refaits dans un ImmediateMesh, sans objet créé en combat. L'éclair n'est jamais détruit : il attend le prochain sort.

## L'éclair frappe en `point`.
signal struck(point: Vector3)

## Les points du tronc : 2^6 + 1 : six fois, chaque morceau est coupé en deux et son milieu s'écarte, de moins en moins.
const TRUNK_POINTS: int = 65
## Le nombre de branches.
const BRANCHES: int = 6
## Les points d'une branche : 2^4 + 1.
const BRANCH_POINTS: int = 17
## La largeur d'une branche, en part de celle du tronc.
const BRANCH_WIDTH: float = 0.5
## Sa force, en part de celle du tronc.
const BRANCH_POWER: float = 0.55
## Une branche se détache du tronc entre ces parts de sa longueur.
const BRANCH_FROM: Vector2 = Vector2(0.15, 0.9)
## Elle fait cette part de la longueur du tronc.
const BRANCH_LENGTH: Vector2 = Vector2(0.1, 0.28)
## Chaque coupe en deux réduit l'écart d'autant.
const ROUGHNESS: float = 0.56

## Rayon, durées, largeur, zigzag.
@export var settings: GolemSpellSettings

## Vrai tant que la marque est au sol.
var marked: bool = false
## Vrai pendant le coup.
var striking: bool = false
## La zone de coup de cet éclair.
var zone: Hitbox

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _points: PackedVector3Array = PackedVector3Array()
var _mesh: ImmediateMesh
var _ring_material: ShaderMaterial
var _bolt_material: ShaderMaterial
var _from: Vector3 = Vector3.ZERO
var _warn: float = 1.0
var _clock: float = 0.0
var _next_shape: float = 0.0

@onready var _ring: MeshInstance3D = $Ring
@onready var _motes: GPUParticles3D = $Motes
@onready var _bolt: MeshInstance3D = $Bolt
@onready var _hit: VfxBurst = $Hit


func _ready() -> void:
	process_priority = ProcessOrder.VIEWS
	zone = $Zone as Hitbox
	_points.resize(TRUNK_POINTS + BRANCHES * BRANCH_POINTS)
	_rng.seed = String(name).hash()
	_mesh = ImmediateMesh.new()
	_bolt.mesh = _mesh
	_bolt.top_level = true
	_bolt.global_transform = Transform3D.IDENTITY
	_ring_material = (_ring.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_ring.material_override = _ring_material
	_bolt_material = (_bolt.material_override as ShaderMaterial).duplicate() as ShaderMaterial
	_bolt.material_override = _bolt_material
	var size: float = settings.lightning_radius * 2.0
	_ring.scale = Vector3(size, 1.0, size)
	((zone.get_node("Shape") as CollisionShape3D).shape as SphereShape3D).radius = settings.lightning_radius
	_ring.visible = false
	_bolt.visible = false
	set_process(false)


func _process(delta: float) -> void:
	update(delta)


## Marque le sol en `point` : le coup viendra dans `warn` secondes.
func mark(point: Vector3, warn: float) -> void:
	marked = true
	_warn = maxf(warn, 0.01)
	_clock = 0.0
	global_position = point
	_ring.visible = true
	_motes.emitting = true
	_ring_material.set_shader_parameter(&"progress", 0.0)
	set_process(true)


## L'éclair part de `from` vers sa marque, avec `damage` dégâts.
func strike(from: Vector3, damage: float) -> void:
	marked = false
	striking = true
	_ring.visible = false
	_motes.emitting = false
	_from = from
	_clock = 0.0
	_next_shape = 0.0
	_bolt.visible = true
	zone.activate(damage)
	_hit.global_position = global_position
	_hit.play()
	struck.emit(global_position)


## Le sort est interrompu : la marque s'efface.
func cancel() -> void:
	marked = false
	_ring.visible = false
	_motes.emitting = false
	if not striking:
		set_process(false)


## Fait passer `delta` secondes : la marque se referme, ou l'éclair scintille et s'éteint.
func update(delta: float) -> void:
	_clock += delta
	if marked:
		_ring_material.set_shader_parameter(&"progress", minf(_clock / _warn, 1.0))
		return
	if not striking:
		return
	if zone.active and _clock >= settings.zone_time:
		zone.deactivate()
	if _clock >= settings.bolt_time:
		striking = false
		_bolt.visible = false
		_mesh.clear_surfaces()
		zone.deactivate()
		set_process(false)
		return
	if _clock >= _next_shape:
		_next_shape = _clock + settings.bolt_flicker
		_shape_bolt()
		_draw_bolt()
	# Chaque forme est un coup : il part fort et retombe vite ; les derniers coups sont plus faibles.
	var stroke: float = 1.0 - (_next_shape - _clock) / settings.bolt_flicker
	_bolt_material.set_shader_parameter(&"level", (1.0 - stroke) ** 2 * (1.0 - _clock / settings.bolt_time))


## Une nouvelle forme : le tronc, puis ses branches, chacune repartie d'un point du tronc.
func _shape_bolt() -> void:
	var to: Vector3 = global_position
	var along: Vector3 = to - _from
	var length: float = along.length()
	_zigzag(0, TRUNK_POINTS, _from, to, settings.bolt_jag)
	for b: int in BRANCHES:
		var at: int = int(_rng.randf_range(BRANCH_FROM.x, BRANCH_FROM.y) * (TRUNK_POINTS - 1))
		var side: Vector3 = Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.5, 0.5), _rng.randf_range(-1.0, 1.0))
		var end: Vector3 = _points[at] + (along / length + side).normalized() * length * _rng.randf_range(BRANCH_LENGTH.x, BRANCH_LENGTH.y)
		_zigzag(TRUNK_POINTS + b * BRANCH_POINTS, BRANCH_POINTS, _points[at], end, settings.bolt_jag * 1.5)


## Les `count` points à partir de `first` vont de `from` à `to` : les deux bouts d'abord, puis le milieu de chaque morceau, qui s'écarte
## de la droite d'un peu moins à chaque passe : une ligne brisée à toutes les échelles, comme un vrai éclair.
func _zigzag(first: int, count: int, from: Vector3, to: Vector3, jag: float) -> void:
	var along: Vector3 = to - from
	var side: Vector3 = along.cross(Vector3.UP).normalized()
	var other: Vector3 = along.cross(side).normalized()
	var reach: float = along.length() * jag
	_points[first] = from
	_points[first + count - 1] = to
	var step: int = count - 1
	while step > 1:
		var half: int = step >> 1
		var i: int = half
		while i < count:
			var middle: Vector3 = (_points[first + i - half] + _points[first + i + half]) * 0.5
			_points[first + i] = middle + side * _rng.randf_range(-reach, reach) + other * _rng.randf_range(-reach, reach)
			i += step
		reach *= ROUGHNESS
		step = half


## Les rubans, tournés vers la caméra ; refaits à chaque forme seulement.
func _draw_bolt() -> void:
	_mesh.clear_surfaces()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var eye: Vector3 = camera.global_position
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	_ribbon(0, TRUNK_POINTS, settings.bolt_width, 1.0, eye)
	for b: int in BRANCHES:
		_ribbon(TRUNK_POINTS + b * BRANCH_POINTS, BRANCH_POINTS, settings.bolt_width * BRANCH_WIDTH, BRANCH_POWER, eye)
	_mesh.surface_end()


## Un ruban de plus dans la bande : deux sommets confondus le séparent du précédent (triangles vides).
func _ribbon(first: int, count: int, width: float, power: float, eye: Vector3) -> void:
	for i: int in count:
		var point: Vector3 = _points[first + i]
		var tangent: Vector3 = _points[first + mini(i + 1, count - 1)] - _points[first + maxi(i - 1, 0)]
		var along: float = float(i) / float(count - 1)
		var edge: Vector3 = tangent.cross(eye - point).normalized() * width * 0.5 * (1.0 - along * 0.75)
		var strength: float = power * (1.0 - along * 0.6)
		if i == 0 and first > 0:
			_vertex(point - edge, 0.0, along, strength)
		_vertex(point - edge, 0.0, along, strength)
		_vertex(point + edge, 1.0, along, strength)
		if i == count - 1:
			_vertex(point + edge, 1.0, along, strength)


func _vertex(at: Vector3, across: float, along: float, strength: float) -> void:
	_mesh.surface_set_color(Color(1.0, 1.0, 1.0, strength))
	_mesh.surface_set_uv(Vector2(across, along))
	_mesh.surface_add_vertex(at)
#@ all
