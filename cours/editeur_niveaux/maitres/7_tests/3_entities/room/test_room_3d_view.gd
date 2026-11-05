extends GdUnitTestSuite
## La salle en 3D, celle du jeu : un sprite par chose, avec la région de son asset et sa couleur ; chaque sprite à la
## position de sa chose, au-dessus du sol selon son calque ; une chose inactive est cachée en jeu, montrée en transparence
## par l'éditeur ; reconstruire remplace les sprites.
#@ 17+
## Une pièce peinte en projection se pose à plat sans la caméra du jeu, d'après elle quand la salle la connaît.
#@ all

var _catalog: AssetCatalogDef
var _room: RoomData


func before_test() -> void:
	_catalog = ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef
	_room = ResourceLoader.load("res://5_data/salles/pont.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as RoomData


func _view(show_inactive: bool) -> Room3DView:
	var view: Room3DView = auto_free(Room3DView.new())
	view.show_inactive = show_inactive
	add_child(view)
	view.build(_room, _catalog)
	return view


func test_un_sprite_par_chose_avec_sa_region() -> void:
	var view: Room3DView = _view(false)
	assert_int(view.sprite_count()).is_equal(_room.thing_count())
	var sprite: Sprite3D = view.sprite_of(_room.thing_ids[0])
	var asset: AssetDef = _catalog.find(StringName(_room.thing_assets[0]))
	assert_bool(sprite.region_enabled).is_true()
	assert_bool(sprite.region_rect == Rect2(asset.region)).is_true()
	assert_bool(sprite.shaded).is_false()


func test_chaque_sprite_est_a_sa_place_au_dessus_de_son_calque() -> void:
	var view: Room3DView = _view(false)
	var last: int = _room.thing_count() - 1
	var sprite: Sprite3D = view.sprite_of(_room.thing_ids[last])
	var place: Vector3 = _room.thing_positions[last]
	assert_float(sprite.position.x).is_equal_approx(place.x, 0.0001)
	assert_float(sprite.position.z).is_equal_approx(place.z, 0.0001)
	var expected: float = FlatLayout.height(_catalog.layers.find(_room.thing_layers[last]), _room.thing_sort[last],
			place.y)
	assert_float(sprite.position.y).is_equal_approx(expected, 0.0001)


func test_une_chose_inactive_est_cachee_en_jeu_montree_par_l_editeur() -> void:
	var active: PackedByteArray = _room.thing_active
	active[0] = 0
	_room.thing_active = active
	assert_bool(_view(false).sprite_of(_room.thing_ids[0]).visible).is_false()
	var shown: Sprite3D = _view(true).sprite_of(_room.thing_ids[0])
	assert_bool(shown.visible).is_true()
	assert_float(shown.modulate.a).is_less(1.0)


func test_reconstruire_remplace_les_sprites() -> void:
	var view: Room3DView = _view(false)
	view.build(_room, _catalog)
	assert_int(view.get_child_count()).is_equal(_room.thing_count())
#@ 17+


func test_une_piece_peinte_se_pose_d_apres_la_camera_du_jeu() -> void:
	var camera: CameraDef = ResourceLoader.load("res://5_data/camera/camera.tres") as CameraDef
	# Une copie à part du catalogue (celui du cache reste intact), où le premier asset de la salle est peint.
	var catalog: AssetCatalogDef = ResourceLoader.load("res://5_data/catalogue/catalogue.tres", "",
			ResourceLoader.CACHE_MODE_IGNORE) as AssetCatalogDef
	var asset: AssetDef = catalog.find(StringName(_room.thing_assets[0]))
	asset.painted = true
	var view: Room3DView = auto_free(Room3DView.new())
	add_child(view)
	view.build(_room, catalog)
	var sprite: Sprite3D = view.sprite_of(_room.thing_ids[0])
	var flat: Basis = FlatLayout.basis(_room.thing_rotations[0], _room.thing_scales[0], FlatLayout.depth_ratio(asset))
	assert_bool(sprite.basis.is_equal_approx(flat)).is_true()
	view.game_camera = camera
	view.build(_room, catalog)
	sprite = view.sprite_of(_room.thing_ids[0])
	var painted: Basis = FlatLayout.painted_basis(camera, _room.thing_rotations[0], _room.thing_scales[0],
			FlatLayout.depth_ratio(asset))
	assert_bool(sprite.basis.is_equal_approx(painted)).is_true()
