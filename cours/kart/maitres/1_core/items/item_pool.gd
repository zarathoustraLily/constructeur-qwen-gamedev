class_name ItemPool extends Resource
## Réserve d'objets (5_data/items/item_pool.tres) dans laquelle les boîtes tirent l'objet donné : chaque objet a
## son poids ; sans poids pour chacun, le tirage est uniforme. Le hasard vient de celui qui tire.

## Objets possibles.
@export var items: Array[ItemType] = []
## Poids de chaque objet, dans le même ordre.
@export var weights: Array[float] = []


## Tire un objet avec le hasard de `rng`, selon les poids ; null si la réserve est vide, ou si tous les poids
## sont nuls.
func draw(rng: RandomNumberGenerator) -> ItemType:
	if items.is_empty():
		return null
	if weights.size() != items.size():
		return items[rng.randi_range(0, items.size() - 1)]
	var total := 0.0
	for weight: float in weights:
		total += maxf(weight, 0.0)
	if total <= 0.0:
		return null
	var pick := rng.randf() * total
	for index: int in items.size():
		pick -= maxf(weights[index], 0.0)
		if pick < 0.0:
			return items[index]
	return items[items.size() - 1]
