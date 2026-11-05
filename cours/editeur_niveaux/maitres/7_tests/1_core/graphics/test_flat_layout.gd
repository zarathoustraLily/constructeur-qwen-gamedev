extends GdUnitTestSuite
## La pose à plat : un calque plus haut passe toujours au-dessus, à rang égal ou non (cinquante rangs tiennent dans un
## cran) ; un quad couché garde le haut de son image vers le fond de la salle (−z) ; la rotation tourne dans le même sens
## que sur la carte ; la taille d'un pixel donne la largeur en jeu ; une ancre au pied pose le bas de l'image sur la
## position.
#@ 17+
## Pour les pièces peintes en projection : un déplacement d'écran ramené au sol se revoit tel quel par la caméra du jeu ;
## un mètre vers le bas de l'écran couvre deux mètres de sol à 30° ; la pièce reste couchée et tourne dans l'écran.
#@ all


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
#@ 17+


func _camera() -> CameraDef:
	return ResourceLoader.load("res://5_data/camera/camera.tres") as CameraDef


# La projection de la caméra du jeu, ouverte comme le jeu sur le point (10, 0, 10), dans une vue de 800 × 600.
func _projection() -> CameraTransform:
	var projection: CameraTransform = CameraTransform.new()
	projection.setup(ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef, _camera())
	projection.show_like_game(Vector3(10, 0, 10), Vector2(800, 600))
	return projection


# Ce que la caméra montre, en pixels, d'un déplacement `offset` (en mètres) depuis le point (10, 0, 10).
func _seen(projection: CameraTransform, offset: Vector3) -> Vector2:
	return projection.world_to_screen(Vector3(10, 0, 10) + offset) - projection.world_to_screen(Vector3(10, 0, 10))


func test_un_deplacement_d_ecran_ramene_au_sol_se_revoit_tel_quel() -> void:
	var projection: CameraTransform = _projection()
	for screen_m: Vector2 in [Vector2(1, 0), Vector2(0, 1), Vector2(2.5, -1.25)]:
		var ground: Vector2 = FlatLayout.ground_from_screen(_camera(), screen_m)
		assert_vector(_seen(projection, Vector3(ground.x, 0, ground.y))).is_equal_approx(
				screen_m * projection.pixels_per_meter(), Vector2.ONE * 0.001)


func test_un_metre_vers_le_bas_de_l_ecran_couvre_deux_metres_de_sol_a_30_degres() -> void:
	assert_float(FlatLayout.ground_from_screen(_camera(), Vector2.RIGHT).length()).is_equal_approx(1.0, 0.0001)
	assert_float(FlatLayout.ground_from_screen(_camera(), Vector2.DOWN).length()).is_equal_approx(2.0, 0.0001)


func test_une_piece_peinte_reste_couchee_et_tourne_dans_l_ecran() -> void:
	var laid: Basis = FlatLayout.painted_basis(_camera(), 30.0, 2.0, 1.0)
	assert_float(laid.x.y).is_equal(0.0)
	assert_float(laid.y.y).is_equal(0.0)
	assert_vector(laid.z).is_equal(Vector3.UP)
	var projection: CameraTransform = _projection()
	var turn: float = deg_to_rad(30.0)
	var ppm: float = projection.pixels_per_meter()
	assert_vector(_seen(projection, laid.x)).is_equal_approx(Vector2.RIGHT.rotated(turn) * 2.0 * ppm, Vector2.ONE * 0.001)
	assert_vector(_seen(projection, laid.y)).is_equal_approx(Vector2.UP.rotated(turn) * 2.0 * ppm, Vector2.ONE * 0.001)
