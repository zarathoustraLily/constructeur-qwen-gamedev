class_name InventoryComponent
extends Node
## Inventaire à emplacements : chaque emplacement tient un objet et un nombre d'exemplaires, jusqu'à max_stack.
## Deux objets s'empilent s'ils ont le même id. Entrées : add(), remove(). Possède : les emplacements.
## Émet : changed (la vue de l'inventaire l'écoute pour se redessiner).

signal changed

@export var slot_count: int = 0

var _items: Array[ItemData] = []
var _counts: Array[int] = []


func _ready() -> void:
	if slot_count <= 0:
		push_error("InventoryComponent : slot_count n'est pas posé")
	_items.resize(slot_count)
	_counts.resize(slot_count)


## Ajoute `count` exemplaires : d'abord sur les piles du même objet, puis dans les emplacements vides.
## Rend ce qui n'a pas trouvé de place.
func add(item: ItemData, count: int) -> int:
	var left := count
	for i: int in slot_count:
		if left > 0 and _items[i] != null and _items[i].id == item.id:
			var moved := mini(left, item.max_stack - _counts[i])
			_counts[i] += moved
			left -= moved
	for i: int in slot_count:
		if left > 0 and _items[i] == null:
			var moved := mini(left, item.max_stack)
			_items[i] = item
			_counts[i] = moved
			left -= moved
	if left != count:
		changed.emit()
	return left


## Retire jusqu'à `count` exemplaires, en vidant d'abord les dernières piles. Rend le nombre retiré.
func remove(item: ItemData, count: int) -> int:
	var left := count
	for i: int in range(slot_count - 1, -1, -1):
		if left > 0 and _items[i] != null and _items[i].id == item.id:
			var moved := mini(left, _counts[i])
			_counts[i] -= moved
			left -= moved
			if _counts[i] == 0:
				_items[i] = null
	if left != count:
		changed.emit()
	return count - left


func count_of(item: ItemData) -> int:
	var total := 0
	for i: int in slot_count:
		if _items[i] != null and _items[i].id == item.id:
			total += _counts[i]
	return total


## Les nombres d'exemplaires, emplacement par emplacement (0 : vide).
func counts() -> Array[int]:
	return _counts.duplicate()
