class_name SpectreTrail extends MeshInstance3D
## La traîne d'un spectre : une bande de lumière faite de ses dernières positions, tournée vers la caméra, large à sa
## tête et effilée au bout. Les positions plus vieilles que `trail_time` s'en vont : immobile, il n'a presque pas de
## traîne ; en plongée, elle s'étire sur plusieurs mètres. La bande est refaite à chaque image (ImmediateMesh, sans
## objet créé en combat). La couleur des sommets porte l'âge (alpha 1 : à l'instant, 0 : effacé) ; UV.x va de la tête
## (0) au bout (1), UV.y d'un bord à l'autre. Elle est hors de la hiérarchie des positions (top_level) : ses points
## sont dans le monde, elle ne suit pas le spectre.

## Le nombre de positions gardées au plus (une par image).
const CAPACITY: int = 48

## La durée et la largeur de la traîne (les réglages du spectre, posés par sa vue).
var settings: SpectreSettings
## Combien de positions la traîne garde.
var count: int = 0
## Les positions gardées, de la plus vieille (0) à la plus récente (count - 1).
var points: PackedVector3Array = PackedVector3Array()

var _times: PackedFloat32Array = PackedFloat32Array()
var _mesh: ImmediateMesh
var _material: ShaderMaterial
var _clock: float = 0.0


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	points.resize(CAPACITY)
	_times.resize(CAPACITY)
	_mesh = ImmediateMesh.new()
	mesh = _mesh
	# Un matériau à elle : chaque traîne a l'éclat de son spectre.
	_material = (material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material_override = _material


## Fait passer `delta` secondes : ajoute la position `point` de l'instant, oublie les trop vieilles et refait la bande,
## d'éclat `intensity`. Invisible (le spectre dort ou s'est dissipé), elle oublie tout.
func follow(point: Vector3, delta: float, intensity: float) -> void:
	_clock += delta
	if not is_visible_in_tree():
		count = 0
		_mesh.clear_surfaces()
		return
	if count == CAPACITY:
		_drop_oldest()
	points[count] = point
	_times[count] = _clock
	count += 1
	while count > 0 and _clock - _times[0] > settings.trail_time:
		_drop_oldest()
	_material.set_shader_parameter(&"intensity", intensity)
	_rebuild()


## La longueur de la traîne, de sa tête à son bout, en mètres (en ligne droite).
func span() -> float:
	return 0.0 if count < 2 else points[count - 1].distance_to(points[0])


func _rebuild() -> void:
	_mesh.clear_surfaces()
	if count < 2:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var head: Vector3 = points[count - 1]
	var eye: Vector3 = camera.global_position if camera != null else head + Vector3.BACK * 10.0
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in count:
		var p: Vector3 = points[i]
		# Le bord de la bande : perpendiculaire à la traîne et au regard, pour qu'on la voie toujours de face.
		var along: Vector3 = points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]
		var side: Vector3 = along.cross(eye - p)
		side = Vector3.RIGHT if side.is_zero_approx() else side.normalized()
		var age: float = clampf((_clock - _times[i]) / settings.trail_time, 0.0, 1.0)
		var half: float = settings.trail_width * 0.5 * (1.0 - age)
		var u: float = 1.0 - float(i) / float(count - 1)
		var shade: Color = Color(1.0, 1.0, 1.0, 1.0 - age)
		_mesh.surface_set_color(shade)
		_mesh.surface_set_uv(Vector2(u, 0.0))
		_mesh.surface_add_vertex(p - side * half)
		_mesh.surface_set_color(shade)
		_mesh.surface_set_uv(Vector2(u, 1.0))
		_mesh.surface_add_vertex(p + side * half)
	_mesh.surface_end()


func _drop_oldest() -> void:
	for i: int in count - 1:
		points[i] = points[i + 1]
		_times[i] = _times[i + 1]
	count -= 1
