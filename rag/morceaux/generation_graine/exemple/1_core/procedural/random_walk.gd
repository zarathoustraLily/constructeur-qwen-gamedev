class_name RandomWalk
extends RefCounted
## Grotte creusée par une marche au hasard sur une grille. Le hasard vient du RandomNumberGenerator reçu : même graine,
## même grotte.


## Creuse `steps` pas depuis le centre d'une grille de `size` cases, sans en sortir. Rend les cases creusées, dans
## l'ordre où elles l'ont été (chacune une fois).
static func carve(rng: RandomNumberGenerator, size: Vector2i, steps: int) -> Array[Vector2i]:
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var cell := Vector2i(floori(size.x / 2.0), floori(size.y / 2.0))  # size / 2 : division entière, avertissement
	var seen: Dictionary[Vector2i, bool] = {cell: true}
	var cells: Array[Vector2i] = [cell]
	for _step: int in steps:
		var next := cell + directions[rng.randi_range(0, directions.size() - 1)]
		if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
			continue
		cell = next
		if not seen.has(cell):
			seen[cell] = true
			cells.append(cell)
	return cells
