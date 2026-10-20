extends GdUnitTestSuite
## Règles du tirage d'objets : on reçoit une copie d'un objet de la réserve, jamais l'original.

const RESERVE_DU_JEU := "res://5_data/items/item_pool.tres"


func _reserve(noms: Array[String], poids: Array[float] = []) -> ItemPool:
	var reserve := ItemPool.new()
	for nom in noms:
		var objet := ItemType.new()
		objet.name = nom
		reserve.items.append(objet)
	reserve.weights = poids
	return reserve


func test_l_objet_tire_est_une_copie() -> void:
	var reserve := _reserve(["bomb"])
	var objet := reserve.get_item()
	assert_object(objet).is_not_same(reserve.items[0])
	assert_str(objet.name).is_equal("bomb")


func test_sans_poids_l_objet_tire_vient_de_la_reserve() -> void:
	var reserve := _reserve(["bomb", "shell", "banana"])
	for i in 20:
		assert_array(["bomb", "shell", "banana"]).contains([reserve.get_item().name])


## La pondération n'est pas encore écrite (TODO de item_pool.gd) : ce test changera avec elle.
func test_avec_des_poids_le_tirage_donne_le_premier_objet() -> void:
	var reserve := _reserve(["bomb", "shell"], [1.0, 3.0])
	for i in 5:
		assert_str(reserve.get_item().name).is_equal("bomb")


func test_la_reserve_du_jeu_donne_des_bombes() -> void:
	var reserve: ItemPool = load(RESERVE_DU_JEU)
	var objet := reserve.get_item()
	assert_str(objet.name).is_equal("bomb")
	assert_object(objet.scene).is_not_null()
