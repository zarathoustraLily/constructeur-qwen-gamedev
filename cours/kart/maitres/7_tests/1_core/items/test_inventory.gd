extends GdUnitTestSuite
## Règles de l'inventaire : il porte au plus `capacity` objets ; ils partent dans l'ordre où ils sont arrivés ;
## vide, il ne rend rien ; chaque changement est signalé.

var _inventory: Inventory
var _changes: Array[int] = [0]


func before_test() -> void:
	_inventory = Inventory.new(2)
	_changes[0] = 0
	_inventory.changed.connect(func() -> void: _changes[0] += 1)


func _item(item_name: String) -> ItemType:
	var item := ItemType.new()
	item.display_name = item_name
	return item


func test_il_porte_au_plus_sa_capacite() -> void:
	assert_bool(_inventory.add(_item("a"))).is_true()
	assert_bool(_inventory.add(_item("b"))).is_true()
	assert_bool(_inventory.is_full()).is_true()
	assert_bool(_inventory.add(_item("c"))).is_false()
	assert_int(_inventory.items.size()).is_equal(2)


func test_les_objets_partent_dans_leur_ordre_d_arrivee() -> void:
	_inventory.add(_item("a"))
	_inventory.add(_item("b"))
	assert_str(_inventory.take().display_name).is_equal("a")
	assert_str(_inventory.take().display_name).is_equal("b")


func test_vide_il_ne_rend_rien() -> void:
	assert_object(_inventory.take()).is_null()


func test_chaque_changement_est_signale() -> void:
	_inventory.add(_item("a"))
	_inventory.take()
	_inventory.take()
	assert_int(_changes[0]).is_equal(2)
