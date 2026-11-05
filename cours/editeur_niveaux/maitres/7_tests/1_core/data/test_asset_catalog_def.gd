extends GdUnitTestSuite
## Le catalogue : celui de l'exemple est valide et connaît tous les assets et calques des trois salles ; un identifiant
## en double, un calque par défaut inconnu, une région hors de la planche ou une taille nulle sont signalés ; une salle
## qui pose un asset inconnu est signalée chose par chose.

const CATALOG: String = "res://5_data/catalogue/catalogue.tres"


func _catalog() -> AssetCatalogDef:
	return ResourceLoader.load(CATALOG, "", ResourceLoader.CACHE_MODE_IGNORE) as AssetCatalogDef


func test_le_catalogue_d_exemple_est_valide() -> void:
	var catalog: AssetCatalogDef = _catalog()
	assert_array(catalog.validate()).is_empty()
	assert_int(catalog.assets.size()).is_equal(20)
	assert_object(catalog.find(&"caisse_cargo")).is_not_null()
	assert_object(catalog.find(&"absent")).is_null()


func test_les_trois_salles_ne_posent_que_des_assets_connus() -> void:
	var catalog: AssetCatalogDef = _catalog()
	for room_name: String in ["hangar", "soute", "pont"]:
		var room: RoomData = ResourceLoader.load("res://5_data/salles/%s.tres" % room_name) as RoomData
		assert_array(catalog.room_errors(room)).is_empty()


func test_un_identifiant_en_double_est_signale() -> void:
	var catalog: AssetCatalogDef = _catalog()
	catalog.assets.append(catalog.assets[0].duplicate() as AssetDef)
	assert_array(catalog.validate()).contains(["asset %s : en double" % catalog.assets[0].id])


func test_un_calque_par_defaut_inconnu_est_signale() -> void:
	var catalog: AssetCatalogDef = _catalog()
	catalog.assets[0].default_layer = &"plafond"
	assert_array(catalog.validate()).contains(["asset %s : calque par défaut inconnu plafond" % catalog.assets[0].id])


func test_une_region_hors_de_la_planche_est_signalee() -> void:
	var catalog: AssetCatalogDef = _catalog()
	var asset: AssetDef = catalog.assets[0]
	var corner: Vector2i = Vector2i(asset.atlas.get_width(), asset.atlas.get_height()) - Vector2i(10, 10)
	asset.region = Rect2i(corner, Vector2i(64, 64))
	assert_array(asset.validate()).is_equal(["asset %s : région hors de la planche" % asset.id])


func test_une_taille_nulle_est_signalee() -> void:
	var asset: AssetDef = _catalog().assets[0]
	asset.size_m = Vector2(0, 1)
	assert_array(asset.validate()).is_equal(["asset %s : taille positive requise" % asset.id])


func test_un_asset_inconnu_d_une_salle_est_signale() -> void:
	var catalog: AssetCatalogDef = _catalog()
	var room: RoomData = ResourceLoader.load("res://5_data/salles/pont.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	var assets: PackedStringArray = room.thing_assets
	assets[0] = "licorne"
	room.thing_assets = assets
	assert_array(catalog.room_errors(room)).is_equal(["chose %d : asset inconnu licorne" % room.thing_ids[0]])
