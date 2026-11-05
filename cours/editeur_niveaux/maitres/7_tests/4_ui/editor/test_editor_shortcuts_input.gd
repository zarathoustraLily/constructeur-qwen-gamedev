extends GdUnitTestSuite
## Les raccourcis : Ctrl+Z annule et Ctrl+Y refait ; Suppr supprime la sélection ; Ctrl+D la duplique et sélectionne les
## doubles ; une flèche la déplace d'un pas de grille, quatre avec Maj ; sans sélection, Suppr ne fait rien.

var _document: RoomDocument
var _selection: SelectionModel
var _settings: EditorSettingsDef
var _shortcuts: EditorShortcutsInput


func before_test() -> void:
	var catalog: AssetCatalogDef = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/pont.tres"))
	_selection = SelectionModel.new()
	var actions: EditorActions = EditorActions.new()
	actions.setup(_document, catalog, _settings)
	_shortcuts = auto_free(EditorShortcutsInput.new())
	_shortcuts.setup(_document, _selection, actions, _settings)


func _key(keycode: Key, ctrl: bool = false, shift: bool = false) -> bool:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.ctrl_pressed = ctrl
	event.shift_pressed = shift
	return _shortcuts.handle(event)


func _obstacle() -> int:
	for thing_id: int in _document.ids():
		if _document.value(thing_id, &"layer") == "obstacles":
			return thing_id
	return 0


func _obstacle_without_children() -> int:
	var parents: PackedInt32Array = _document.column(&"parent")
	for thing_id: int in _document.ids():
		if _document.value(thing_id, &"layer") == "obstacles" and not parents.has(thing_id):
			return thing_id
	return 0


func test_ctrl_z_annule_et_ctrl_y_refait() -> void:
	var thing_id: int = _obstacle()
	_document.set_value(thing_id, &"height", 2.0)
	assert_bool(_key(KEY_Z, true)).is_true()
	assert_float(_document.value(thing_id, &"height")).is_equal(0.0)
	assert_bool(_key(KEY_Y, true)).is_true()
	assert_float(_document.value(thing_id, &"height")).is_equal(2.0)


func test_suppr_supprime_la_selection() -> void:
	# Un obstacle sans rien d'attaché : le document refuse, à raison, de supprimer un parent.
	var thing_id: int = _obstacle_without_children()
	_selection.replace([thing_id])
	assert_bool(_key(KEY_DELETE)).is_true()
	assert_int(_document.ids().find(thing_id)).is_equal(-1)


func test_ctrl_d_duplique_et_selectionne_les_doubles() -> void:
	var thing_id: int = _obstacle()
	_selection.replace([thing_id])
	var count: int = _document.ids().size()
	assert_bool(_key(KEY_D, true)).is_true()
	assert_int(_document.ids().size()).is_equal(count + 1)
	assert_bool(_selection.contains(thing_id)).is_false()
	assert_int(_selection.ids().size()).is_equal(1)


func test_une_fleche_deplace_d_un_pas_quatre_avec_maj() -> void:
	var thing_id: int = _obstacle()
	_selection.replace([thing_id])
	var start: Vector3 = _document.value(thing_id, &"position")
	_key(KEY_RIGHT)
	assert_float(Vector3(_document.value(thing_id, &"position")).x).is_equal_approx(start.x + _settings.snap_m, 0.001)
	_key(KEY_UP, false, true)
	assert_float(Vector3(_document.value(thing_id, &"position")).z).is_equal_approx(start.z - 4.0 * _settings.snap_m,
			0.001)


#@ 9+
func test_ctrl_s_demande_l_enregistrement() -> void:
	var asked: Array[bool] = []
	_shortcuts.save_requested.connect(func() -> void: asked.append(true))
	assert_bool(_key(KEY_S, true)).is_true()
	assert_array(asked).is_equal([true])


#@ all
func test_sans_selection_suppr_ne_fait_rien() -> void:
	var count: int = _document.ids().size()
	assert_bool(_key(KEY_DELETE)).is_false()
	assert_int(_document.ids().size()).is_equal(count)
