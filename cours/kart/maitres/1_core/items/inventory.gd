class_name Inventory extends RefCounted
## Inventaire : quelques objets au plus (`capacity`), utilisés dans l'ordre où ils ont été ramassés. Il signale
## chaque changement : l'affichage l'écoute.

## Émis quand le contenu change.
signal changed

## Nombre maximal d'objets portés.
var capacity: int = 0
## Objets portés, du plus ancien au plus récent.
var items: Array[ItemType] = []


func _init(max_items: int) -> void:
	capacity = max_items


## Ajoute `item` ; faux si l'inventaire est plein.
func add(item: ItemType) -> bool:
	if item == null or items.size() >= capacity:
		return false
	items.append(item)
	changed.emit()
	return true


## Retire et rend le plus ancien objet ; null si l'inventaire est vide.
func take() -> ItemType:
	if items.is_empty():
		return null
	var item: ItemType = items.pop_front()
	changed.emit()
	return item


## Vrai si l'inventaire est plein.
func is_full() -> bool:
	return items.size() >= capacity
