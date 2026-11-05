extends GdUnitTestSuite
## La fabrique des salles : un identifiant se tire du nom (minuscules, sans accents, tirets bas) et reste unique dans le
## projet ; un nom vide donne « salle » ; une salle neuve est valide, avec son contour et le départ du héros dedans.


func test_un_identifiant_se_tire_du_nom() -> void:
	var factory: RoomFactory = RoomFactory.new()
	assert_str(String(factory.id_from_name("Salle des machines", PackedStringArray()))).is_equal("salle_des_machines")
	assert_str(String(factory.id_from_name("  Pont supérieur !", PackedStringArray()))).is_equal("pont_superieur")


func test_un_identifiant_reste_unique() -> void:
	var factory: RoomFactory = RoomFactory.new()
	var existing: PackedStringArray = PackedStringArray(["hangar", "hangar_2"])
	assert_str(String(factory.id_from_name("Hangar", existing))).is_equal("hangar_3")


func test_un_nom_vide_donne_salle() -> void:
	assert_str(String(RoomFactory.new().id_from_name("?!", PackedStringArray()))).is_equal(RoomFactory.FALLBACK_ID)


func test_une_salle_neuve_est_valide() -> void:
	var layers: PackedStringArray = (ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef).layers
	var room: RoomData = RoomFactory.new_room(&"atelier", "L'atelier", Vector2(20, 12), layers)
	assert_array(room.validate()).is_empty()
	assert_int(room.collisions.size()).is_equal(1)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(room.hero_start.x, room.hero_start.z), room.collisions[0])) \
			.is_true()
	assert_int(room.thing_count()).is_equal(0)
