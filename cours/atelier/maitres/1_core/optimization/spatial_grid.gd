class_name SpatialGrid extends RefCounted
## Une grille spatiale (sur le sol, x et z) : chaque objet est rangé dans la case qui le contient. Chercher les
## voisins d'un point ne regarde que les cases que le cercle touche, au lieu de comparer chaque objet à tous les
## autres : de n² comparaisons à quelques-unes par objet.

## Le côté d'une case, en mètres : de l'ordre du rayon des recherches.
var cell_size: float = 4.0

var _cells: Dictionary[Vector2i, Array] = {}
var _positions: Dictionary[int, Vector2] = {}


func _init(size: float = 4.0) -> void:
	cell_size = size


## La case qui contient `point`.
func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / cell_size), floori(point.y / cell_size))


## Range l'objet `id` en `point` ; un objet déjà rangé est déplacé.
func insert(id: int, point: Vector2) -> void:
	if _positions.has(id):
		remove(id)
	_positions[id] = point
	var cell: Vector2i = cell_of(point)
	if not _cells.has(cell):
		_cells[cell] = []
	_cells[cell].append(id)


## Retire l'objet `id` ; un objet inconnu est ignoré.
func remove(id: int) -> void:
	if not _positions.has(id):
		return
	var cell: Vector2i = cell_of(_positions[id])
	_cells[cell].erase(id)
	if _cells[cell].is_empty():
		_cells.erase(cell)
	_positions.erase(id)


## Les objets à `radius` mètres de `point` au plus, par ordre croissant d'identifiant : seules les cases que le
## cercle touche sont visitées, puis la vraie distance tranche.
func query(point: Vector2, radius: float) -> Array[int]:
	var found: Array[int] = []
	var low: Vector2i = cell_of(point - Vector2.ONE * radius)
	var high: Vector2i = cell_of(point + Vector2.ONE * radius)
	for x: int in range(low.x, high.x + 1):
		for y: int in range(low.y, high.y + 1):
			for id: int in _cells.get(Vector2i(x, y), []):
				if _positions[id].distance_to(point) <= radius:
					found.append(id)
	found.sort()
	return found


## Le nombre de cases occupées.
func cell_count() -> int:
	return _cells.size()
