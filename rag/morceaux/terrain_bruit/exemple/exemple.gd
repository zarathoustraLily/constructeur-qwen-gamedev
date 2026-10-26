extends Node
## Exemple : terrain tiré d'un bruit. On construit les tableaux du maillage : (cells + 1)² sommets, 6 indices par carré,
## hauteurs dans [-height, height], normales tournées vers le haut en moyenne, et le même bruit (même graine) redonne
## le même terrain.

const CELLS := 32
const CELL_SIZE := 0.5
const HEIGHT := 3.0


func _ready() -> void:
	var a := HeightTerrain.build_arrays(_bruit(1234), CELLS, CELL_SIZE, HEIGHT)
	var b := HeightTerrain.build_arrays(_bruit(1234), CELLS, CELL_SIZE, HEIGHT)
	var sommets: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var normales: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var bas := INF
	var haut := -INF
	for p: Vector3 in sommets:
		bas = minf(bas, p.y)
		haut = maxf(haut, p.y)
	var moyenne := Vector3.ZERO
	for n: Vector3 in normales:
		moyenne += n
	moyenne /= normales.size()
	var sommets_b: PackedVector3Array = b[Mesh.ARRAY_VERTEX]
	var memes := sommets == sommets_b
	var mesh := HeightTerrain.build(_bruit(1234), CELLS, CELL_SIZE, HEIGHT)
	var ok := sommets.size() == (CELLS + 1) * (CELLS + 1) and indices.size() == CELLS * CELLS * 6
	ok = ok and bas >= -HEIGHT and haut <= HEIGHT and haut - bas > 0.5 and moyenne.y > 0.8 and memes
	if ok and mesh.get_surface_count() == 1:
		print("EXEMPLE VERIFIE : %d sommets, %d indices ; hauteurs de %.2f à %.2f m ; normale moyenne (%.2f, %.2f, %.2f) ; même graine, même terrain"
				% [sommets.size(), indices.size(), bas, haut, moyenne.x, moyenne.y, moyenne.z])
	else:
		push_error("%d sommets, %d indices, hauteurs %.2f à %.2f, normale moyenne %s, mêmes %s"
				% [sommets.size(), indices.size(), bas, haut, moyenne, memes])
	get_tree().quit()


func _bruit(graine: int) -> FastNoiseLite:
	var bruit := FastNoiseLite.new()
	bruit.seed = graine
	bruit.frequency = 0.05
	return bruit
