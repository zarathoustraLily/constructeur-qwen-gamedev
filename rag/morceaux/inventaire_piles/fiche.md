# Inventaire à emplacements avec piles d'objets

Exemple vérifié dans Godot 4.7.2, sans fenêtre, en mesurant son comportement : `python -m usine.rag.morceaux verifier inventaire_piles`.

## Ce que fait le morceau

Un composant d'inventaire à emplacements : chaque objet (une ressource `ItemData` de `5_data/items/`) s'empile jusqu'à son `max_stack` ; ajouter remplit d'abord les piles du même objet puis les emplacements vides, et rend ce qui n'a pas trouvé de place ; retirer vide d'abord les dernières piles. Le signal `changed` prévient la vue.

## Quand l'employer

Sac du joueur, coffre, boutique, barre d'objets rapides, munitions.

Dans un projet qui suit le plan : la définition des objets dans `1_core/data/item_data.gd` et un `.tres` par objet dans `5_data/items/` (principe 2) ; le composant dans `1_core/components/` (un composant par responsabilité) ; l'affichage dans `4_ui/`, qui écoute `changed`.

## Le code (`1_core/components/inventory_component.gd`, vérifié)

```gdscript
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
```

## Le code (`1_core/data/item_data.gd`, vérifié)

```gdscript
class_name ItemData
extends Resource
## Définition d'un objet, immuable pendant la partie : ses valeurs vivent dans un .tres de 5_data/items/.

## Identifiant stable, en snake_case, jamais renommé : deux objets de même id s'empilent.
@export var id: StringName
@export var display_name: String = ""
## Nombre d'exemplaires par emplacement (1 : ne s'empile pas).
@export var max_stack: int = 1


## Erreurs de la définition ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).is_empty() or String(id) != String(id).to_snake_case():
		errors.append("%s : id « %s » vide ou hors snake_case" % [resource_path, id])
	if max_stack < 1:
		errors.append("%s : max_stack %d (attendu >= 1)" % [resource_path, max_stack])
	return errors
```

## Le code (`5_data/items/potion.tres`, vérifié)

```ini
[gd_resource type="Resource" script_class="ItemData" format=3]

[ext_resource type="Script" path="res://1_core/data/item_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"potion"
display_name = "Potion"
max_stack = 10
```

## Le code (`5_data/items/sword.tres`, vérifié)

```ini
[gd_resource type="Resource" script_class="ItemData" format=3]

[ext_resource type="Script" path="res://1_core/data/item_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"sword"
display_name = "Épée"
max_stack = 1
```

## Ce que l'exemple mesure

`exemple/exemple.gd` : 25 potions → [10, 10, 5], reste 0 ; épée refusée (reste 1) ; 12 retirées → [10, 3, 0] ; épée acceptée ; 2 potions copiées (duplicate) empilées : 15 potions ; 4 signaux changed.

## Pièges

- Deux objets s'empilent s'ils ont le même `id`, pas s'ils sont le même objet : `duplicate()` donne un autre objet de même id (mesuré : 2 potions copiées s'empilent avec les autres).
- `add` rend le reste : un ramassage doit le laisser au sol, pas le perdre (mesuré : épée refusée, reste 1, inventaire plein).
- Les définitions (`ItemData`) restent immuables pendant la partie ; le nombre d'exemplaires vit dans le composant (principe du plan DAT-04).
