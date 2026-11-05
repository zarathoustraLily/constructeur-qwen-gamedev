extends GdUnitTestSuite
## La souris des collisions : un clic choisit la forme sous lui ; tirer un sommet le déplace en un pas ; un déplacement
## qui croiserait deux côtés est refusé et annoncé ; un double-clic sur un côté ajoute un sommet ; Suppr retire le
## sommet choisi, puis la forme, jamais le contour ; Ctrl+clic crée une forme carrée ; inactif, le script laisse tout
## passer.

var _document: RoomDocument
var _view: RoomView
var _input: CollisionInput
var _refusals: Array[String] = []


func before_test() -> void:
	var settings: EditorSettingsDef = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	var catalog: AssetCatalogDef = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/pont.tres"))
	var transform: ViewTransform = ViewTransform.new()
	transform.setup(settings)
	_view = auto_free(RoomView.new())
	_view.size = Vector2(800, 600)
	add_child(_view)
	_view.setup(_document, catalog, transform)
	transform.frame(Vector2(24, 20), _view.size)
	_input = auto_free(CollisionInput.new())
	add_child(_input)
	_input.setup(_view, _document, settings)
	_input.active = true
	_refusals.clear()
	_input.refused.connect(func(reason: String) -> void: _refusals.append(reason))


func _screen(world: Vector2) -> Vector2:
	return _view.view_transform.world_to_screen(Vector3(world.x, 0, world.y))


func _left(pressed: bool, world: Vector2, ctrl: bool = false, double: bool = false) -> bool:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = _screen(world)
	event.ctrl_pressed = ctrl
	event.double_click = double
	return _input.handle(event)


func _move(world: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _screen(world)
	_input.handle(event)


func _delete() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = KEY_DELETE
	event.pressed = true
	_input.handle(event)


func _polygons() -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	polygons.assign(_document.room_value(&"collisions"))
	return polygons


# Choisit la forme 1 (le premier obstacle) en cliquant en son centre.
func _choose_first_obstacle() -> PackedVector2Array:
	var polygon: PackedVector2Array = _polygons()[1]
	var center: Vector2 = Vector2.ZERO
	for point: Vector2 in polygon:
		center += point / polygon.size()
	_left(true, center)
	_left(false, center)
	return polygon


func test_un_clic_choisit_la_forme_sous_lui() -> void:
	var polygon: PackedVector2Array = _choose_first_obstacle()
	var center: Vector2 = (polygon[0] + polygon[2]) / 2.0
	assert_int(_input.chosen).is_equal(CollisionTools.polygon_at(_polygons(), center))
	assert_int(_input.chosen).is_greater(0)


func test_tirer_un_sommet_le_deplace_en_un_pas() -> void:
	var polygon: PackedVector2Array = _choose_first_obstacle()
	var index: int = _input.chosen
	var corner: Vector2 = _polygons()[index][0]
	var target: Vector2 = corner + Vector2(-0.5, -0.5)
	_left(true, corner)
	_move(target)
	assert_vector(_input.shown_polygons()[index][0]).is_equal_approx(target, Vector2.ONE * 0.01)
	assert_vector(_polygons()[index][0]).is_equal(polygon[0])
	_left(false, target)
	assert_vector(_polygons()[index][0]).is_equal_approx(target, Vector2.ONE * 0.01)
	assert_bool(_document.undo()).is_true()
	assert_bool(_document.can_undo()).is_false()


func test_un_deplacement_qui_croise_est_refuse() -> void:
	_choose_first_obstacle()
	var index: int = _input.chosen
	var polygon: PackedVector2Array = _polygons()[index]
	# Le sommet 0 (en haut à gauche) amené à droite de la forme, à mi-hauteur : le côté qui le relie au sommet 3 (en bas
	# à gauche) croise alors le côté droit.
	var across: Vector2 = Vector2(polygon[1].x + (polygon[1].x - polygon[0].x), (polygon[1].y + polygon[2].y) / 2.0)
	_left(true, polygon[0])
	_move(across)
	_left(false, across)
	assert_array(_refusals).contains(["collision %d : des côtés se croisent" % index])
	assert_vector(_polygons()[index][0]).is_equal(polygon[0])


func test_un_double_clic_sur_un_cote_ajoute_un_sommet() -> void:
	_choose_first_obstacle()
	var index: int = _input.chosen
	var polygon: PackedVector2Array = _polygons()[index]
	var middle: Vector2 = (polygon[0] + polygon[1]) / 2.0
	_left(true, middle, false, true)
	assert_int(_polygons()[index].size()).is_equal(polygon.size() + 1)
	assert_int(_input.chosen_point).is_equal(1)


func test_suppr_retire_le_sommet_puis_la_forme_jamais_le_contour() -> void:
	_choose_first_obstacle()
	var index: int = _input.chosen
	var count: int = _polygons().size()
	var polygon: PackedVector2Array = _polygons()[index]
	_left(true, (polygon[0] + polygon[1]) / 2.0, false, true)
	_delete()
	assert_int(_polygons()[index].size()).is_equal(polygon.size())
	_delete()
	assert_int(_polygons().size()).is_equal(count - 1)
	_input.chosen = 0
	_input.chosen_point = -1
	_delete()
	assert_array(_refusals).contains(["Le contour de la salle ne se supprime pas"])
	assert_int(_polygons().size()).is_equal(count - 1)


func test_ctrl_clic_cree_une_forme_carree() -> void:
	var count: int = _polygons().size()
	_left(true, Vector2(5, 5), true)
	assert_int(_polygons().size()).is_equal(count + 1)
	assert_int(_input.chosen).is_equal(count)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(5, 5), _polygons()[count])).is_true()


func test_inactif_le_script_laisse_tout_passer() -> void:
	_input.active = false
	var count: int = _polygons().size()
	assert_bool(_left(true, Vector2(5, 5), true)).is_false()
	assert_int(_polygons().size()).is_equal(count)
