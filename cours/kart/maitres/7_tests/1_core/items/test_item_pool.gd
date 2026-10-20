extends GdUnitTestSuite
## Règles de la réserve d'objets : le tirage suit les poids ; un poids nul n'est jamais tiré ; tous les poids
## nuls, rien ; sans un poids par objet, le tirage est uniforme ; une réserve vide ne donne rien ; une même
## graine, les mêmes tirages.


func _item(item_name: String) -> ItemType:
	var item := ItemType.new()
	item.display_name = item_name
	return item


func _pool(weights: Array[float]) -> ItemPool:
	var pool := ItemPool.new()
	pool.items = [_item("a"), _item("b"), _item("c")]
	pool.weights = weights
	return pool


## Nombre de tirages de chaque objet, sur `draws` tirages.
func _counts(pool: ItemPool, draws: int, random_seed: int = 1) -> Dictionary[String, int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var counts: Dictionary[String, int] = {"a": 0, "b": 0, "c": 0}
	for _draw: int in draws:
		counts[pool.draw(rng).display_name] += 1
	return counts


func test_le_tirage_suit_les_poids() -> void:
	var counts := _counts(_pool([1.0, 3.0, 0.0]), 4000)
	assert_int(counts["a"]).is_between(850, 1150)
	assert_int(counts["b"]).is_between(2850, 3150)


func test_un_poids_nul_n_est_jamais_tire() -> void:
	assert_int(_counts(_pool([1.0, 3.0, 0.0]), 4000)["c"]).is_equal(0)


func test_sans_un_poids_par_objet_le_tirage_est_uniforme() -> void:
	var counts := _counts(_pool([]), 3000)
	for item_name: String in ["a", "b", "c"]:
		assert_int(counts[item_name]).is_between(850, 1150)


func test_tous_les_poids_nuls_rien() -> void:
	assert_object(_pool([0.0, 0.0, 0.0]).draw(RandomNumberGenerator.new())).is_null()


func test_une_reserve_vide_ne_donne_rien() -> void:
	assert_object(ItemPool.new().draw(RandomNumberGenerator.new())).is_null()


func test_une_meme_graine_les_memes_tirages() -> void:
	assert_dict(_counts(_pool([1.0, 1.0, 1.0]), 50, 7)).is_equal(_counts(_pool([1.0, 1.0, 1.0]), 50, 7))
