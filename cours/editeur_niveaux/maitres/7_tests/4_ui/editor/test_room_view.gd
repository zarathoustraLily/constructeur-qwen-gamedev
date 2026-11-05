extends GdUnitTestSuite
## La vue de dessus : salle cadrée, toutes les choses sont à dessiner, dans l'ordre de dessin ; la vue déplacée loin
## de la salle n'en dessine aucune ; une chose tournée d'un quart de tour échange largeur et profondeur à l'écran ; la
## vue redessine quand le document change.
#@ 7+
## Un point désigne la chose la plus haute sous lui, jamais une dalle du sol (calque verrouillé) ; un rectangle prend ce
## qu'il touche ; l'aperçu d'un geste montre la chose déplacée sans toucher au document.
#@ all

var _document: RoomDocument
var _catalog: AssetCatalogDef
var _transform: ViewTransform
var _view: RoomView


func before_test() -> void:
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/pont.tres"))
	_catalog = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_transform = ViewTransform.new()
	_transform.setup(ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef)
	_view = auto_free(RoomView.new())
	_view.size = Vector2(800, 600)
	add_child(_view)
	_view.setup(_document, _catalog, _transform)
	_transform.frame(Vector2(24, 20), _view.size)


func test_salle_cadree_tout_est_a_dessiner_dans_l_ordre() -> void:
	assert_array(Array(_view.visible_ids())).is_equal(Array(DrawOrder.sorted(_document, _catalog.layers)))


func test_vue_deplacee_loin_rien_n_est_dessine() -> void:
	_transform.pan(Vector2(100000, 0))
	assert_array(Array(_view.visible_ids())).is_empty()


func test_un_quart_de_tour_echange_largeur_et_profondeur() -> void:
	var wall: int = _document.add_thing({&"asset": "mur_droit", &"layer": "obstacles", &"position": Vector3(10, 0, 10)})
	var flat: Rect2 = _view.screen_rect_of(wall)
	_document.set_value(wall, &"rotation", 90.0)
	var turned: Rect2 = _view.screen_rect_of(wall)
	assert_vector(turned.size).is_equal_approx(Vector2(flat.size.y, flat.size.x), Vector2.ONE * 0.01)


func test_la_vue_redessine_quand_le_document_change() -> void:
	var connected: bool = _document.changed.is_connected(_view.queue_redraw)
	assert_bool(connected).is_true()
#@ 7+


func test_un_point_designe_la_chose_la_plus_haute_hors_du_sol() -> void:
	var shown: PackedInt32Array = _view.visible_ids()
	var top: int = shown[shown.size() - 1]
	var center: Vector2 = _view.screen_rect_of(top).get_center()
	assert_int(_view.thing_at(center)).is_equal(top)
	var floor_id: int = shown[0]
	assert_str(_document.value(floor_id, &"layer")).is_equal("sol")
	var under: int = _view.thing_at(_view.screen_rect_of(floor_id).get_center())
	assert_bool(under == 0 or _document.value(under, &"layer") != "sol").is_true()


func test_un_rectangle_prend_ce_qu_il_touche() -> void:
	var found: Array[int] = _view.things_in(Rect2(Vector2.ZERO, _view.size))
	assert_int(found.size()).is_greater(0)
	for thing_id: int in found:
		assert_str(_document.value(thing_id, &"layer")).is_not_equal("sol")


func test_l_apercu_deplace_sans_toucher_au_document() -> void:
	var thing_id: int = _document.ids()[_document.ids().size() - 1]
	var before_rect: Rect2 = _view.screen_rect_of(thing_id)
	var before_position: Vector3 = _document.value(thing_id, &"position")
	_view.set_preview({&"ids": [thing_id], &"move": Vector3(1, 0, 0), &"angle": 0.0, &"factor": 1.0,
			&"pivot": before_position})
	var shift_px: float = _transform.pixels_per_meter()
	assert_float(_view.screen_rect_of(thing_id).position.x).is_equal_approx(before_rect.position.x + shift_px, 0.01)
	assert_vector(_document.value(thing_id, &"position")).is_equal(before_position)
	_view.clear_preview()
	assert_vector(_view.screen_rect_of(thing_id).position).is_equal_approx(before_rect.position, Vector2.ONE * 0.01)
#@ all
