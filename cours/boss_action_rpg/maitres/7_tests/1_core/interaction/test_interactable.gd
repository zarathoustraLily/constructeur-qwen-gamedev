extends GdUnitTestSuite
## Règles de ce qu'on actionne à la main : il est sur la couche des interactions et ne regarde rien ; l'actionner le dit ;
## inactif, il ne dit rien.


func _item() -> Interactable:
	var item: Interactable = auto_free(Interactable.new())
	add_child(item)
	return item


func test_il_est_sur_la_couche_des_interactions_et_ne_regarde_rien() -> void:
	var item: Interactable = _item()
	assert_bool(Layers.has(item.collision_layer, Layers.INTERACTIONS)).is_true()
	assert_int(item.collision_mask).is_equal(0)
	assert_bool(item.monitoring).is_false()


func test_l_actionner_le_dit() -> void:
	var item: Interactable = _item()
	var count: Array[int] = [0]
	item.used.connect(func() -> void: count[0] += 1)
	item.use()
	assert_int(count[0]).is_equal(1)


func test_inactif_il_ne_dit_rien() -> void:
	var item: Interactable = _item()
	var count: Array[int] = [0]
	item.used.connect(func() -> void: count[0] += 1)
	item.enabled = false
	item.use()
	assert_int(count[0]).is_equal(0)
