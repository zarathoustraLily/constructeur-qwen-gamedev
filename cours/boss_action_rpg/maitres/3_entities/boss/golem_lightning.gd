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
