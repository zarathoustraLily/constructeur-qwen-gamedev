extends GdUnitTestSuite
## Les apparitions : tirer le départ du héros le déplace en un pas, avec un aperçu ; Ctrl+clic ajoute un point « tous » ;
## R fait tourner le rôle du point choisi ; Suppr retire le point choisi ; le panneau de la rencontre coche les ennemis de
## la salle, et en décocher un change la rencontre en un pas ; il dit ce qui manque.

var _document: RoomDocument
var _view: RoomView
var _input: SpawnInput


func before_test() -> void:
	var settings: EditorSettingsDef = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	var catalog: AssetCatalogDef = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/soute.tres"))
	var transform: ViewTransform = ViewTransform.new()
	transform.setup(settings)
	_view = auto_free(RoomView.new())
	_view.size = Vector2(800, 600)
	add_child(_view)
	_view.setup(_document, catalog, transform)
	transform.frame(Vector2(36, 28), _view.size)
	_input = auto_free(SpawnInput.new())
	add_child(_input)
	_input.setup(_view, _document, settings)
	_input.active = true


func _left(pressed: bool, world: Vector3, ctrl: bool = false) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = _view.view_transform.world_to_screen(world)
	event.ctrl_pressed = ctrl
	_input.handle(event)


func _move(world: Vector3) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _view.view_transform.world_to_screen(world)
	_input.handle(event)


func _key(keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	_input.handle(event)


func test_tirer_le_depart_du_heros_le_deplace_en_un_pas() -> void:
	var start: Vector3 = _document.room_value(&"hero_start")
	var target: Vector3 = start + Vector3(3, 0, 4)
	_left(true, start)
	assert_int(_input.chosen).is_equal(SpawnInput.HERO)
	_move(target)
	assert_vector(_input.shown_hero()).is_equal_approx(target, Vector3.ONE * 0.01)
	assert_vector(_document.room_value(&"hero_start")).is_equal(start)
	_left(false, target)
	assert_vector(_document.room_value(&"hero_start")).is_equal_approx(target, Vector3.ONE * 0.01)
	assert_bool(_document.undo()).is_true()
	assert_bool(_document.can_undo()).is_false()


func test_ctrl_clic_ajoute_un_point_tous() -> void:
	var count: int = (_document.room_value(&"spawn_positions") as PackedVector3Array).size()
	_left(true, Vector3(10, 0, 10), true)
	var roles: PackedStringArray = _document.room_value(&"spawn_roles")
	assert_int(roles.size()).is_equal(count + 1)
	assert_str(roles[count]).is_equal("tous")
	assert_int(_input.chosen).is_equal(count)


func test_r_fait_tourner_le_role_et_suppr_retire_le_point() -> void:
	var count: int = (_document.room_value(&"spawn_positions") as PackedVector3Array).size()
	_left(true, Vector3(10, 0, 10), true)
	_key(KEY_R)
	assert_str((_document.room_value(&"spawn_roles") as PackedStringArray)[count]).is_equal("melee")
	_key(KEY_DELETE)
	assert_int((_document.room_value(&"spawn_positions") as PackedVector3Array).size()).is_equal(count)
	assert_int(_input.chosen).is_equal(-1)


func test_le_panneau_de_la_rencontre_coche_et_decoche() -> void:
	var enemies: Array[EnemyDef] = []
	enemies.assign(DefinitionFolder.new().load_all("res://5_data/ennemis", EnemyDef))
	var panel: EncounterPanel = auto_free(EncounterPanel.new())
	add_child(panel)
	panel.setup(_document, enemies)
	assert_bool(panel.check_of(&"tireur").button_pressed).is_true()
	assert_bool(panel.check_of(&"racine").button_pressed).is_false()
	panel.check_of(&"tireur").button_pressed = false
	assert_bool((_document.room_value(&"encounter_pool") as PackedStringArray).has("tireur")).is_false()
	assert_bool(_document.undo()).is_true()
	assert_bool(panel.check_of(&"tireur").button_pressed).is_true()
	assert_str(panel.warnings()).is_empty()
	_document.set_room_fields({&"spawn_roles": PackedStringArray(["melee", "melee", "melee", "melee", "melee",
			"melee", "melee", "melee"])})
	assert_str(panel.warnings()).contains("aucun point d'apparition pour tireur")
