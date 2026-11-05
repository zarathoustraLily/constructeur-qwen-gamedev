extends GdUnitTestSuite
## Les gestes de la souris sur la vue : la molette zoome autour du curseur ; glisser avec le bouton du milieu déplace la
## vue ; un mouvement sans bouton ne change rien.

var _settings: EditorSettingsDef
var _transform: ViewTransform
var _input: RoomViewInput


func before_test() -> void:
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_transform = ViewTransform.new()
	_transform.setup(_settings)
	var view: Control = auto_free(Control.new())
	_input = auto_free(RoomViewInput.new())
	_input.setup(view, _transform, _settings)


func _button(index: MouseButton, pressed: bool, position: Vector2 = Vector2.ZERO) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = position
	return event


func test_la_molette_zoome_autour_du_curseur() -> void:
	var cursor: Vector2 = Vector2(300, 200)
	var under: Vector3 = _transform.screen_to_world(cursor)
	assert_bool(_input.handle(_button(MOUSE_BUTTON_WHEEL_UP, true, cursor))).is_true()
	assert_float(_transform.zoom).is_greater(1.0)
	assert_vector(_transform.screen_to_world(cursor)).is_equal_approx(under, Vector3.ONE * 0.0001)


func test_glisser_avec_le_bouton_du_milieu_deplace_la_vue() -> void:
	_input.handle(_button(MOUSE_BUTTON_MIDDLE, true))
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.relative = Vector2(15, -8)
	assert_bool(_input.handle(motion)).is_true()
	assert_vector(_transform.origin).is_equal(Vector2(15, -8))
	_input.handle(_button(MOUSE_BUTTON_MIDDLE, false))
	assert_bool(_input.handle(motion)).is_false()
	assert_vector(_transform.origin).is_equal(Vector2(15, -8))
