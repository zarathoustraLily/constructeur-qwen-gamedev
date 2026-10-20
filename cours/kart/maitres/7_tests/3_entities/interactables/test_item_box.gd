extends GdUnitTestSuite
## Règles de la boîte à objets : un corps qui la traverse la fait signaler une fois ; prise, elle se cache et
## ne se reprend pas ; elle revient après son délai.

const BOX := preload("res://3_entities/interactables/item_box/item_box.tscn")

var _box: ItemBox
var _collected: Array[Node3D] = []


func before_test() -> void:
	_box = auto_free(BOX.instantiate())
	add_child(_box)
	_collected.clear()
	_box.collected.connect(func(body: Node3D) -> void: _collected.append(body))


func test_un_corps_qui_la_traverse_la_fait_signaler() -> void:
	var body: Node3D = auto_free(Node3D.new())
	_box.on_body_entered(body)
	assert_array(_collected).is_equal([body])


func test_prise_elle_se_cache_et_ne_se_reprend_pas() -> void:
	var body: Node3D = auto_free(Node3D.new())
	_box.on_body_entered(body)
	_box.on_body_entered(body)
	await get_tree().process_frame
	assert_int(_collected.size()).is_equal(1)
	assert_bool(_box.active).is_false()
	assert_bool((_box.get_node("VisualParent/Visual") as Node3D).visible).is_false()


func test_elle_revient_apres_son_delai() -> void:
	_box.on_body_entered(auto_free(Node3D.new()))
	for _frame: int in int((_box.respawn_time + 0.1) * 60.0):
		await get_tree().physics_frame
	await get_tree().process_frame
	assert_bool(_box.active).is_true()
	assert_bool((_box.get_node("VisualParent/Visual") as Node3D).visible).is_true()


func test_un_kart_qui_passe_dedans_est_detecte() -> void:
	var kart: Kart = auto_free(preload("res://3_entities/kart/kart.tscn").instantiate())
	kart.input = null
	kart.position = _box.position + Vector3(0.0, 4.0, 0.0)
	add_child(kart)
	for _frame: int in 30:
		await get_tree().physics_frame
	assert_array(_collected).is_equal([kart])
