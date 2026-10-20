class_name ItemPool extends Resource
## Réserve d'objets (ressource) dans laquelle les boîtes tirent l'objet donné au joueur.

## Objets possibles.
@export var items : Array[ItemType]
## Poids de chaque objet, dans le même ordre. Le tirage pondéré n'est pas encore écrit : si les deux
## listes n'ont pas la même taille, le tirage est uniforme ; sinon, c'est toujours le premier objet.
@export var weights : Array[float]

## Tire un objet et en renvoie une copie : l'objet de la réserve n'est jamais donné lui-même.
func get_item() -> ItemType:
	if items.size() != weights.size():
		return items.pick_random().duplicate()
	
	#todo add simple weighted sampling
	return items[0].duplicate();
