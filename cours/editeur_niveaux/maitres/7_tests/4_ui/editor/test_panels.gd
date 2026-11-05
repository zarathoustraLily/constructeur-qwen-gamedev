extends GdUnitTestSuite
## Les panneaux : la palette filtre par la recherche et choisit un asset ; la hiérarchie range les choses sous leur
## calque, reflète la sélection et sélectionne au clic, même le sol ; l'inspecteur montre la chose sélectionnée, la
## modifie en un pas, affiche ses champs inconnus « non édités », ne montre que les champs communs pour plusieurs
## choses, et le dit quand rien n'est sélectionné.

var _document: RoomDocument
var _selection: SelectionModel
var _actions: EditorActions
var _catalog: AssetCatalogDef


func before_test() -> void:
	_catalog = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/hangar.tres"))
	_selection = SelectionModel.new()
	_actions = EditorActions.new()
	_actions.setup(_document, _catalog, ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef)


func _palette() -> PalettePanel:
	var palette: PalettePanel = auto_free(PalettePanel.new())
	add_child(palette)
	palette.setup(_catalog)
	return palette


func _inspector() -> InspectorPanel:
	var inspector: InspectorPanel = auto_free(InspectorPanel.new())
	add_child(inspector)
	inspector.setup(_document, _selection, _actions, _catalog)
	return inspector


func _obstacle() -> int:
	for thing_id: int in _document.ids():
		if _document.value(thing_id, &"layer") == "obstacles":
			return thing_id
	return 0


func test_la_palette_filtre_et_choisit() -> void:
	var palette: PalettePanel = _palette()
	assert_int(palette.shown().size()).is_equal(_catalog.assets.size())
	palette.filter("caisse")
	assert_array(palette.shown()).is_equal([&"caisse_cargo"])
	var chosen: Array[StringName] = []
	palette.asset_chosen.connect(func(asset_id: StringName) -> void: chosen.append(asset_id))
	palette.choose(0)
	assert_array(chosen).is_equal([&"caisse_cargo"])


func test_la_hierarchie_range_et_reflete_la_selection() -> void:
	var tree: HierarchyPanel = auto_free(HierarchyPanel.new())
	add_child(tree)
	tree.setup(_document, _selection, _catalog)
	var floor_id: int = DrawOrder.sorted(_document, _catalog.layers)[0]
	assert_str(tree.item_of(floor_id).get_parent().get_text(0)).is_equal("sol")
	_selection.replace([floor_id])
	assert_bool(tree.item_of(floor_id).is_selected(0)).is_true()
	_selection.clear()
	tree.item_of(floor_id).select(0)
	assert_array(_selection.ids()).is_equal([floor_id])


func test_l_inspecteur_montre_et_modifie_en_un_pas() -> void:
	var inspector: InspectorPanel = _inspector()
	var thing_id: int = _obstacle()
	_selection.replace([thing_id])
	assert_str(inspector.title()).is_equal("%s (%d)" % [_document.value(thing_id, &"name"), thing_id])
	assert_float((inspector.control(&"scale") as SpinBox).value).is_equal_approx(_document.value(thing_id, &"scale"),
			0.001)
	assert_bool(inspector.edit(&"scale", 2.5)).is_true()
	assert_float(_document.value(thing_id, &"scale")).is_equal_approx(2.5, 0.001)
	assert_bool(inspector.edit(&"x", 7.0)).is_true()
	assert_float(Vector3(_document.value(thing_id, &"position")).x).is_equal_approx(7.0, 0.001)
	assert_bool(_document.undo()).is_true()
	assert_bool(_document.undo()).is_true()
	assert_bool(_document.can_undo()).is_false()


func test_l_inspecteur_affiche_les_champs_inconnus_non_edites() -> void:
	var inspector: InspectorPanel = _inspector()
	var room: RoomData = _document.snapshot()
	var thing_id: int = room.thing_extras.keys()[0]
	_selection.replace([thing_id])
	assert_str(inspector.extras_text()).is_equal("Non édité : " + room.thing_extras[thing_id])


func test_plusieurs_choses_ne_montrent_que_les_champs_communs() -> void:
	var inspector: InspectorPanel = _inspector()
	_selection.replace([_document.ids()[0], _document.ids()[1]])
	assert_str(inspector.title()).is_equal("2 choses sélectionnées")
	assert_bool(inspector.control(&"layer").get_parent().visible).is_true()
	assert_bool(inspector.control(&"x").get_parent().visible).is_false()


func test_rien_de_selectionne_l_inspecteur_le_dit() -> void:
	var inspector: InspectorPanel = _inspector()
	assert_str(inspector.title()).is_equal(InspectorPanel.NOTHING)
	assert_bool(inspector.edit(&"scale", 2.0)).is_false()
