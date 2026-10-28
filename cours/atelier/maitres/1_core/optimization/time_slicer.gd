class_name TimeSlicer extends RefCounted
## Une mise à jour échelonnée : quand mille objets ont un travail coûteux (une recherche de chemin, une vue), on en
## fait `budget` par image, à tour de rôle, au lieu de tous à chaque image. Chacun est servi une fois tous les
## n / budget images, et le coût par image reste borné.

## L'indice du prochain objet à servir.
var cursor: int = 0


## Les indices à servir cette image parmi `count` objets, au plus `budget`, à partir du curseur, en revenant au
## début ; le curseur avance d'autant.
func next_batch(count: int, budget: int) -> Array[int]:
	var batch: Array[int] = []
	if count <= 0:
		return batch
	for _i: int in mini(budget, count):
		batch.append(cursor % count)
		cursor = (cursor + 1) % count
	return batch


## Le nombre d'images pour servir une fois chacun des `count` objets avec `budget` par image.
static func frames_per_cycle(count: int, budget: int) -> int:
	return ceili(float(count) / float(maxi(budget, 1)))
