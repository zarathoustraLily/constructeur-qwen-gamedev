extends GdUnitTestSuite
## Le bouton gauche sur la vue : un clic sélectionne la chose la plus haute, Maj+clic l'ajoute ou la retire, un clic
## dans le vide vide la sélection, un rectangle sélectionne ce qu'il touche ; tirer l'intérieur du cadre déplace la
## sélection, une poignée d'angle l'agrandit, la poignée ronde la tourne, chaque fois en un seul pas, avec un aperçu
## pendant le glisser ; Page haut avance la sélection d'un rang.

var _document: RoomDocument
var _selection: SelectionModel
var _view: RoomView
var _input: SelectionInput
var _settings: EditorSettingsDef


func before_test() -> void:
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	var catalog: AssetCatalogDef = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/pont.tres"))
	_selection = SelectionModel.new()
	var transform: ViewTransform = ViewTransform.new()
	transform.setup(_settings)
	_view = auto_free(RoomView.new())
	_view.size = Vector2(800, 600)
	add_child(_view)
	_view.setup(_document, catalog, transform)
	transform.frame(Vector2(24, 20), _view.size)
	var actions: EditorActions = EditorActions.new()
	actions.setup(_document, catalog, _settings)
	_input = auto_free(SelectionInput.new())
	add_child(_input)
	_input.setup(_view, _document, _selection, actions, _settings)


func _left(pressed: bool, point: Vector2, shift: bool = false) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.shift_pressed = shift
	_input.handle(event)


func _move(point: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = point
	_input.handle(event)


func _click(point: Vector2, shift: bool = false) -> void:
	_left(true, point, shift)
	_left(false, point, shift)


# Le centre d'une chose qu'un clic peut prendre : la plus haute, sous son propre centre.
func _clickable() -> int:
	var shown: PackedInt32Array = _view.visible_ids()
	for index: int in range(shown.size() - 1, -1, -1):
		var center: Vector2 = _view.screen_rect_of(shown[index]).get_center()
		if _view.thing_at(center) == shown[index]:
			return shown[index]
	return 0


func _steps_to_undo() -> int:
	var steps: int = 0
	while _document.undo():
		steps += 1
	return steps


func test_un_clic_selectionne_la_chose_la_plus_haute() -> void:
	var thing_id: int = _clickable()
	_click(_view.screen_rect_of(thing_id).get_center())
	assert_array(_selection.ids()).is_equal([thing_id])
	assert_bool(_input.gizmo.box.has_area()).is_true()


func test_maj_clic_ajoute_puis_retire() -> void:
	var thing_id: int = _clickable()
	var center: Vector2 = _view.screen_rect_of(thing_id).get_center()
	_click(center, true)
	assert_array(_selection.ids()).is_equal([thing_id])
	_click(center, true)
	assert_bool(_selection.is_empty()).is_true()


func test_un_clic_dans_le_vide_vide_la_selection() -> void:
	_selection.replace([_clickable()])
	_click(Vector2(2, 2))
	assert_bool(_selection.is_empty()).is_true()


func test_un_rectangle_selectionne_ce_qu_il_touche() -> void:
	var band: Rect2 = Rect2(Vector2(0, 0), _view.size)
	_left(true, band.position)
	_move(band.end)
	assert_bool(_input.band.has_area()).is_true()
	_left(false, band.end)
	assert_array(_selection.ids()).contains_exactly_in_any_order(_view.things_in(band))
	assert_bool(_input.band.has_area()).is_false()


func test_tirer_l_interieur_deplace_en_un_pas_avec_un_apercu() -> void:
	var thing_id: int = _clickable()
	_selection.replace([thing_id])
	var start: Vector2 = _view.screen_rect_of(thing_id).get_center()
	var before_position: Vector3 = _document.value(thing_id, &"position")
	var before_rect: Rect2 = _view.screen_rect_of(thing_id)
	var shift_px: Vector2 = Vector2(_view.view_transform.pixels_per_meter() * 2.0, 0)
	_left(true, start)
	_move(start + shift_px)
	assert_vector(_view.screen_rect_of(thing_id).position).is_equal_approx(before_rect.position + shift_px,
			Vector2.ONE * 0.01)
	assert_vector(_document.value(thing_id, &"position")).is_equal(before_position)
	_left(false, start + shift_px)
	assert_vector(_document.value(thing_id, &"position")).is_equal_approx(before_position + Vector3(2, 0, 0),
			Vector3.ONE * 0.001)
	assert_int(_steps_to_undo()).is_equal(1)


func test_une_poignee_d_angle_agrandit() -> void:
	var thing_id: int = _clickable()
	_selection.replace([thing_id])
	var corner: Vector2 = _input.gizmo.point_of(TransformGizmo.Handle.BOTTOM_RIGHT)
	var center: Vector2 = _input.gizmo.box.get_center()
	_left(true, corner)
	_left(false, center + (corner - center) * 2.0)
	assert_float(_document.value(thing_id, &"scale")).is_greater(1.5)
	assert_int(_steps_to_undo()).is_equal(1)


func test_la_poignee_ronde_tourne() -> void:
	var thing_id: int = _clickable()
	_selection.replace([thing_id])
	var handle: Vector2 = _input.gizmo.point_of(TransformGizmo.Handle.ROTATE)
	var center: Vector2 = _input.gizmo.box.get_center()
	var before_angle: float = _document.value(thing_id, &"rotation")
	_left(true, handle)
	_left(false, center + Vector2((handle - center).length(), 0))
	assert_float(fposmod(float(_document.value(thing_id, &"rotation")) - before_angle, RoomData.FULL_TURN)) \
			.is_equal_approx(90.0, 0.01)


func test_page_haut_avance_d_un_rang() -> void:
	var thing_id: int = _clickable()
	_selection.replace([thing_id])
	var before_sort: int = _document.value(thing_id, &"sort")
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_PAGEUP
	key.pressed = true
	assert_bool(_input.handle(key)).is_true()
	assert_int(_document.value(thing_id, &"sort")).is_equal(before_sort + 1)
