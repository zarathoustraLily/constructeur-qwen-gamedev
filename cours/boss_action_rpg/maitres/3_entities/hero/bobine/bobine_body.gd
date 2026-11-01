class_name BobineBody extends RefCounted
## Le corps de Bobine, la poupée de bois : un maillage d'une seule surface, fait de pièces rigides posées sur le squelette
## des clips du héros. Chaque pièce se place d'après les os, à leur pose de repos : le corps suit donc ce squelette, et
## aucun chiffre ne répète ses mesures. Bobine regarde vers +Z dans ce repère ; sa gauche est en +X.
## La couleur d'un sommet porte aussi sa matière, dans son alpha : 1 le bois, 0,5 le tissu, 0 le métal
## (6_assets/Shader/Characters/bobine.gdshader).

## Le hêtre clair de ses membres.
const WOOD: Color = Color(0.76, 0.52, 0.31, 1.0)
## Le bois foncé de ses rotules et de ses sabots.
const WOOD_DARK: Color = Color(0.38, 0.22, 0.12, 1.0)
## Le fil rouge de la bobine.
const THREAD: Color = Color(0.66, 0.09, 0.07, 0.5)
## Le creux entre deux tours de fil.
const THREAD_DARK: Color = Color(0.47, 0.05, 0.05, 0.5)
## La laine de ses cheveux.
const YARN: Color = Color(0.86, 0.40, 0.11, 0.5)
## Le creux entre deux mèches de la tresse.
const YARN_DARK: Color = Color(0.64, 0.25, 0.07, 0.5)
## Le tissu de sa jupe.
const SKIRT: Color = Color(0.09, 0.27, 0.30, 0.5)
## L'ourlet de sa jupe.
const SKIRT_HEM: Color = Color(0.76, 0.66, 0.43, 0.5)
## Le fond de ses bas rayés.
const STOCKING: Color = Color(0.86, 0.80, 0.68, 0.5)
## Le laiton du dé à coudre.
const BRASS: Color = Color(0.86, 0.70, 0.42, 0.0)
## Les creux du laiton.
const BRASS_DARK: Color = Color(0.56, 0.42, 0.22, 0.0)
## Ses yeux : deux boutons noirs.
const BUTTON: Color = Color(0.02, 0.02, 0.03, 0.0)
## Le fard de ses joues.
const CHEEK: Color = Color(0.84, 0.42, 0.34, 1.0)
## Le ruban de sa tresse.
const RIBBON: Color = Color(0.13, 0.32, 0.56, 0.5)
## La part de l'ourlet qui suit les cuisses : le reste suit les hanches.
const HEM_ON_LEGS: float = 0.75
## Les pièces de la cape, en quinconce.
const PATCHES: PackedColorArray = [
	Color(0.36, 0.24, 0.15, 0.5), Color(0.20, 0.33, 0.27, 0.5), Color(0.56, 0.43, 0.25, 0.5), Color(0.30, 0.18, 0.27, 0.5),
	Color(0.44, 0.17, 0.12, 0.5),
]
## Le bas de chaque colonne de la cape, en mètres : un bord déchiré.
const CAPE_TEARS: PackedFloat32Array = [0.03, -0.05, 0.05, -0.02, -0.06, 0.04, -0.03, 0.02]
## Les colonnes de pièces de la cape.
const CAPE_COLUMNS: int = 8
## Les rangées de pièces de la cape.
const CAPE_ROWS: int = 5
## Les demi-axes de la tête, en mètres.
const HEAD_RADII: Vector3 = Vector3(0.165, 0.175, 0.16)

var _skeleton: Skeleton3D
var _b: PuppetBuilder = PuppetBuilder.new()
var _head: Vector3


func _init(skeleton: Skeleton3D) -> void:
	_skeleton = skeleton
	_head = _at("Head") + Vector3(0.0, 0.08, 0.017)


## Le corps de Bobine, posé sur `skeleton`.
static func build(skeleton: Skeleton3D) -> ArrayMesh:
	var body: BobineBody = BobineBody.new(skeleton)
	for side: String in ["Left", "Right"]:
		body._leg(side)
		body._arm(side)
	body._spool()
	body._skirt()
	body._head_and_face()
	body._thimble()
	body._hair()
	body._cape()
	return body._b.to_mesh()


func _at(bone_name: String) -> Vector3:
	return _skeleton.get_bone_global_rest(_skeleton.find_bone(bone_name)).origin


func _on(bone_name: String) -> void:
	_b.bone = _skeleton.find_bone(bone_name)


## Une jambe : cuisse, genou à rotule, mollet à bas rayé, sabot.
func _leg(side: String) -> void:
	var hip: Vector3 = _at(side + "UpperLeg")
	var knee: Vector3 = _at(side + "LowerLeg")
	var ankle: Vector3 = _at(side + "Foot")
	var toes: Vector3 = _at(side + "Toes")
	_on(side + "UpperLeg")
	_b.ball(hip, Vector3.ONE * 0.085, WOOD_DARK)
	_b.limb(hip, knee, PackedFloat32Array([0.08, 0.072, 0.06]), 10, WOOD)
	_on(side + "LowerLeg")
	_b.ball(knee, Vector3.ONE * 0.068, WOOD_DARK)
	var stripes: PackedVector2Array = PackedVector2Array()
	var tints: PackedColorArray = PackedColorArray()
	for ring: int in 13:
		var t: float = ring / 12.0
		stripes.append(Vector2(t, lerpf(0.062, 0.046, t)))
		tints.append(THREAD if (ring + 1) % 4 < 2 else STOCKING)
	_b.turned(knee, ankle, stripes, tints, 10)
	_on(side + "Foot")
	var heel: Vector3 = Vector3(ankle.x, 0.09, ankle.z - 0.06)
	var tip: Vector3 = Vector3(toes.x, 0.09, toes.z + 0.13)
	_b.turned(heel, tip, PackedVector2Array([Vector2(0.0, 0.05), Vector2(0.14, 0.086), Vector2(0.6, 0.088),
			Vector2(0.86, 0.074), Vector2(1.0, 0.035)]), PackedColorArray([WOOD_DARK]), 10)


## Un bras : épaule et coude à rotule, deux tiges, une main en moufle et son pouce.
func _arm(side: String) -> void:
	var shoulder: Vector3 = _at(side + "UpperArm")
	var elbow: Vector3 = _at(side + "LowerArm")
	var wrist: Vector3 = _at(side + "Hand")
	var knuckle: Vector3 = _at(side + "MiddleProximal")
	var thumb: Vector3 = _at(side + "ThumbProximal")
	_on(side + "UpperArm")
	_b.ball(shoulder, Vector3.ONE * 0.082, WOOD_DARK)
	_b.limb(shoulder, elbow, PackedFloat32Array([0.056, 0.05, 0.043]), 10, WOOD)
	_on(side + "LowerArm")
	_b.ball(elbow, Vector3.ONE * 0.056, WOOD_DARK)
	_b.limb(elbow, wrist, PackedFloat32Array([0.044, 0.04, 0.034]), 10, WOOD)
	_on(side + "Hand")
	_b.ball(wrist, Vector3.ONE * 0.04, WOOD_DARK)
	_b.limb(wrist, wrist.lerp(knuckle, 1.6), PackedFloat32Array([0.034, 0.05, 0.055, 0.044, 0.016]), 10, WOOD)
	_b.limb(wrist.lerp(thumb, 0.5), wrist.lerp(thumb, 1.5), PackedFloat32Array([0.022, 0.021, 0.009]), 8, WOOD)


## Le buste : une bobine de fil rouge entre deux joues de bois, et la tige qui porte les épaules.
func _spool() -> void:
	var foot: Vector3 = _at("Spine") + Vector3.DOWN * 0.05
	var top: Vector3 = _at("Neck") + Vector3.DOWN * 0.07
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.17), Vector2(0.015, 0.205), Vector2(0.07, 0.205),
			Vector2(0.09, 0.15)])
	var tints: PackedColorArray = PackedColorArray([WOOD, WOOD, WOOD, WOOD])
	for ring: int in 25:
		var t: float = ring / 24.0
		profile.append(Vector2(lerpf(0.1, 0.9, t), 0.178 if ring % 2 == 0 else 0.170))
		tints.append(THREAD if ring % 2 == 0 else THREAD_DARK)
	profile.append_array(PackedVector2Array([Vector2(0.91, 0.15), Vector2(0.93, 0.205), Vector2(0.985, 0.205), Vector2(1.0, 0.17)]))
	tints.append_array(PackedColorArray([WOOD, WOOD, WOOD, WOOD]))
	_on("Chest")
	_b.turned(foot, top, profile, tints, 18)
	_on("UpperChest")
	var left: Vector3 = _at("LeftUpperArm")
	var right: Vector3 = _at("RightUpperArm")
	_b.limb(left, right, PackedFloat32Array([0.05, 0.05]), 10, WOOD_DARK)
	_on("Neck")
	_b.limb(top + Vector3.UP * 0.02, _at("Head"), PackedFloat32Array([0.058, 0.044]), 10, WOOD)


## La taille : un plateau de bois sous la bobine, et une jupe ouverte, large pour que les cuisses s'y balancent.
func _skirt() -> void:
	var waist: Vector3 = _at("Hips") + Vector3.UP * 0.075
	_on("Hips")
	_b.limb(waist, waist + Vector3.DOWN * 0.18, PackedFloat32Array([0.16, 0.175, 0.15]), 14, WOOD_DARK)
	var first: int = _b.vertices.size()
	_b.turned(waist, waist + Vector3.DOWN * 0.40, PackedVector2Array([Vector2(0.0, 0.178), Vector2(0.22, 0.2), Vector2(0.55, 0.255),
			Vector2(0.86, 0.315), Vector2(0.9, 0.32), Vector2(1.0, 0.33)]),
			PackedColorArray([SKIRT, SKIRT, SKIRT, SKIRT, SKIRT_HEM, SKIRT_HEM]), 18, false)
	var left: int = _skeleton.find_bone("LeftUpperLeg")
	var right: int = _skeleton.find_bone("RightUpperLeg")
	for vertex: int in range(first, _b.vertices.size()):
		var spot: Vector3 = _b.vertices[vertex]
		var on_legs: float = HEM_ON_LEGS * smoothstep(0.0, 0.40, waist.y - spot.y)
		var toward_left: float = smoothstep(-0.12, 0.12, spot.x)
		if on_legs > 0.0:
			_b.share(vertex, left, on_legs * toward_left)
			_b.share(vertex, right, on_legs * (1.0 - toward_left))


## Le point de la surface de la tête devant (`x`, `y`), qui font de -1 à 1 sur ses demi-axes.
func _on_face(x: float, y: float) -> Vector3:
	return _head + Vector3(x, y, sqrt(maxf(1.0 - x * x - y * y, 0.0))) * HEAD_RADII


## La tête : une boule de bois, des boutons pour yeux, un point de fil pour bouche.
func _head_and_face() -> void:
	_on("Head")
	_b.ball(_head, HEAD_RADII, WOOD)
	for x: float in [-1.0, 1.0]:
		var eye: Vector3 = _on_face(x * 0.38, 0.1)
		_b.ball(eye, Vector3(0.036, 0.036, 0.013), BUTTON)
		_b.ball(eye + Vector3(0.010, 0.012, 0.012), Vector3.ONE * 0.008, BRASS)
		_b.ball(_on_face(x * 0.6, -0.22), Vector3(0.036, 0.024, 0.008), CHEEK)
	_b.ball(_on_face(0.0, -0.08), Vector3.ONE * 0.02, WOOD)
	_b.begin_part()
	_b.tube(PackedVector3Array([_on_face(-0.22, -0.42), _on_face(0.0, -0.5), _on_face(0.22, -0.42)]),
			PackedFloat32Array([0.006, 0.007, 0.006]), 5, THREAD)
	_b.end_part()


## Le dé à coudre qui lui sert de casque, un peu de travers.
func _thimble() -> void:
	var axis: Vector3 = Vector3(0.12, 1.0, -0.1).normalized()
	var brim: Vector3 = _head + axis * 0.09
	var profile: PackedVector2Array = PackedVector2Array([Vector2(0.0, 0.166), Vector2(0.03, 0.176), Vector2(0.1, 0.176), Vector2(0.13, 0.164)])
	var tints: PackedColorArray = PackedColorArray([BRASS_DARK, BRASS, BRASS, BRASS_DARK])
	for ring: int in 13:
		var t: float = ring / 12.0
		profile.append(Vector2(lerpf(0.16, 0.86, t), lerpf(0.162, 0.134, t) - (0.003 if ring % 2 == 1 else 0.0)))
		tints.append(BRASS if ring % 2 == 0 else BRASS_DARK)
	profile.append_array(PackedVector2Array([Vector2(0.92, 0.122), Vector2(0.97, 0.094), Vector2(1.0, 0.05)]))
	tints.append_array(PackedColorArray([BRASS, BRASS, BRASS]))
	_on("Head")
	_b.turned(brim, brim + axis * 0.235, profile, tints, 18)


## Ses cheveux : une frange de laine, une tresse dans le dos, un ruban.
func _hair() -> void:
	_on("Head")
	for i: int in range(-3, 4):
		var u: float = i / 3.5
		var from: Vector3 = _on_face(u * 0.72, 0.62)
		var middle: Vector3 = _on_face(u * 0.84, 0.4) + Vector3.BACK * 0.02
		var to: Vector3 = _on_face(u * 0.92, 0.2) + Vector3.BACK * 0.01
		_b.begin_part()
		_b.tube(PackedVector3Array([from, middle, to]), PackedFloat32Array([0.02, 0.019, 0.009]), 6, YARN)
		_b.end_part()
	_on("UpperChest")
	var knots: PackedVector3Array = PackedVector3Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	var spine: Curve3D = Curve3D.new()
	for point: Vector3 in [_head + Vector3(0.0, 0.03, -0.14), _head + Vector3(0.0, -0.12, -0.25), _head + Vector3(0.02, -0.3, -0.33),
			_head + Vector3(-0.015, -0.5, -0.355), _head + Vector3(0.012, -0.68, -0.375)]:
		spine.add_point(point, Vector3(0.0, 0.05, 0.0), Vector3(0.0, -0.05, 0.0))
	var length: float = spine.get_baked_length()
	var count: int = 25
	for i: int in count:
		var t: float = float(i) / (count - 1)
		knots.append(spine.sample_baked(t * length))
		radii.append(lerpf(0.058, 0.03, t) * (1.0 if i % 2 == 0 else 0.76))
	var first: int = _b.vertices.size()
	_b.begin_part()
	_b.tube(knots, radii, 7, YARN)
	_b.end_part()
	for ring: int in range(1, count, 2):
		for k: int in 7:
			_b.paint(first + ring * 7 + k, YARN_DARK)
	var tail: Vector3 = knots[count - 1]
	_b.ball(tail + Vector3(0.05, 0.0, -0.01), Vector3(0.05, 0.03, 0.018), RIBBON)
	_b.ball(tail + Vector3(-0.05, 0.0, -0.01), Vector3(0.05, 0.03, 0.018), RIBBON)
	_b.ball(tail, Vector3.ONE * 0.022, RIBBON)


## La cape rapiécée : des carrés de tissu cousus côte à côte, du haut du dos jusqu'aux hanches, au bord déchiré.
func _cape() -> void:
	_on("UpperChest")
	for column: int in CAPE_COLUMNS:
		for row: int in CAPE_ROWS:
			var a: Vector3 = _cape_point(column, row)
			var b: Vector3 = _cape_point(column + 1, row)
			var c: Vector3 = _cape_point(column + 1, row + 1)
			var d: Vector3 = _cape_point(column, row + 1)
			var tint: Color = PATCHES[(column * 3 + row * 2) % PATCHES.size()]
			_b.begin_part()
			var corner: int = _b.add_vertex(a, tint)
			_b.add_vertex(b, tint)
			_b.add_vertex(c, tint)
			_b.add_vertex(d, tint)
			_b.add_triangle(corner, corner + 1, corner + 2)
			_b.add_triangle(corner, corner + 2, corner + 3)
			_b.end_part()


## Le coin (`column`, `row`) de la cape, vu du dos : elle s'élargit vers le bas et s'écarte du buste.
func _cape_point(column: int, row: int) -> Vector3:
	var u: float = 2.0 * column / CAPE_COLUMNS - 1.0
	var v: float = float(row) / CAPE_ROWS
	var tear: float = CAPE_TEARS[column % CAPE_TEARS.size()] if row == CAPE_ROWS else 0.0
	return Vector3(u * lerpf(0.2, 0.38, v), lerpf(1.5, 0.86, v) + tear, -0.2 - 0.09 * (1.0 - u * u) - 0.1 * v)
