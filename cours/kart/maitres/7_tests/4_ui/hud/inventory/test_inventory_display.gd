extends GdUnitTestSuite
## Règles de l'affichage de l'inventaire : vide, il se cache ; la grande case montre le prochain objet à
## partir, la petite le suivant.

const DISPLAY := preload("res://4_ui/hud/inventory/inventory_display.tscn")

var _display: InventoryDisplay


func before_test() -> void:
	_display = auto_free(DISPLAY.instantiate())
	add_child(_display)


func _item(texture: Texture2D) -> ItemType:
	var item := ItemType.new()
	item.icon = texture
	return item


func test_vide_il_se_cache() -> void:
	_display.show_items([])
	assert_bool(_display.visible).is_false()


func test_la_grande_case_montre_le_prochain_objet() -> void:
	var first := PlaceholderTexture2D.new()
	var second := PlaceholderTexture2D.new()
	_display.show_items([_item(first), _item(second)])
	assert_bool(_display.visible).is_true()
	assert_object((_display.get_node("Slots/NextSlot/Icon") as TextureRect).texture).is_same(first)
	assert_object((_display.get_node("Slots/LaterSlot/Icon") as TextureRect).texture).is_same(second)
