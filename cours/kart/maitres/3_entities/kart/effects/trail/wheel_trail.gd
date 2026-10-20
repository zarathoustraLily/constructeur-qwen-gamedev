class_name WheelTrail extends MeshInstance3D

## Traînée procédurale : un ruban reconstruit à chaque image à partir des dernières positions
## d'une roue. Chaque point vieillit, s'élargit et s'efface ; le shader « ronge » la traînée
## avec du bruit en fonction de l'âge (COLOR.r) et applique l'opacité (COLOR.a).

## Durée de vie d'un point (s)
@export var lifetime : float = 1.5
## Largeur à la création (m)
@export var width : float = 0.35
## Multiplicateur de largeur en fin de vie (> 1 : la traînée s'étale, comme un sillage)
@export var width_growth : float = 1.0
## Distance minimale entre deux points (m)
@export var min_distance : float = 0.2
## Décalage au-dessus de la surface (m), pour éviter le z-fighting
@export var height_offset : float = 0.03
## Matériau du ruban.
@export var trail_material : Material

var _points : Array[Dictionary] = []
var _time : float = 0.0
var _active : bool = false
var _distance : float = 0.0
var _mesh := ImmediateMesh.new()

func _ready() -> void:
	# Le ruban est construit directement en coordonnées monde
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## À appeler à chaque image tant que la roue doit laisser une traînée.
## side : direction latérale (perpendiculaire au déplacement, dans le plan de la surface).
func add_point(surface_position: Vector3, side: Vector3, surface_normal: Vector3, strength: float) -> void:
	var pos := surface_position + surface_normal * height_offset
	var start_segment := not _active or _points.is_empty()
	_active = true
	if not start_segment:
		var last : Dictionary = _points[-1]
		var moved : float = (pos - last.pos).length()
		if moved < min_distance:
			# La tête de la traînée suit la roue sans créer de nouveau point
			last.pos = pos
			last.side = side
			last.strength = strength
			return
		_distance += moved
	_points.append({
		"pos": pos,
		"side": side,
		"time": _time,
		"strength": strength,
		"distance": _distance,
		"new_segment": start_segment,
	})

## La roue a quitté la surface : la traînée existante finit de s'effacer.
func stop() -> void:
	_active = false

func _process(delta: float) -> void:
	_time += delta
	while not _points.is_empty() and _time - (_points[0].time as float) > lifetime:
		_points.pop_front()
		if not _points.is_empty():
			_points[0].new_segment = true
	_rebuild()

func _rebuild() -> void:
	_mesh.clear_surfaces()
	var i := 0
	while i < _points.size():
		# Un segment = une suite de points sans interruption
		var j := i + 1
		while j < _points.size() and not (_points[j].new_segment as bool):
			j += 1
		if j - i >= 2:
			_build_segment(i, j)
		i = j

func _build_segment(from: int, to: int) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, trail_material)
	for k in range(from, to):
		var p : Dictionary = _points[k]
		var age : float = clampf((_time - (p.time as float)) / lifetime, 0.0, 1.0)
		var half_width : float = width * lerpf(1.0, width_growth, age) * 0.5
		var alpha : float = (p.strength as float) * pow(1.0 - age, 1.5)
		# Fondu en queue de segment
		if k == from:
			alpha = 0.0
		var color := Color(age, 0.0, 0.0, alpha)
		var side : Vector3 = p.side
		var v : float = p.distance
		_mesh.surface_set_normal(Vector3.UP)
		_mesh.surface_set_color(color)
		_mesh.surface_set_uv(Vector2(0.0, v))
		_mesh.surface_add_vertex(p.pos - side * half_width)
		_mesh.surface_set_normal(Vector3.UP)
		_mesh.surface_set_color(color)
		_mesh.surface_set_uv(Vector2(1.0, v))
		_mesh.surface_add_vertex(p.pos + side * half_width)
	_mesh.surface_end()
