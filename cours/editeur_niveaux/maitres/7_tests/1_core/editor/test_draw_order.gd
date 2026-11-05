extends GdUnitTestSuite
## L'ordre de dessin : le sol d'abord, l'avant-plan en dernier ; dans un calque, par rang, puis par identifiant ; une
## chose avancée d'un rang passe après les autres de son calque.

var _document: RoomDocument
var _layers: PackedStringArray


func before_test() -> void:
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/pont.tres"))
	_layers = (ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef).layers


func _layer_ranks(order: PackedInt32Array) -> Array[int]:
	var ranks: Array[int] = []
	for thing_id: int in order:
		ranks.append(_layers.find(String(_document.value(thing_id, &"layer"))))
	return ranks


func test_les_calques_se_suivent_du_sol_a_l_avant_plan() -> void:
	var ranks: Array[int] = _layer_ranks(DrawOrder.sorted(_document, _layers))
	var sorted_ranks: Array[int] = ranks.duplicate()
	sorted_ranks.sort()
	assert_array(ranks).is_equal(sorted_ranks)
	assert_int(ranks.size()).is_equal(_document.ids().size())


func test_une_chose_avancee_passe_apres_son_calque() -> void:
	var first_obstacle: int = 0
	for thing_id: int in DrawOrder.sorted(_document, _layers):
		if _document.value(thing_id, &"layer") == "obstacles":
			first_obstacle = thing_id
			break
	_document.set_value(first_obstacle, &"sort", 5)
	var order: PackedInt32Array = DrawOrder.sorted(_document, _layers)
	var last_obstacle: int = 0
	for thing_id: int in order:
		if _document.value(thing_id, &"layer") == "obstacles":
			last_obstacle = thing_id
	assert_int(last_obstacle).is_equal(first_obstacle)


func test_a_rang_egal_l_identifiant_decide() -> void:
	var order: PackedInt32Array = DrawOrder.sorted(_document, _layers)
	var floors: Array[int] = []
	for thing_id: int in order:
		if _document.value(thing_id, &"layer") == "sol":
			floors.append(thing_id)
	var expected: Array[int] = floors.duplicate()
	expected.sort()
	assert_array(floors).is_equal(expected)
