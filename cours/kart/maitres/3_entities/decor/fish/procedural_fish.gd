class_name ProceduralFish extends MeshInstance3D

## Poisson à animation procédurale, adapté en 3D de « animal-proc-anim » d'argonautcode
## (https://github.com/argonautcode/animal-proc-anim, licence MIT) :
## - la colonne vertébrale est une chaîne de 12 articulations à distance fixe ; chaque segment suit
##   le précédent avec un angle limité (PI/8), ce qui propage l'ondulation de la tête vers la queue ;
## - le corps est un tube dont la largeur suit chaque vertèbre (mêmes largeurs que l'original) ;
## - les nageoires pectorales, ventrales, caudale et dorsale sont reconstruites à chaque image et
##   réagissent à la courbure du corps comme dans l'original.
## Les distances sont celles du code d'origine (en « pixels »), converties en mètres par `size`.

## Nombre d'articulations de la colonne vertébrale.
const JOINT_COUNT := 12
## Distance entre deux articulations (unités d'origine).
const LINK := 64.0
## Angle maximal entre deux segments voisins.
const ANGLE_CONSTRAINT := PI / 8.0
## Demi-largeur du corps à chaque vertèbre (les 2 dernières articulations portent la nageoire caudale)
const BODY_WIDTH := [68.0, 81.0, 84.0, 83.0, 77.0, 64.0, 51.0, 38.0, 32.0, 19.0]
## Hauteur du corps par rapport à sa largeur
const HEIGHT_RATIO := 0.9
## Nombre de côtés de chaque anneau du tube du corps.
const RING_SIDES := 10
## Nombre d'anneaux du tube du corps.
const RING_COUNT := 12 # 2 anneaux pour le museau + 10 vertèbres
## Nombre de segments du bord des nageoires en ellipse.
const FIN_RIM := 12
## Longueur du corps du museau à la queue (unités d'origine), pour les coordonnées de texture
const BODY_LENGTH := 72.0 + 64.0 * 9.0 + 19.0

## Mètres par unité du code d'origine (0.0013 : poisson d'environ 1 m)
@export var size : float = 0.0013
## Matériau du corps.
@export var body_material : Material
## Matériau des nageoires.
@export var fin_material : Material
## Vitesse de rotation maximale (rad/s)
@export var turn_rate : float = 2.4
## Amplitude du battement de la tête (rad), propagé le long du corps par la chaîne
@export var wiggle : float = 0.32
## Au-delà de cette distance de la caméra, le poisson est caché
@export var max_render_distance : float = 70.0
## Au-delà de cette distance, le maillage n'est reconstruit qu'une image sur deux
@export var half_rate_distance : float = 18.0

## Point vers lequel le poisson nage (fixé par FishSchool)
var target_position : Vector3
## Vitesse visée (m/s)
var desired_speed : float = 1.0

var _joints := PackedVector3Array()
var _angles := PackedFloat32Array()
var _heading : float = 0.0
var _speed : float = 0.0
var _phase : float = 0.0
var _flap : float = 0.0
var _frame : int = 0
var _mesh := ArrayMesh.new()
var _body_vertices := PackedVector3Array()
var _body_normals := PackedVector3Array()
var _fin_vertices := PackedVector3Array()
var _fin_normals := PackedVector3Array()

static var _static_ready := false
static var _body_uv := PackedVector2Array()
static var _body_indices := PackedInt32Array()
static var _fin_uv := PackedVector2Array()
static var _fin_indices := PackedInt32Array()

func _init() -> void:
	_joints.resize(JOINT_COUNT)
	_angles.resize(JOINT_COUNT)
	_body_vertices.resize(RING_COUNT * (RING_SIDES + 1) + 2)
	_body_normals.resize(_body_vertices.size())
	_fin_vertices.resize(4 * (FIN_RIM + 1) + 15 + 8)
	_fin_normals.resize(_fin_vertices.size())
	_build_static_data()

func _ready() -> void:
	# Le maillage est construit directement en coordonnées monde
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	_phase = randf() * TAU
	_flap = randf() * TAU
	_frame = randi() % 2

## Place le poisson, tête en `position`, orienté selon `heading` (angle dans le plan XZ).
func place(head_position: Vector3, heading: float) -> void:
	_heading = heading
	target_position = head_position
	var back := -Vector3(cos(heading), 0.0, sin(heading)) * LINK * size
	for i in JOINT_COUNT:
		_joints[i] = head_position + back * i
		_angles[i] = heading

## Position de la tête (première articulation).
func get_head_position() -> Vector3:
	return _joints[0]

## Direction de nage, à l'horizontale.
func get_forward() -> Vector3:
	return Vector3(cos(_heading), 0.0, sin(_heading))

func _process(delta: float) -> void:
	_swim(delta)
	var camera := get_viewport().get_camera_3d()
	var distance := camera.global_position.distance_to(_joints[0]) if camera else 0.0
	visible = distance < max_render_distance
	_frame += 1
	if visible and (distance < half_rate_distance or _frame % 2 == 0):
		_rebuild_mesh()

# ---------------------------------------------------------------------------
# Nage
# ---------------------------------------------------------------------------

func _swim(delta: float) -> void:
	var head := _joints[0]
	var to_target := Vector2(target_position.x - head.x, target_position.z - head.z)
	if to_target.length() > 0.05:
		var desired := atan2(to_target.y, to_target.x)
		var turn := relative_angle_diff(_heading, desired)
		_heading = simplify_angle(_heading + clampf(turn, -turn_rate * delta, turn_rate * delta))
	_speed = move_toward(_speed, desired_speed, 2.5 * delta)

	# Battement de la tête : la chaîne le transforme en ondulation de tout le corps
	_phase += delta * (3.0 + 5.0 * _speed)
	_flap += delta * (4.0 + 3.0 * _speed)
	var swim_angle := _heading + sin(_phase) * wiggle * clampf(_speed, 0.3, 1.2)
	var new_head := head + Vector3(cos(swim_angle), 0.0, sin(swim_angle)) * _speed * delta
	new_head.y = move_toward(head.y, target_position.y, 0.6 * delta)
	_resolve(new_head)

## Chain.resolve() de l'original : la tête va en `pos`, chaque articulation suit la précédente
## à distance fixe, avec un angle limité par rapport à elle.
func _resolve(pos: Vector3) -> void:
	var moved := Vector2(pos.x - _joints[0].x, pos.z - _joints[0].z)
	if moved.length_squared() > 1e-10:
		_angles[0] = atan2(moved.y, moved.x)
	_joints[0] = pos
	var link := LINK * size
	for i in range(1, JOINT_COUNT):
		var prev := _joints[i - 1]
		var cur := _joints[i]
		var angle := constrain_angle(atan2(prev.z - cur.z, prev.x - cur.x), _angles[i - 1], ANGLE_CONSTRAINT)
		_angles[i] = angle
		_joints[i] = Vector3(prev.x - cos(angle) * link, lerpf(cur.y, prev.y, 0.25), prev.z - sin(angle) * link)

# Util.pde de l'original
## Ramène `angle` entre 0 et 2π.
static func simplify_angle(angle: float) -> float:
	return fposmod(angle, TAU)

## Combien de radians faut-il tourner `angle` pour atteindre `anchor` ?
static func relative_angle_diff(angle: float, anchor: float) -> float:
	return PI - simplify_angle(angle + PI - anchor)

## Limite `angle` à ± `constraint` autour de `anchor` ; le résultat est entre 0 et 2π.
static func constrain_angle(angle: float, anchor: float, constraint: float) -> float:
	var diff := relative_angle_diff(angle, anchor)
	if absf(diff) <= constraint:
		return simplify_angle(angle)
	if diff > constraint:
		return simplify_angle(anchor - constraint)
	return simplify_angle(anchor + constraint)

# ---------------------------------------------------------------------------
# Maillage
# ---------------------------------------------------------------------------

func _forward(i: int) -> Vector3:
	return Vector3(cos(_angles[i]), 0.0, sin(_angles[i]))

func _side(i: int) -> Vector3:
	return Vector3(-sin(_angles[i]), 0.0, cos(_angles[i]))

## getPosX/getPosY de l'original : point au bord du corps, décalé de `angle_offset` par rapport à la vertèbre
func _edge(i: int, angle_offset: float, length_offset: float) -> Vector3:
	var a := _angles[i] + angle_offset
	return _joints[i] + Vector3(cos(a), 0.0, sin(a)) * ((BODY_WIDTH[i] as float) + length_offset) * size

func _rebuild_mesh() -> void:
	_build_body()
	_build_fins()
	_mesh.clear_surfaces()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _body_vertices
	arrays[Mesh.ARRAY_NORMAL] = _body_normals
	arrays[Mesh.ARRAY_TEX_UV] = _body_uv
	arrays[Mesh.ARRAY_INDEX] = _body_indices
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh.surface_set_material(0, body_material)
	arrays[Mesh.ARRAY_VERTEX] = _fin_vertices
	arrays[Mesh.ARRAY_NORMAL] = _fin_normals
	arrays[Mesh.ARRAY_TEX_UV] = _fin_uv
	arrays[Mesh.ARRAY_INDEX] = _fin_indices
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh.surface_set_material(1, fin_material)

func _build_body() -> void:
	var w0 : float = BODY_WIDTH[0]
	var f0 := _forward(0)
	# Museau arrondi : demi-cercle devant la première vertèbre, comme dans l'original
	_body_vertices[0] = _joints[0] + f0 * (w0 + 4.0) * size
	_body_normals[0] = f0
	_ring(0, _joints[0] + f0 * w0 * 0.87 * size, f0, _side(0), w0 * 0.5, 1.4)
	_ring(1, _joints[0] + f0 * w0 * 0.5 * size, f0, _side(0), w0 * 0.87, 0.5)
	for i in 10:
		_ring(2 + i, _joints[i], _forward(i), _side(i), BODY_WIDTH[i], -0.4 if i == 9 else 0.0)
	var last := _body_vertices.size() - 1
	_body_vertices[last] = _joints[9] - _forward(9) * (BODY_WIDTH[9] as float) * size
	_body_normals[last] = -_forward(9)

func _ring(ring: int, center: Vector3, fwd: Vector3, side: Vector3, half_width: float, normal_forward: float) -> void:
	var w := half_width * size
	var h := w * HEIGHT_RATIO
	var base := 1 + ring * (RING_SIDES + 1)
	for k in RING_SIDES + 1:
		var theta := TAU * k / RING_SIDES
		var c := cos(theta)
		var s := sin(theta)
		_body_vertices[base + k] = center + side * (c * w) + Vector3.UP * (s * h)
		# Normale d'une ellipse, inclinée vers l'avant au museau et vers l'arrière à la queue
		_body_normals[base + k] = ((side * (c * h) + Vector3.UP * (s * w)).normalized() + fwd * normal_forward).normalized()

func _build_fins() -> void:
	var a := _angles
	# Différences d'angle relatives, utilisées comme dans l'original pour la dorsale et la caudale
	var head_to_mid1 := relative_angle_diff(a[0], a[6])
	var head_to_mid2 := relative_angle_diff(a[0], a[7])
	var head_to_tail := head_to_mid1 + relative_angle_diff(a[6], a[11])

	var flap := sin(_flap)
	var h3 := (BODY_WIDTH[3] as float) * size * HEIGHT_RATIO
	var h7 := (BODY_WIDTH[7] as float) * size * HEIGHT_RATIO

	# Pectorales (ellipses 160 x 64 de l'original), battement alterné
	_ellipse_fin(0, _edge(3, PI / 3.0, 0.0) - Vector3.UP * h3 * 0.1, a[2] - PI / 4.0, 88.0, 34.0, 3, 1.0, -0.15 + 0.25 * flap)
	_ellipse_fin(FIN_RIM + 1, _edge(3, -PI / 3.0, 0.0) - Vector3.UP * h3 * 0.1, a[2] + PI / 4.0, 88.0, 34.0, 3, -1.0, -0.15 - 0.25 * flap)
	# Ventrales (ellipses 96 x 32)
	_ellipse_fin(2 * (FIN_RIM + 1), _edge(7, PI / 2.0, 0.0) - Vector3.UP * h7 * 0.45, a[6] - PI / 4.0, 48.0, 16.0, 7, 1.0, -0.6 + 0.12 * flap)
	_ellipse_fin(3 * (FIN_RIM + 1), _edge(7, -PI / 2.0, 0.0) - Vector3.UP * h7 * 0.45, a[6] + PI / 4.0, 48.0, 16.0, 7, -1.0, -0.6 - 0.12 * flap)

	# Caudale : verticale, plus haute vers l'extrémité, fléchie sur le côté selon la courbure
	var base := 4 * (FIN_RIM + 1)
	for r in 4:
		var i := 8 + r
		var t := r / 3.0
		var height := (18.0 + 62.0 * pow(t, 1.3)) * size
		var lean := _side(i) * (-1.5 * head_to_tail * r * r) * size
		var j := _joints[i]
		var n := _side(i)
		_set_fin(base + r * 3, j + Vector3.UP * height + lean, n)
		_set_fin(base + r * 3 + 1, j, n)
		_set_fin(base + r * 3 + 2, j - Vector3.UP * height * 0.85 + lean, n)
	var tail_back := -_forward(11) * LINK * size
	var tail_height := 80.0 * size
	var tail_lean := _side(11) * (-1.5 * head_to_tail * 9.0) * size * 1.3
	_set_fin(base + 12, _joints[11] + tail_back * 0.55 + Vector3.UP * tail_height * 1.15 + tail_lean, _side(11))
	_set_fin(base + 13, _joints[11] + tail_back * 0.12 + tail_lean, _side(11))
	_set_fin(base + 14, _joints[11] + tail_back * 0.55 - Vector3.UP * tail_height + tail_lean, _side(11))

	# Dorsale : sur le dos, entre les vertèbres 4 et 7, penchée sur le côté quand le corps se courbe
	base += 15
	var dorsal_profile := [0.2, 1.0, 0.85, 0.1]
	var dorsal_lean := [0.0, head_to_mid1 * 16.0, head_to_mid2 * 16.0, 0.0]
	for r in 4:
		var i := 4 + r
		var top_of_body := _joints[i] + Vector3.UP * (BODY_WIDTH[i] as float) * size * HEIGHT_RATIO * 0.9
		var n := _side(i)
		_set_fin(base + r * 2, top_of_body, n)
		_set_fin(base + r * 2 + 1, top_of_body + Vector3.UP * 48.0 * size * (dorsal_profile[r] as float) \
			+ n * (dorsal_lean[r] as float) * size, n)

func _set_fin(index: int, point: Vector3, normal: Vector3) -> void:
	_fin_vertices[index] = point
	_fin_normals[index] = normal

## Nageoire en ellipse (rayons rx, rz en unités d'origine), qui s'abaisse et bat vers l'extérieur
func _ellipse_fin(base: int, center: Vector3, angle: float, rx: float, rz: float, joint: int, outward: float, droop: float) -> void:
	var dir := Vector3(cos(angle), 0.0, sin(angle)) * rx * size
	var perp := Vector3(-sin(angle), 0.0, cos(angle)) * rz * size
	var side := _side(joint) * outward
	var body_edge := (BODY_WIDTH[joint] as float) * size * 0.6
	_set_fin(base, center, Vector3.UP)
	for m in FIN_RIM:
		var t := TAU * m / FIN_RIM
		var p := center + dir * cos(t) + perp * sin(t)
		p.y += maxf((p - _joints[joint]).dot(side) - body_edge, 0.0) * droop
		_set_fin(base + 1 + m, p, Vector3.UP)

# ---------------------------------------------------------------------------
# Données communes à tous les poissons (topologie et coordonnées de texture)
# ---------------------------------------------------------------------------

static func _build_static_data() -> void:
	if _static_ready:
		return
	_static_ready = true

	# Corps : UV.x = position du museau (0) à la queue (1), UV.y = tour du corps (0 = flanc droit, 0.25 = dos)
	var ring_distance := [12.84, 38.0]
	for i in 10:
		ring_distance.append(72.0 + 64.0 * i)
	_body_uv.append(Vector2(0.0, 0.25))
	for ring in RING_COUNT:
		for k in RING_SIDES + 1:
			_body_uv.append(Vector2((ring_distance[ring] as float) / BODY_LENGTH, float(k) / RING_SIDES))
	_body_uv.append(Vector2(1.0, 0.25))

	var stride := RING_SIDES + 1
	for k in RING_SIDES:
		_body_indices.append_array([0, 1 + k, 1 + k + 1])
	for ring in RING_COUNT - 1:
		var a := 1 + ring * stride
		var b := a + stride
		for k in RING_SIDES:
			_body_indices.append_array([a + k, b + k, a + k + 1, a + k + 1, b + k, b + k + 1])
	var last_ring := 1 + (RING_COUNT - 1) * stride
	var tail := 1 + RING_COUNT * stride
	for k in RING_SIDES:
		_body_indices.append_array([last_ring + k, tail, last_ring + k + 1])

	# Nageoires en ellipse : UV.y = 0 au centre, 1 au bord (liseré blanc dans le shader)
	for fin in 4:
		var base := fin * (FIN_RIM + 1)
		_fin_uv.append(Vector2(0.5, 0.0))
		for m in FIN_RIM:
			_fin_uv.append(Vector2(float(m) / FIN_RIM, 1.0))
			_fin_indices.append_array([base, base + 1 + m, base + 1 + (m + 1) % FIN_RIM])
	# Caudale : 4 rangées (haut, axe, bas) + 2 pointes et l'échancrure
	var c := 4 * (FIN_RIM + 1)
	for r in 4:
		_fin_uv.append_array([Vector2(r / 3.0, 1.0), Vector2(r / 3.0, 0.0), Vector2(r / 3.0, 1.0)])
	_fin_uv.append_array([Vector2(1.0, 1.0), Vector2(1.0, 0.55), Vector2(1.0, 1.0)])
	for r in 3:
		var top := c + r * 3
		var mid := top + 1
		var bottom := top + 2
		_fin_indices.append_array([top, top + 3, mid, mid, top + 3, mid + 3, mid, mid + 3, bottom, bottom, mid + 3, bottom + 3])
	var t3 := c + 9
	_fin_indices.append_array([t3, c + 12, t3 + 1, t3 + 1, c + 12, c + 13, t3 + 1, c + 13, c + 14, t3 + 1, c + 14, t3 + 2])
	# Dorsale : 4 rangées (base, sommet)
	var d := c + 15
	for r in 4:
		_fin_uv.append_array([Vector2(r / 3.0, 0.0), Vector2(r / 3.0, 1.0)])
	for r in 3:
		var b0 := d + r * 2
		_fin_indices.append_array([b0, b0 + 1, b0 + 2, b0 + 2, b0 + 1, b0 + 3])
