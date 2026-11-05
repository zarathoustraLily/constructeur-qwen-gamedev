extends GdUnitTestSuite
## Les effets placés : sans effet choisi, Ctrl+clic est refusé et le dit ; avec un effet choisi, Ctrl+clic le place ;
## tirer un effet placé le déplace en un pas ; Suppr le retire ; le panneau choisit l'effet et montre ses réglages.

var _document: RoomDocument
var _view: RoomView
var _input: EffectInput
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
	_input = auto_free(EffectInput.new())
	add_child(_input)
	_input.setup(_view, _document, settings)
	_input.active = true
	_refusals.clear()
	_input.refused.connect(func(reason: String) -> void: _refusals.append(reason))


func _left(pressed: bool, world: Vector3, ctrl: bool = false) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = _view.view_transform.world_to_screen(world)
	event.ctrl_pressed = ctrl
	_input.handle(event)


func _count() -> int:
	return (_document.room_value(&"effect_ids") as PackedStringArray).size()


func test_sans_effet_choisi_ctrl_clic_est_refuse() -> void:
	var count: int = _count()
	_left(true, Vector3(5, 0, 5), true)
	assert_int(_count()).is_equal(count)
	assert_array(_refusals).is_equal(["Choisir d'abord un effet dans la liste"])


func test_ctrl_clic_place_l_effet_choisi() -> void:
	_input.current_fx = &"vapeur"
	var count: int = _count()
	_left(true, Vector3(5, 0, 5), true)
	assert_int(_count()).is_equal(count + 1)
	assert_str((_document.room_value(&"effect_ids") as PackedStringArray)[count]).is_equal("vapeur")
	assert_int(_input.chosen).is_equal(count)


func test_tirer_un_effet_le_deplace_et_suppr_le_retire() -> void:
	var start: Vector3 = (_document.room_value(&"effect_positions") as PackedVector3Array)[0]
	var target: Vector3 = start + Vector3(1.5, 0, -1)
	_left(true, start)
	assert_int(_input.chosen).is_equal(0)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = _view.view_transform.world_to_screen(target)
	_input.handle(motion)
	_left(false, target)
	assert_vector((_document.room_value(&"effect_positions") as PackedVector3Array)[0]).is_equal_approx(target,
			Vector3.ONE * 0.01)
	var count: int = _count()
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_DELETE
	key.pressed = true
	_input.handle(key)
	assert_int(_count()).is_equal(count - 1)


func test_le_panneau_choisit_l_effet_et_montre_ses_reglages() -> void:
	var effects: Array[FxDef] = []
	effects.assign(DefinitionFolder.new().load_all("res://5_data/effets", FxDef))
	var panel: EffectPanel = auto_free(EffectPanel.new())
	add_child(panel)
	panel.setup(effects)
	var chosen: Array[StringName] = []
	panel.effect_chosen.connect(func(effect_id: StringName) -> void: chosen.append(effect_id))
	panel.choose(0)
	assert_array(chosen).is_equal([effects[0].id])
	assert_str(panel.details()).contains("particules/s")
