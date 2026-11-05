extends GdUnitTestSuite
## La pose à plat : un calque plus haut passe toujours au-dessus, à rang égal ou non (cinquante rangs tiennent dans un
## cran) ; un quad couché garde le haut de son image vers le fond de la salle (−z) ; la rotation tourne dans le même sens
## que sur la carte ; la taille d'un pixel donne la largeur en jeu ; une ancre au pied pose le bas de l'image sur la
## position.


func _asset(asset_id: StringName) -> AssetDef:
	return (ResourceLoader.load("res://5_data/catalogue/catalogue.tres") as AssetCatalogDef).find(asset_id)


func test_un_calque_plus_haut_passe_au_dessus() -> void:
	assert_float(FlatLayout.height(2, -40, 0.0)).is_greater(FlatLayout.height(1, 40, 0.0))
	assert_float(FlatLayout.height(1, 3, 0.0)).is_greater(FlatLayout.height(1, 2, 0.0))
	assert_float(FlatLayout.height(0, 0, 3.0)).is_equal(3.0)


func test_un_quad_couche_garde_le_haut_de_l_image_vers_le_fond() -> void:
	var flat: Basis = FlatLayout.basis(0.0, 1.0, 1.0)
	assert_vector(flat * Vector3.UP).is_equal_approx(Vector3.FORWARD, Vector3.ONE * 0.0001)
	assert_vector(flat * Vector3.BACK).is_equal_approx(Vector3.UP, Vector3.ONE * 0.0001)


func test_la_rotation_tourne_comme_sur_la_carte() -> void:
	var turned: Basis = FlatLayout.basis(90.0, 1.0, 1.0)
	assert_vector(turned * Vector3.RIGHT).is_equal_approx(Vector3.BACK, Vector3.ONE * 0.0001)
	assert_vector(Vector2.RIGHT.rotated(deg_to_rad(90.0))).is_equal_approx(Vector2(0, 1), Vector2.ONE * 0.0001)


func test_la_taille_d_un_pixel_donne_la_largeur_en_jeu() -> void:
	var crate: AssetDef = _asset(&"caisse_cargo")
	assert_float(FlatLayout.pixel_size(crate) * crate.region.size.x).is_equal_approx(crate.size_m.x, 0.0001)
	var wall: AssetDef = _asset(&"mur_droit")
	var depth: float = wall.region.size.y * FlatLayout.pixel_size(wall) * FlatLayout.depth_ratio(wall)
	assert_float(depth).is_equal_approx(wall.size_m.y, 0.0001)


func test_une_ancre_au_pied_pose_le_bas_de_l_image() -> void:
	var crate: AssetDef = _asset(&"caisse_cargo")
	assert_vector(FlatLayout.offset(crate)).is_equal(Vector2(0, crate.region.size.y / 2.0))
	assert_vector(FlatLayout.offset(_asset(&"sol_tole"))).is_equal(Vector2.ZERO)
