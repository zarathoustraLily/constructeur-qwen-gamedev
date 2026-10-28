class_name GridMesh extends RefCounted
## Une grille plate de quadrilatères, centrée sur l'origine, dans le plan xz : la base d'une surface qu'on déforme
## (eau, terrain). Les sommets sont rangés ligne par ligne, chaque quadrilatère en deux triangles.


## Le nombre de sommets d'une grille de `cells` cases : (colonnes + 1) × (lignes + 1).
static func vertex_count(cells: Vector2i) -> int:
	return (cells.x + 1) * (cells.y + 1)


## Les positions des sommets d'une grille de taille `size` (en mètres, x et z) en `cells` cases, y nul, ligne par
## ligne (z croissant), de -size/2 à +size/2.
static func positions(size: Vector2, cells: Vector2i) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for row: int in cells.y + 1:
		for column: int in cells.x + 1:
			var u: float = float(column) / float(cells.x)
			var v: float = float(row) / float(cells.y)
			points.append(Vector3((u - 0.5) * size.x, 0.0, (v - 0.5) * size.y))
	return points


## Les indices des triangles : deux par case, tournés pour que leur face regarde vers le haut (+y).
static func indices(cells: Vector2i) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	var stride: int = cells.x + 1
	for row: int in cells.y:
		for column: int in cells.x:
			var a: int = row * stride + column
			var b: int = a + 1
			var c: int = a + stride
			var d: int = c + 1
			result.append_array(PackedInt32Array([a, b, c, b, d, c]))
	return result


## Le maillage d'une grille dont les sommets sont `points` (rangés comme `positions`) : triangles, normales
## calculées, coordonnées de texture de 0 à 1.
static func build(points: PackedVector3Array, cells: Vector2i) -> ArrayMesh:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in points.size():
		var column: int = i % (cells.x + 1)
		var row: int = floori(float(i) / float(cells.x + 1))
		tool.set_uv(Vector2(float(column) / float(cells.x), float(row) / float(cells.y)))
		tool.add_vertex(points[i])
	for index: int in indices(cells):
		tool.add_index(index)
	tool.generate_normals()
	return tool.commit()
