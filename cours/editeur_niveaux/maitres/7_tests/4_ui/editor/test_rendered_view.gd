extends GdUnitTestSuite
## La vue rendue : sa caméra filme chaque sprite là où la vue le projette (Godot et le calcul d'accord) ; la fenêtre de rendu suit la taille de la vue ; changer la salle reconstruit les
## sprites ; la carte de navigation centre la vue rendue sur le point cliqué et montre ce qu'elle filme.
#@ 17+
## Une pièce peinte en projection se voit telle qu'elle est peinte, au pixel près pour la caméra de Godot, tournée et
## agrandie dans le plan de l'écran ; sur la carte, son emprise est ce rectangle ramené au sol.
#@ all

var _document: RoomDocument
var _catalog: AssetCatalogDef
var _transform: CameraTransform
var _view: RenderedView
#@ 17+
var _painted_catalog: AssetCatalogDef
#@ all


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
#@ 17+


# Une dalle peinte en projection, faite en mémoire : une image de 120 × 60 pixels, peinte à 80 pixels par mètre, donc
# 1,5 × 0,75 m d'écran, ancrée en son centre.
func _painted_asset() -> AssetDef:
	var asset: AssetDef = AssetDef.new()
	asset.id = &"dalle_peinte"
	asset.atlas = ImageTexture.create_from_image(Image.create_empty(120, 60, false, Image.FORMAT_RGBA8))
	asset.region = Rect2i(0, 0, 120, 60)
	asset.size_m = Vector2(1.5, 0.75)
	asset.category = &"detail"
	asset.default_layer = &"detail_sol"
	asset.painted = true
	return asset


# Une seconde vue rendue de 800 × 600, sur le même document et la même caméra, dont le catalogue (une copie à part :
# celui du cache reste intact) connaît la dalle peinte.
func _painted_view() -> RenderedView:
	var catalog: AssetCatalogDef = ResourceLoader.load("res://5_data/catalogue/catalogue.tres", "",
			ResourceLoader.CACHE_MODE_IGNORE) as AssetCatalogDef
	catalog.assets.append(_painted_asset())
	_painted_catalog = catalog
	var view: RenderedView = auto_free(RenderedView.new())
	view.size = Vector2(800, 600)
	add_child(view)
	view.set_renderer(Room3DView.new())
	view.game_camera = ResourceLoader.load("res://5_data/camera/camera.tres") as CameraDef
	view.setup(_document, catalog, _transform)
	return view


# Le rectangle de l'image de la dalle `thing_id` à l'écran (haut gauche, haut droit, bas droit, bas gauche), tourné de
# `rotation_deg` autour de son ancre, à l'échelle `scale_factor`. L'ancre est celle du sprite, relevée à la hauteur de
# son calque.
func _painted_rect(view: RenderedView, thing_id: int, rotation_deg: float, scale_factor: float) -> PackedVector2Array:
	var center: Vector2 = _transform.world_to_screen(view.room_3d().sprite_of(thing_id).global_position)
	var half: Vector2 = Vector2(1.5, 0.75) * scale_factor * _transform.pixels_per_meter() / 2.0
	var result: PackedVector2Array = PackedVector2Array()
	for corner: Vector2 in [-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]:
		result.append(center + corner.rotated(deg_to_rad(rotation_deg)))
	return result


# Les quatre coins du sprite de `thing_id`, vus par la caméra de Godot, dans le même ordre : le quad du sprite (centré
# sur son décalage, en pixels de l'image fois la taille d'un pixel ; +y vers le haut de l'image), mené dans la salle
# par sa transformation, puis projeté.
func _seen_corners(view: RenderedView, thing_id: int) -> PackedVector2Array:
	var sprite: Sprite3D = view.room_3d().sprite_of(thing_id)
	var half: Vector2 = sprite.region_rect.size / 2.0
	var seen: PackedVector2Array = PackedVector2Array()
	for corner: Vector2 in [Vector2(-half.x, half.y), half, Vector2(half.x, -half.y), -half]:
		var local: Vector2 = (corner + sprite.offset) * sprite.pixel_size
		seen.append(view.camera().unproject_position(sprite.global_transform * Vector3(local.x, local.y, 0.0)))
	return seen


func test_une_piece_peinte_se_voit_telle_qu_elle_est_peinte() -> void:
	var view: RenderedView = _painted_view()
	# Au calque le plus haut, et devant les autres choses de ce calque : un clic au centre la désigne.
	var thing_id: int = _document.add_thing({&"asset": "dalle_peinte", &"layer": "avant_plan",
			&"position": Vector3(10, 0, 8), &"sort": 1})
	var expected: PackedVector2Array = _painted_rect(view, thing_id, 0.0, 1.0)
	var drawn: PackedVector2Array = view.corners_of(thing_id)
	var seen: PackedVector2Array = _seen_corners(view, thing_id)
	for index: int in 4:
		assert_vector(drawn[index]).is_equal_approx(expected[index], Vector2.ONE * 0.01)
		assert_vector(seen[index]).is_equal_approx(expected[index], Vector2.ONE * 0.5)
	assert_int(view.thing_at((expected[0] + expected[2]) / 2.0)).is_equal(thing_id)


func test_tournee_et_agrandie_elle_tourne_dans_l_ecran_comme_dans_un_logiciel_de_dessin() -> void:
	var view: RenderedView = _painted_view()
	var thing_id: int = _document.add_thing({&"asset": "dalle_peinte", &"layer": "detail_sol",
			&"position": Vector3(10, 0, 8), &"rotation": 30.0, &"scale": 2.0})
	var expected: PackedVector2Array = _painted_rect(view, thing_id, 30.0, 2.0)
	var drawn: PackedVector2Array = view.corners_of(thing_id)
	var seen: PackedVector2Array = _seen_corners(view, thing_id)
	for index: int in 4:
		assert_vector(drawn[index]).is_equal_approx(expected[index], Vector2.ONE * 0.01)
		assert_vector(seen[index]).is_equal_approx(expected[index], Vector2.ONE * 0.5)


func test_sur_la_carte_son_emprise_est_le_rectangle_peint_ramene_au_sol() -> void:
	var view: RenderedView = _painted_view()
	var thing_id: int = _document.add_thing({&"asset": "dalle_peinte", &"layer": "detail_sol",
			&"position": Vector3(10, 0, 8), &"rotation": 30.0})
	var map_transform: ViewTransform = ViewTransform.new()
	map_transform.setup(ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef)
	var map: RoomView = auto_free(RoomView.new())
	map.size = Vector2(240, 180)
	add_child(map)
	map.game_camera = view.game_camera
	map.setup(_document, _painted_catalog, map_transform)
	map_transform.frame(Vector2(24, 20), map.size)
	var on_map: PackedVector2Array = map.corners_of(thing_id)
	var in_view: PackedVector2Array = view.corners_of(thing_id)
	# La carte rend des points du sol ; la vue rendue les voit à la hauteur du sprite.
	var lift: Vector3 = Vector3.UP * view.room_3d().sprite_of(thing_id).global_position.y
	for index: int in 4:
		assert_vector(_transform.world_to_screen(map_transform.screen_to_world(on_map[index]) + lift)).is_equal_approx(
				in_view[index], Vector2.ONE * 0.01)
	# Vu de dessus, ce n'est plus un rectangle : le bas de l'écran couvre deux fois plus de sol que sa droite.
	assert_float(absf((on_map[1] - on_map[0]).normalized().dot((on_map[3] - on_map[0]).normalized()))).is_greater(0.1)
