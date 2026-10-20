class_name WheelTrail extends MeshInstance3D
## Traînée procédurale : un ruban reconstruit à chaque image à partir des dernières positions d'une roue.
## Chaque point vieillit, s'élargit et s'efface ; le shader (wheel_trail.gdshader) « ronge » la traînée avec du
## bruit selon l'âge (COLOR.r) et applique l'opacité (COLOR.a). Le ruban est construit en coordonnées du monde.


## Un point de la traînée.
class TrailPoint:
	## Position, sur la surface (m).
	var pos: Vector3
	## Direction latérale, dans le plan de la surface.
	var side: Vector3
	## Instant de création (s).
	var time: float
	## Opacité de départ, de 0 à 1.
	var strength: float
	## Distance parcourue depuis le début de la traînée (m) : la coordonnée V du ruban.
	var distance: float
	## Vrai pour le premier point d'un tronçon : le ruban s'interrompt avant lui.
	var new_segment: bool


## Durée de vie d'un point (s).
@export var lifetime: float = 1.5
## Largeur à la création (m).
@export var width: float = 0.35
## Multiplicateur de largeur en fin de vie (> 1 : la traînée s'étale, comme un sillage).
@export var width_growth: float = 1.0
## Distance minimale entre deux points (m).
@export var min_distance: float = 0.2
## Décalage au-dessus de la surface (m), pour que le ruban ne scintille pas avec elle.
@export var height_offset: float = 0.03
## Matériau du ruban.
@export var trail_material: Material

var _points: Array[TrailPoint] = []
var _time: float = 0.0
var _active: bool = false
var _distance: float = 0.0
var _mesh: ImmediateMesh = ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## À appeler à chaque image tant que la roue doit laisser une traînée. `side` : direction latérale
## (perpendiculaire au déplacement, dans le plan de la surface).
func add_point(surface_position: Vector3, side: Vector3, surface_normal: Vector3, strength: float) -> void:
	var pos := surface_position + surface_normal * height_offset
	var start_segment := not _active or _points.is_empty()
	_active = true
	if not start_segment:
		var last := _points[-1]
		var moved := (pos - last.pos).length()
		if moved < min_distance:
			# La tête de la traînée suit la roue sans créer de point.
			last.pos = pos
			last.side = side
			last.strength = strength
			return
		_distance += moved
	var point := TrailPoint.new()
	point.pos = pos
	point.side = side
	point.time = _time
	point.strength = strength
	point.distance = _distance
	point.new_segment = start_segment
	_points.append(point)


## La roue a quitté la surface : la traînée existante finit de s'effacer.
func stop() -> void:
	_active = false


## Nombre de points vivants.
func point_count() -> int:
	return _points.size()


func _process(delta: float) -> void:
	_time += delta
	while not _points.is_empty() and _time - _points[0].time > lifetime:
		_points.pop_front()
		if not _points.is_empty():
			_points[0].new_segment = true
	_rebuild()


func _rebuild() -> void:
	_mesh.clear_surfaces()
	var start := 0
	while start < _points.size():
		# Un tronçon : une suite de points sans interruption.
		var end := start + 1
		while end < _points.size() and not _points[end].new_segment:
			end += 1
		if end - start >= 2:
			_build_segment(start, end)
		start = end


func _build_segment(from: int, to: int) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, trail_material)
	for index: int in range(from, to):
		var point := _points[index]
		var age := clampf((_time - point.time) / lifetime, 0.0, 1.0)
		var half_width := width * lerpf(1.0, width_growth, age) * 0.5
		# Le premier point du tronçon est transparent : la queue s'estompe.
		var alpha := 0.0 if index == from else point.strength * pow(1.0 - age, 1.5)
		var color := Color(age, 0.0, 0.0, alpha)
		_mesh.surface_set_normal(Vector3.UP)
		_mesh.surface_set_color(color)
		_mesh.surface_set_uv(Vector2(0.0, point.distance))
		_mesh.surface_add_vertex(point.pos - point.side * half_width)
		_mesh.surface_set_normal(Vector3.UP)
		_mesh.surface_set_color(color)
		_mesh.surface_set_uv(Vector2(1.0, point.distance))
		_mesh.surface_add_vertex(point.pos + point.side * half_width)
	_mesh.surface_end()
