extends GdUnitTestSuite
## La vue de dessus : salle cadrée, toutes les choses sont à dessiner, dans l'ordre de dessin ; la vue déplacée loin
## de la salle n'en dessine aucune ; une chose tournée d'un quart de tour échange largeur et profondeur à l'écran ; la
## vue redessine quand le document change.

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
