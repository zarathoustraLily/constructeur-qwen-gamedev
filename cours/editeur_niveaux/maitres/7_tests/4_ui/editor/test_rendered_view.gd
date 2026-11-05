extends GdUnitTestSuite
## La vue rendue : sa caméra filme chaque sprite là où la vue le projette (Godot et le calcul d'accord) ; la fenêtre de rendu suit la taille de la vue ; changer la salle reconstruit les
## sprites ; la carte de navigation centre la vue rendue sur le point cliqué et montre ce qu'elle filme.

var _document: RoomDocument
var _catalog: AssetCatalogDef
var _transform: CameraTransform
var _view: RenderedView


func before_test() -> void:
	var settings: EditorSettingsDef = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_catalog = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_document = RoomDocument.new()
	_document.open(RoomStore.new().load_room("res://5_data/salles/pont.tres"))
	_transform = CameraTransform.new()
	_transform.setup(settings, ResourceLoader.load("res://5_data/camera/camera.tres") as CameraDef)
	_view = auto_free(RenderedView.new())
	_view.size = Vector2(800, 600)
	add_child(_view)
	_view.set_renderer(Room3DView.new())
	_view.setup(_document, _catalog, _transform)
	_transform.frame(Vector2(24, 20), _view.size)


func _top_obstacle() -> int:
	var shown: PackedInt32Array = _view.visible_ids()
	for index: int in range(shown.size() - 1, -1, -1):
#@ 6
		if _document.value(shown[index], &"layer") == "obstacles":
			return shown[index]
#@ 7+
		var center: Vector2 = _view.screen_rect_of(shown[index]).get_center()
		if _document.value(shown[index], &"layer") == "obstacles" and _view.thing_at(center) == shown[index]:
			return shown[index]
#@ all
	return 0


func test_la_camera_filme_chaque_sprite_la_ou_la_vue_le_projette() -> void:
	for thing_id: int in [_document.ids()[0], _top_obstacle()]:
		var sprite: Sprite3D = _view.room_3d().sprite_of(thing_id)
		assert_vector(_view.camera().unproject_position(sprite.global_position)).is_equal_approx(
				_transform.world_to_screen(sprite.global_position), Vector2.ONE * 0.5)


#@ 7+
func test_un_clic_au_centre_projete_designe_la_chose() -> void:
	var thing_id: int = _top_obstacle()
	assert_int(thing_id).is_greater(0)
	assert_int(_view.thing_at(_view.screen_rect_of(thing_id).get_center())).is_equal(thing_id)
#@ all


func test_la_fenetre_de_rendu_suit_la_taille_de_la_vue() -> void:
	assert_vector(Vector2(_view.viewport().size)).is_equal(Vector2(800, 600))
	_view.size = Vector2(640, 360)
	assert_vector(Vector2(_view.viewport().size)).is_equal(Vector2(640, 360))


func test_la_grille_couvre_la_salle_avec_ses_axes() -> void:
	var mesh: Mesh = _view.grid().mesh
	assert_object(mesh).is_not_null()
	var vertices: int = mesh.surface_get_array_len(0)
	assert_int(vertices).is_equal(2 * ((24 + 1) + (20 + 1)))
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	# Les couleurs des sommets se rangent sur 8 bits : 0,45 revient à un centième près, pas à l'identique.
	var expected: Color = RenderedView.AXIS_Z_COLOR
	assert_vector(Vector4(colors[0].r, colors[0].g, colors[0].b, colors[0].a)).is_equal_approx(
			Vector4(expected.r, expected.g, expected.b, expected.a), Vector4.ONE * 0.01)
	_view.show_grid = false
	assert_bool(_view.grid().visible).is_false()


func test_changer_la_salle_reconstruit_les_sprites() -> void:
	var count: int = _view.room_3d().sprite_count()
	_document.add_thing({&"asset": "caisse_cargo", &"layer": "obstacles", &"position": Vector3(4, 0, 4)})
	assert_int(_view.room_3d().sprite_count()).is_equal(count + 1)


func test_la_carte_centre_la_vue_et_montre_ce_qu_elle_filme() -> void:
	var map_transform: ViewTransform = ViewTransform.new()
	map_transform.setup(ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef)
	var map: RoomView = auto_free(RoomView.new())
	map.size = Vector2(240, 180)
	add_child(map)
	map.setup(_document, _catalog, map_transform)
	map_transform.frame(Vector2(24, 20), map.size)
	var input: MapInput = auto_free(MapInput.new())
	input.setup(map, _transform)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = map_transform.world_to_screen(Vector3(5, 0, 6))
	assert_bool(input.handle(click)).is_true()
	assert_vector(_transform.focus).is_equal_approx(Vector3(5, 0, 6), Vector3.ONE * 0.001)
	var footprint: PackedVector2Array = input.footprint(_view.size)
	assert_int(footprint.size()).is_equal(4)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(5, 6), footprint)).is_true()
