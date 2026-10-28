class_name TreeBuilder extends RefCounted
## Un arbre procédural : un tronc, puis à chaque niveau des branches filles plus courtes et plus fines, réparties
## autour de leur parent et écartées d'un angle, avec un peu de hasard tiré d'une graine (le même arbre à chaque
## fois). Les branches deviennent des prismes à quatre faces ; les feuilles se posent au bout des rameaux.


## Une branche : son départ, son arrivée, son rayon, son niveau (0 : le tronc).
class Segment extends RefCounted:
	var start: Vector3
	var end: Vector3
	var radius: float
	var level: int

	func _init(from: Vector3, to: Vector3, thickness: float, depth_level: int) -> void:
		start = from
		end = to
		radius = thickness
		level = depth_level


## Le nombre de branches d'un arbre : 1 + k + k² + … + k^profondeur (k : filles par branche).
static func segment_count(settings: TreeSettings) -> int:
	var total: int = 0
	var level_count: int = 1
	for _level: int in settings.depth + 1:
		total += level_count
		level_count *= settings.children
	return total


## La direction d'une branche fille : la direction `parent` penchée de `tilt` radians, tournée de `turn` radians
## autour d'elle.
static func child_direction(parent: Vector3, tilt: float, turn: float) -> Vector3:
	var side: Vector3 = parent.cross(Vector3.FORWARD if absf(parent.dot(Vector3.UP)) > 0.99 else Vector3.UP).normalized()
	return parent.rotated(side, tilt).rotated(parent, turn).normalized()


## Toutes les branches de l'arbre, tronc d'abord, tirées avec la graine des réglages.
static func grow(settings: TreeSettings) -> Array[Segment]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = settings.random_seed
	var segments: Array[Segment] = []
	_branch(Vector3.ZERO, Vector3.UP, settings.trunk_length, settings.trunk_radius, 0, settings, rng, segments)
	return segments


static func _branch(origin: Vector3, direction: Vector3, length: float, radius: float, level: int,
		settings: TreeSettings, rng: RandomNumberGenerator, out: Array[Segment]) -> void:
	var tip: Vector3 = origin + direction * length
	out.append(Segment.new(origin, tip, radius, level))
	if level >= settings.depth:
		return
	for i: int in settings.children:
		var tilt: float = deg_to_rad(settings.spread_degrees + rng.randf_range(-settings.jitter_degrees, settings.jitter_degrees))
		var turn: float = TAU * float(i) / float(settings.children) + rng.randf_range(-0.2, 0.2)
		_branch(tip, child_direction(direction, tilt, turn), length * settings.length_ratio,
			radius * settings.radius_ratio, level + 1, settings, rng, out)


## Les branches terminales (sans filles) : celles du dernier niveau.
static func tips(segments: Array[Segment], settings: TreeSettings) -> Array[Segment]:
	var found: Array[Segment] = []
	for s: Segment in segments:
		if s.level == settings.depth:
			found.append(s)
	return found


## Le maillage du bois : chaque branche en prisme à quatre faces, du rayon de sa base à 70 % de ce rayon au bout.
static func wood_mesh(segments: Array[Segment]) -> ArrayMesh:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s: Segment in segments:
		var axis: Vector3 = (s.end - s.start).normalized()
		var side: Vector3 = axis.cross(Vector3.FORWARD if absf(axis.dot(Vector3.UP)) > 0.99 else Vector3.UP).normalized()
		var other: Vector3 = axis.cross(side).normalized()
		var corners: Array[Vector3] = [side, other, -side, -other]
		for k: int in 4:
			var a: Vector3 = corners[k]
			var b: Vector3 = corners[(k + 1) % 4]
			var p0: Vector3 = s.start + a * s.radius
			var p1: Vector3 = s.start + b * s.radius
			var p2: Vector3 = s.end + b * s.radius * 0.7
			var p3: Vector3 = s.end + a * s.radius * 0.7
			for p: Vector3 in [p0, p2, p1, p0, p3, p2]:
				tool.add_vertex(p)
	tool.generate_normals()
	return tool.commit()


## Les positions des feuilles : `leaves_per_tip` autour du bout de chaque rameau, tirées avec la graine.
static func leaf_positions(segments: Array[Segment], settings: TreeSettings) -> PackedVector3Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = settings.random_seed + 1
	var points: PackedVector3Array = PackedVector3Array()
	for s: Segment in tips(segments, settings):
		var reach: float = (s.end - s.start).length() * 0.5
		for _i: int in settings.leaves_per_tip:
			points.append(s.end + Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.5, 1.0), rng.randf_range(-1.0, 1.0)) * reach)
	return points
