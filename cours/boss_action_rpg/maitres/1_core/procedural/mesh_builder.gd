class_name MeshBuilder extends RefCounted
## L'outil de maillage des modèles procéduraux : il empile des formes (boules déformables, tubes le long d'un chemin,
## nappes à deux faces) dans un seul jeu de tableaux et en fait un ArrayMesh d'une seule surface (un seul lot de dessin).
## Les formes se rangent en pièces (begin_part, end_part) : les normales lisses se calculent pièce par pièce, à la fin,
## pour qu'une forme puisse être déformée sommet par sommet avant (move_vertex). Les triangles tournent dans le sens des
## aiguilles d'une montre vus de l'extérieur : c'est leur face avant pour Godot. Chaque sommet porte une couleur, que le
## shader lit comme des poids.

## Les positions.
var vertices: PackedVector3Array = PackedVector3Array()
## Les normales (nulles jusqu'à la fin de leur pièce).
var normals: PackedVector3Array = PackedVector3Array()
## Les couleurs des sommets (des poids pour le shader).
var colors: PackedColorArray = PackedColorArray()
## Les triangles, trois indices chacun.
var indices: PackedInt32Array = PackedInt32Array()

var _part_vertex: int = 0
var _part_index: int = 0


## Commence une pièce : ses normales se calculeront à end_part.
func begin_part() -> void:
	_part_vertex = vertices.size()
	_part_index = indices.size()


## Finit la pièce : la normale de chaque sommet est la moyenne des faces qui le touchent (pondérée par leur aire).
func end_part() -> void:
	for t: int in range(_part_index, indices.size(), 3):
		var a: int = indices[t]
		var b: int = indices[t + 1]
		var c: int = indices[t + 2]
		var face: Vector3 = (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
		normals[a] += face
		normals[b] += face
		normals[c] += face
	for i: int in range(_part_vertex, vertices.size()):
		normals[i] = normals[i].normalized() if not normals[i].is_zero_approx() else Vector3.UP


## Ajoute un sommet ; rend son indice.
func add_vertex(position: Vector3, color: Color) -> int:
	vertices.append(position)
	normals.append(Vector3.ZERO)
	colors.append(color)
	return vertices.size() - 1


## Déplace le sommet `index` (avant la fin de sa pièce).
func move_vertex(index: int, position: Vector3) -> void:
	vertices[index] = position


## Change la couleur du sommet `index`.
func paint(index: int, color: Color) -> void:
	colors[index] = color


## Ajoute le triangle a, b, c (dans le sens des aiguilles d'une montre vu de l'extérieur).
func add_triangle(a: int, b: int, c: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)


## Coud deux rangées de `count` sommets (qui commencent aux indices `row_a` et `row_b`) ; `closed` relie le dernier au
## premier ; `flip` retourne les faces.
func stitch(row_a: int, row_b: int, count: int, closed: bool, flip: bool = false) -> void:
	for k: int in (count if closed else count - 1):
		var k1: int = (k + 1) % count
		if flip:
			add_triangle(row_a + k, row_b + k1, row_b + k)
			add_triangle(row_a + k, row_a + k1, row_b + k1)
		else:
			add_triangle(row_a + k, row_b + k, row_b + k1)
			add_triangle(row_a + k, row_b + k1, row_a + k1)


## Ferme un anneau de `count` sommets (à partir de `ring`) sur le sommet `tip` ; `flip` retourne les faces.
func fan(tip: int, ring: int, count: int, flip: bool) -> void:
	for k: int in count:
		var k1: int = (k + 1) % count
		if flip:
			add_triangle(tip, ring + k1, ring + k)
		else:
			add_triangle(tip, ring + k, ring + k1)


## Une boule de centre `center` et de demi-axes `radii` : un pôle en haut, `rings` - 1 anneaux de `segments` sommets,
## un pôle en bas. Rend l'indice de son premier sommet.
func ellipsoid(center: Vector3, radii: Vector3, rings: int, segments: int, color: Color) -> int:
	var first: int = add_vertex(center + Vector3(0.0, radii.y, 0.0), color)
	for j: int in range(1, rings):
		var polar: float = PI * j / rings
		for k: int in segments:
			var azimuth: float = TAU * k / segments
			var d: Vector3 = Vector3(sin(polar) * cos(azimuth), cos(polar), sin(polar) * sin(azimuth))
			add_vertex(center + d * radii, color)
	var bottom: int = add_vertex(center - Vector3(0.0, radii.y, 0.0), color)
	fan(first, first + 1, segments, false)
	for j: int in rings - 2:
		stitch(first + 1 + j * segments, first + 1 + (j + 1) * segments, segments, true)
	fan(bottom, first + 1 + (rings - 2) * segments, segments, true)
	return first


## Un tube le long de `path` (deux points au moins), de rayon `radii[i]` au point i, à `sides` côtés ; ses deux bouts
## se ferment en pointe courte. Ses anneaux suivent le chemin sans vriller (repère transporté d'un point à l'autre).
func tube(path: PackedVector3Array, radii: PackedFloat32Array, sides: int, color: Color) -> void:
	var count: int = path.size()
	var first: int = vertices.size()
	var normal: Vector3 = Vector3.ZERO
	for i: int in count:
		var tangent: Vector3 = (path[mini(i + 1, count - 1)] - path[maxi(i - 1, 0)]).normalized()
		if i == 0:
			normal = _perpendicular(tangent)
		else:
			normal = (normal - tangent * normal.dot(tangent)).normalized()
		var binormal: Vector3 = tangent.cross(normal)
		for k: int in sides:
			var angle: float = TAU * k / sides
			add_vertex(path[i] + (normal * cos(angle) + binormal * sin(angle)) * radii[i], color)
	for i: int in count - 1:
		stitch(first + i * sides, first + (i + 1) * sides, sides, true)
	var start: Vector3 = path[0] - (path[1] - path[0]).normalized() * radii[0] * 0.6
	fan(add_vertex(start, color), first, sides, false)
	var end: Vector3 = path[count - 1] + (path[count - 1] - path[count - 2]).normalized() * radii[count - 1] * 0.6
	fan(add_vertex(end, color), first + (count - 1) * sides, sides, true)


## Une nappe à deux faces : des rangées de points (toutes de même longueur, couleurs dans `tints`, rangée par rangée)
## cousues l'une à l'autre. Chaque face a ses propres sommets, donc ses propres normales : un shader qui cache les faces
## arrière la montre des deux côtés. Les sommets de la face avant viennent d'abord, rangée par rangée, puis ceux de la
## face arrière, dans le même ordre.
func sheet(rows: Array[PackedVector3Array], tints: Array[PackedColorArray]) -> void:
	var count: int = rows[0].size()
	for flip: bool in [false, true]:
		var first: int = vertices.size()
		for r: int in rows.size():
			for k: int in count:
				add_vertex(rows[r][k], tints[r][k])
		for r: int in rows.size() - 1:
			stitch(first + r * count, first + (r + 1) * count, count, false, flip)


## Le maillage : une surface de triangles (positions, normales, couleurs, indices).
func to_mesh() -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _perpendicular(v: Vector3) -> Vector3:
	var other: Vector3 = Vector3.UP if absf(v.y) < 0.9 else Vector3.RIGHT
	return v.cross(other).normalized()
