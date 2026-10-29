@tool
class_name SpectreBones extends RefCounted
## Les pièces du squelette spectral, faites par le code : un crâne aux orbites creuses où brûlent deux feux, des dents,
## une mâchoire, une colonne qui finit en queue, des côtes, des omoplates, des bras osseux et des mains aux
## longues griffes, un linceul en lambeaux. Chaque pièce est un ArrayMesh d'une surface, construit à la première demande
## puis partagé par tous les spectres. Le modèle regarde vers -Z ; le bas du linceul est en y = 0. Les couleurs des
## sommets sont les poids du shader de spectre : r, l'ondulation (0 pour les os) ; g, la dissolution (le bas du
## linceul) ; b, l'éclat (0,5 l'ordinaire).

## Les pièces : le crâne, la mâchoire, le tronc, le linceul, un bras, un avant-bras, deux mains.
const PARTS: Array[StringName] = [
	&"skull", &"jaw", &"torso", &"shroud", &"upper_arm", &"forearm", &"hand_left", &"hand_right",
]
## Le pivot de la tête (le haut du cou), dans le modèle.
const SKULL_PIVOT: Vector3 = Vector3(0.0, 1.58, 0.02)
## Le centre du crâne, dans le repère de la tête.
const SKULL_CENTER: Vector3 = Vector3(0.0, 0.11, -0.01)
## Les demi-axes du crâne (un peu plus grand qu'un crâne d'homme, pour qu'on le lise de loin).
const SKULL_RADII: Vector3 = Vector3(0.095, 0.115, 0.12)
## La charnière de la mâchoire, dans le repère de la tête.
const JAW_HINGE: Vector3 = Vector3(0.0, 0.05, 0.0)
## L'épaule droite, dans le modèle ; la gauche est son miroir en x.
const SHOULDER: Vector3 = Vector3(0.19, 1.49, -0.01)
## La longueur du bras, de l'épaule au coude.
const UPPER_ARM_LENGTH: float = 0.3
## La longueur de l'avant-bras, du coude au poignet.
const FOREARM_LENGTH: float = 0.28
## Les rangées du linceul, de haut en bas.
const SHROUD_ROWS: int = 18
## Les colonnes du linceul, d'un côté du dos à l'autre.
const SHROUD_COLUMNS: int = 30
## Le haut du linceul, sur les épaules (en mètres).
const SHROUD_TOP: float = 1.53
## La longueur du linceul, du haut au plus long lambeau (en mètres).
const SHROUD_LENGTH: float = 1.38
## Le linceul fait le tour du dos jusqu'à cet angle de chaque côté (radians, 0 au milieu du dos) : il reste ouvert
## devant, sur les côtes.
const SHROUD_SPAN: float = 2.25

## Un os : immobile, d'éclat ordinaire.
const BONE: Color = Color(0.0, 0.0, 0.5)
## Le feu d'une orbite : le plus vif.
const EYE_FIRE: Color = Color(0.0, 0.0, 1.0)
## Le fond d'une orbite ou du nez : éteint.
const HOLLOW: Color = Color(0.0, 0.0, 0.0)
## La longueur de chaque côte, de la colonne vers l'avant (angle autour du tronc, en radians) : les deux dernières
## flottent.
const RIB_REACH: Array[float] = [2.85, 2.9, 2.9, 2.8, 2.55, 2.2, 1.85]
## La longueur des quatre griffes de chaque main, en mètres.
const CLAW_LENGTH: Array[float] = [0.2, 0.23, 0.22, 0.18]

static var _built: Dictionary[StringName, ArrayMesh] = {}


## La pièce `part` (une de PARTS), construite à la première demande puis partagée.
static func mesh(part: StringName) -> ArrayMesh:
	if not _built.has(part):
		_built[part] = build(part)
	return _built[part]


## Construit la pièce `part` à neuf ; deux constructions donnent le même maillage (le hasard des lambeaux a sa graine).
static func build(part: StringName) -> ArrayMesh:
	var b: MeshBuilder = MeshBuilder.new()
	b.begin_part()
	match part:
		&"skull":
			_skull(b)
		&"jaw":
			_jaw(b)
		&"torso":
			_torso(b)
		&"shroud":
			_shroud(b)
		&"upper_arm":
			_upper_arm(b)
		&"forearm":
			_forearm(b)
		&"hand_left":
			_hand(b, 1.0)
		&"hand_right":
			_hand(b, -1.0)
		_:
			push_error("pièce de spectre inconnue : %s" % part)
	b.end_part()
	return b.to_mesh()


## La direction (longueur 1, depuis le centre du crâne) de l'orbite de ce côté (-1 gauche, 1 droite).
static func eye_direction(side: float) -> Vector3:
	return Vector3(side * 0.42, 0.1, -1.0).normalized()


static func _skull(b: MeshBuilder) -> void:
	var first: int = b.ellipsoid(SKULL_CENTER, SKULL_RADII, 20, 28, BONE)
	for i: int in range(first, b.vertices.size()):
		var d: Vector3 = (b.vertices[i] - SKULL_CENTER) / SKULL_RADII
		b.move_vertex(i, SKULL_CENTER + _skull_shape(d))
		b.paint(i, BONE.lerp(HOLLOW, _hollowness(d)))
	for side: float in [-1.0, 1.0]:
		var e: Vector3 = eye_direction(side)
		b.ellipsoid(SKULL_CENTER + e * (e * SKULL_RADII).length() * 0.5, Vector3(0.008, 0.007, 0.007), 5, 8, EYE_FIRE)
	for k: int in 8:
		var a: float = lerpf(-0.95, 0.95, k / 7.0)
		var root: Vector3 = SKULL_CENTER + Vector3(sin(a) * 0.046, -0.084, -cos(a) * 0.082)
		b.ellipsoid(root, Vector3(0.0065, 0.012, 0.006), 4, 6, BONE)


## Le crâne sur sa boule : face plus plate, mâchoire du haut plus étroite, arrière bombé, orbites et nez creusés,
## arcades, pommettes et joues creuses dessous, tempes. `d` : la direction sur la boule de départ (longueur 1).
static func _skull_shape(d: Vector3) -> Vector3:
	var p: Vector3 = d * SKULL_RADII
	p.x *= lerpf(1.0, 0.7, smoothstep(0.25, 1.0, -d.y))
	p.z *= 1.0 + 0.1 * d.z if d.z > 0.0 else 1.0 + 0.06 * d.z
	var depth: float = 0.0
	for side: float in [-1.0, 1.0]:
		depth += 0.07 * smoothstep(0.915, 0.985, d.dot(eye_direction(side)))
		depth -= 0.012 * smoothstep(0.9, 0.98, d.dot(Vector3(side * 0.42, 0.42, -1.0).normalized()))
		depth -= 0.012 * smoothstep(0.9, 0.97, d.dot(Vector3(side * 0.85, -0.3, -0.55).normalized()))
		depth += 0.012 * smoothstep(0.92, 0.99, d.dot(Vector3(side, 0.15, -0.15).normalized()))
		depth += 0.018 * smoothstep(0.93, 0.99, d.dot(Vector3(side * 0.65, -0.6, -0.45).normalized()))
	depth += 0.045 * smoothstep(0.965, 0.995, d.dot(Vector3(0.0, -0.3, -1.0).normalized()))
	return p - d * depth


## Le fond des orbites et du nez (0 ailleurs, 1 au plus profond) : ils s'éteignent.
static func _hollowness(d: Vector3) -> float:
	var h: float = smoothstep(0.965, 0.99, d.dot(Vector3(0.0, -0.3, -1.0).normalized()))
	for side: float in [-1.0, 1.0]:
		h = maxf(h, smoothstep(0.925, 0.975, d.dot(eye_direction(side))))
	return h


## La mâchoire, dans le repère de sa charnière : un fer à cheval de la tempe au menton, et ses dents.
static func _jaw(b: MeshBuilder) -> void:
	var path: PackedVector3Array = PackedVector3Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	var half: PackedVector3Array = PackedVector3Array([
		Vector3(-0.068, 0.01, 0.0), Vector3(-0.064, -0.04, -0.012), Vector3(-0.05, -0.064, -0.05),
		Vector3(-0.028, -0.074, -0.086),
	])
	for p: Vector3 in half:
		path.append(p)
		radii.append(0.014)
	path.append(Vector3(0.0, -0.078, -0.1))
	radii.append(0.017)
	for i: int in range(half.size() - 1, -1, -1):
		path.append(Vector3(-half[i].x, half[i].y, half[i].z))
		radii.append(0.014)
	b.tube(path, radii, 6, BONE)
	for k: int in 8:
		var a: float = lerpf(-0.9, 0.9, k / 7.0)
		b.ellipsoid(Vector3(sin(a) * 0.04, -0.05, -cos(a) * 0.078), Vector3(0.006, 0.011, 0.0055), 4, 6, BONE)


## Le tronc, dans le modèle : la colonne (qui finit en queue sous les côtes), ses vertèbres, sept paires de côtes, le
## sternum, les clavicules et les omoplates. La queue ondule et se dissout vers sa pointe.
static func _torso(b: MeshBuilder) -> void:
	var first: int = b.vertices.size()
	var spine: PackedVector3Array = PackedVector3Array([
		Vector3(0.0, 1.57, 0.035), Vector3(0.0, 1.45, 0.05), Vector3(0.0, 1.3, 0.065), Vector3(0.0, 1.15, 0.05),
		Vector3(0.0, 1.0, 0.05), Vector3(0.0, 0.85, 0.08), Vector3(0.0, 0.7, 0.13), Vector3(0.0, 0.56, 0.2),
		Vector3(0.0, 0.44, 0.28),
	])
	var spine_radii: PackedFloat32Array = PackedFloat32Array()
	for i: int in spine.size():
		spine_radii.append(lerpf(0.012, 0.004, i / float(spine.size() - 1)))
	b.tube(spine, spine_radii, 6, BONE)
	for i: int in 22:
		var f: float = i / 21.0
		var at: Vector3 = _along(spine, f)
		var r: float = lerpf(0.024, 0.008, pow(f, 0.8))
		b.ellipsoid(at, Vector3(r * 1.4, r * 0.75, r * 1.1), 5, 8, BONE)
		if f < 0.55:
			b.tube(PackedVector3Array([at, at + Vector3(0.0, -r * 0.6, r * 1.8)]),
					PackedFloat32Array([r * 0.45, r * 0.15]), 5, BONE)
	for i: int in RIB_REACH.size():
		var y: float = 1.45 - 0.062 * i
		var barrel: float = sin(PI * (i + 1) / 8.0)
		var half_width: float = 0.105 + 0.055 * barrel
		var depth: float = 0.085 + 0.02 * barrel
		for side: float in [-1.0, 1.0]:
			var rib: PackedVector3Array = PackedVector3Array()
			var radii: PackedFloat32Array = PackedFloat32Array()
			for k: int in 10:
				var t: float = lerpf(0.3, RIB_REACH[i], k / 9.0)
				rib.append(Vector3(side * half_width * sin(t), y - 0.075 * pow(t / PI, 1.5), -0.02 + depth * cos(t)))
				radii.append(lerpf(0.011, 0.007, k / 9.0))
			b.tube(rib, radii, 6, BONE)
	b.tube(PackedVector3Array([Vector3(0.0, 1.47, -0.11), Vector3(0.0, 1.35, -0.125), Vector3(0.0, 1.22, -0.12),
			Vector3(0.0, 1.17, -0.105)]), PackedFloat32Array([0.018, 0.016, 0.012, 0.004]), 6, BONE)
	for side: float in [-1.0, 1.0]:
		b.tube(PackedVector3Array([Vector3(side * 0.02, 1.475, -0.11), Vector3(side * 0.1, 1.5, -0.085),
				Vector3(side * 0.18, 1.5, -0.02)]), PackedFloat32Array([0.011, 0.009, 0.012]), 6, BONE)
		b.ellipsoid(Vector3(side * 0.1, 1.37, 0.095), Vector3(0.055, 0.075, 0.012), 6, 10, BONE)
	for i: int in range(first, b.vertices.size()):
		var y: float = b.vertices[i].y
		b.paint(i, Color(0.8 * (1.0 - smoothstep(0.45, 1.0, y)), 0.6 * (1.0 - smoothstep(0.42, 0.75, y)), 0.5))


## Le linceul, dans le modèle : drapé sur les épaules (plus bas sur leur pente et devant), il tombe en s'évasant et
## traîne vers l'arrière ; ouvert devant ; son bas
## est déchiré en lambeaux de longueurs inégales (une colonne sur deux plus courte, au hasard d'une graine fixe).
static func _shroud(b: MeshBuilder) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var lengths: PackedFloat32Array = PackedFloat32Array()
	for k: int in SHROUD_COLUMNS:
		lengths.append(rng.randf_range(0.78, 1.0) if k % 2 == 0 else rng.randf_range(0.45, 0.72))
	var rows: Array[PackedVector3Array] = []
	var tints: Array[PackedColorArray] = []
	for r: int in SHROUD_ROWS:
		var v: float = r / float(SHROUD_ROWS - 1)
		var row: PackedVector3Array = PackedVector3Array()
		var tint: PackedColorArray = PackedColorArray()
		for k: int in SHROUD_COLUMNS:
			var angle: float = lerpf(-SHROUD_SPAN, SHROUD_SPAN, k / float(SHROUD_COLUMNS - 1))
			var down: float = v * lengths[k]
			var spread: float = pow(down, 0.8)
			var top: float = SHROUD_TOP - 0.05 * absf(sin(angle)) - 0.06 * maxf(0.0, -cos(angle))
			var back: float = 0.03 + 0.22 * down * down
			row.append(Vector3(sin(angle) * lerpf(0.23, 0.44, spread), top - down * SHROUD_LENGTH,
					back + cos(angle) * lerpf(0.13, 0.38, spread)))
			tint.append(Color(pow(down, 1.2), down * down, 0.42))
		rows.append(row)
		tints.append(tint)
	b.sheet(rows, tints)


## Le bras, dans le repère de l'épaule, pendant vers le bas : la tête de l'os, l'os, le coude.
static func _upper_arm(b: MeshBuilder) -> void:
	b.ellipsoid(Vector3.ZERO, Vector3(0.03, 0.03, 0.03), 6, 10, BONE)
	b.tube(PackedVector3Array([Vector3(0.0, -0.015, 0.0), Vector3(0.0, -0.06, 0.0), Vector3(0.0, -0.15, 0.0),
			Vector3(0.0, -0.25, 0.0), Vector3(0.0, -0.29, 0.0)]), PackedFloat32Array([0.02, 0.015, 0.013, 0.016, 0.022]),
			7, BONE)
	b.ellipsoid(Vector3(0.0, -UPPER_ARM_LENGTH, 0.0), Vector3(0.026, 0.018, 0.02), 5, 8, BONE)


## L'avant-bras, dans le repère du coude : deux os côte à côte (le même pour les deux bras).
static func _forearm(b: MeshBuilder) -> void:
	for x: float in [0.012, -0.012]:
		b.tube(PackedVector3Array([Vector3(x, -0.01, 0.0), Vector3(x * 1.1, -0.14, -0.004),
				Vector3(x * 1.25, -FOREARM_LENGTH + 0.01, 0.0)]), PackedFloat32Array([0.012, 0.009, 0.011]), 6, BONE)


## Une main, dans le repère du poignet, pendant vers le bas : le carpe, quatre longues griffes en éventail d'avant en
## arrière et un pouce devant ; elles se recourbent vers le corps (`inward` : +1 pour la main gauche, -1 la droite).
static func _hand(b: MeshBuilder, inward: float) -> void:
	b.ellipsoid(Vector3(0.0, -0.02, 0.0), Vector3(0.016, 0.022, 0.026), 5, 8, BONE)
	for f: int in CLAW_LENGTH.size():
		var z: float = lerpf(-0.024, 0.022, f / 3.0)
		var length: float = CLAW_LENGTH[f]
		b.tube(PackedVector3Array([Vector3(0.0, -0.035, z), Vector3(inward * 0.005, -0.035 - 0.35 * length, z * 1.2),
				Vector3(inward * 0.02, -0.035 - 0.65 * length, z * 1.35),
				Vector3(inward * 0.05, -0.035 - 0.88 * length, z * 1.4), Vector3(inward * 0.085, -0.035 - length, z * 1.4)]),
				PackedFloat32Array([0.0075, 0.0065, 0.0055, 0.0035, 0.0006]), 5, BONE)
	b.tube(PackedVector3Array([Vector3(0.0, -0.025, -0.03), Vector3(inward * 0.01, -0.06, -0.055),
			Vector3(inward * 0.03, -0.1, -0.065), Vector3(inward * 0.055, -0.13, -0.06)]),
			PackedFloat32Array([0.008, 0.0065, 0.004, 0.0006]), 5, BONE)


## Le point à la fraction `f` (0 à 1) de la longueur du chemin `path`.
static func _along(path: PackedVector3Array, f: float) -> Vector3:
	var total: float = 0.0
	for i: int in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
	var rest: float = f * total
	for i: int in path.size() - 1:
		var step: float = path[i].distance_to(path[i + 1])
		if rest <= step:
			return path[i].lerp(path[i + 1], rest / step)
		rest -= step
	return path[path.size() - 1]
