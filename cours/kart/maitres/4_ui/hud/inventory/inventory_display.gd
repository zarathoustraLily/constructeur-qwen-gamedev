class_name InventoryDisplay extends Control
## Affichage de l'inventaire, en haut à droite : la grande case montre l'objet qui partira au prochain usage,
## la petite le suivant ; vide, l'affichage se cache. Il ne connaît pas l'inventaire : la scène lui donne les
## objets à chaque changement (show_items).

@onready var _next_icon: TextureRect = $Slots/NextSlot/Icon
@onready var _later_icon: TextureRect = $Slots/LaterSlot/Icon


func _ready() -> void:
	show_items([])


## Montre `items`, du prochain à partir au suivant.
func show_items(items: Array[ItemType]) -> void:
	visible = not items.is_empty()
	_next_icon.texture = items[0].icon if items.size() > 0 else null
	_later_icon.texture = items[1].icon if items.size() > 1 else null
