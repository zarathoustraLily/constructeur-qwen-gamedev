extends GdUnitTestSuite
## Règles de la navigation au focus : chaque contrôle connaît ses voisins du dessus et du dessous ; avec la
## boucle, le dernier mène au premier ; sans, les bords n'ont pas de voisin ; le premier contrôle utilisable
## n'est ni caché, ni désactivé, ni fermé au focus.

var _box: VBoxContainer
var _items: Array[Control] = []


func before_test() -> void:
	_box = auto_free(VBoxContainer.new())
	add_child(_box)
	_items.clear()
	for i: int in 3:
		var button: Button = Button.new()
		button.text = "Bouton %d" % i
		_box.add_child(button)
		_items.append(button)


func test_avec_la_boucle_le_dernier_mene_au_premier() -> void:
	MenuFocus.chain(_items, true)
	assert_that(_items[2].get_node(_items[2].focus_neighbor_bottom)).is_same(_items[0])
	assert_that(_items[0].get_node(_items[0].focus_neighbor_top)).is_same(_items[2])
	assert_that(_items[1].get_node(_items[1].focus_neighbor_bottom)).is_same(_items[2])
	assert_that(_items[1].get_node(_items[1].focus_next)).is_same(_items[2])
	assert_that(_items[1].get_node(_items[1].focus_previous)).is_same(_items[0])


func test_sans_la_boucle_les_bords_n_ont_pas_de_voisin() -> void:
	MenuFocus.chain(_items, false)
	assert_bool(_items[2].focus_neighbor_bottom.is_empty()).is_true()
	assert_bool(_items[0].focus_neighbor_top.is_empty()).is_true()
	assert_that(_items[0].get_node(_items[0].focus_neighbor_bottom)).is_same(_items[1])


func test_index_du_voisin() -> void:
	assert_int(MenuFocus.neighbor_index(3, 0, -1, true)).is_equal(2)
	assert_int(MenuFocus.neighbor_index(3, 2, 1, true)).is_equal(0)
	assert_int(MenuFocus.neighbor_index(3, 1, 1, false)).is_equal(2)
	assert_int(MenuFocus.neighbor_index(3, 2, 1, false)).is_equal(-1)
	assert_int(MenuFocus.neighbor_index(3, 0, -1, false)).is_equal(-1)


func test_le_premier_utilisable_saute_le_cache_et_le_desactive() -> void:
	_items[0].hide()
	(_items[1] as Button).disabled = true
	assert_that(MenuFocus.first_focusable(_items)).is_same(_items[2])


func test_un_controle_ferme_au_focus_n_est_pas_utilisable() -> void:
	_items[0].focus_mode = Control.FOCUS_NONE
	assert_bool(MenuFocus.can_focus(_items[0])).is_false()
	assert_bool(MenuFocus.can_focus(_items[1])).is_true()


func test_sans_controle_utilisable_rien() -> void:
	for item: Control in _items:
		item.hide()
	assert_that(MenuFocus.first_focusable(_items)).is_null()
