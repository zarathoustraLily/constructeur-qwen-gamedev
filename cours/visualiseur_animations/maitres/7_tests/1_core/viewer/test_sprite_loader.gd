extends GdUnitTestSuite
## Un atlas de l'optimiseur se lit avec ses pages et la place de chaque image ; un dossier d'images se lit dans l'ordre
## de leurs numéros, à la cadence donnée ; une image vide ne montre rien ; un fichier qui n'est pas un atlas et une
## page absente sont des erreurs.

const FLAME: String = "res://6_assets/exemple/effets/flamme/flamme.atlas.json"
const SPARK: String = "res://6_assets/exemple/effets/etincelle"
const ROOT: String = "user://test_atlas"


func after_test() -> void:
	if DirAccess.dir_exists_absolute(ROOT):
		for file: String in DirAccess.get_files_at(ROOT):
			DirAccess.remove_absolute(ROOT.path_join(file))
		DirAccess.remove_absolute(ROOT)


func _write(file: String, text: String) -> String:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var path: String = ROOT.path_join(file)
	var out: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	out.store_string(text)
	out.close()
	return path


func test_l_atlas_de_la_flamme_se_lit_avec_la_place_de_chaque_image() -> void:
	var sprites: SpriteSet = SpriteLoader.load_atlas(FLAME)
	assert_str(sprites.error).is_empty()
	assert_int(sprites.pages.size()).is_equal(1)
	assert_str(sprites.blend).is_equal("normal")
	var flame: SpriteAnimation = sprites.animations["flamme"]
	assert_int(flame.frames.size()).is_equal(12)
	assert_float(flame.fps).is_equal(12.0)
	assert_object(flame.frame_size).is_equal(Vector2i(192, 192))
	var data: Dictionary[String, Variant] = JsonValues.object(JSON.parse_string(FileAccess.get_file_as_string(FLAME)))
	var flame_data: Dictionary[String, Variant] = JsonValues.object(JsonValues.object(data["animations"])["flamme"])
	var first: Dictionary[String, Variant] = JsonValues.object(JsonValues.list(flame_data["images"])[0])
	var zone: Array[Variant] = JsonValues.list(first["zone"])
	assert_object(flame.frames[0].region).is_equal(Rect2i(int(zone[0]), int(zone[1]), int(zone[2]), int(zone[3])))
	assert_float(flame.frames[0].scale_factor()).is_equal(1.0)


func test_un_dossier_d_images_se_lit_dans_l_ordre_a_sa_cadence() -> void:
	var sprites: SpriteSet = SpriteLoader.load_frames(SPARK, 16.0)
	assert_str(sprites.error).is_empty()
	var spark: SpriteAnimation = sprites.animations["etincelle"]
	assert_int(spark.frames.size()).is_equal(8)
	assert_float(spark.fps).is_equal(16.0)
	assert_object(spark.frame_size).is_equal(Vector2i(96, 96))
	assert_int(spark.frames[7].page).is_equal(7)
	assert_float(spark.length()).is_equal(0.5)


func test_une_image_vide_ne_montre_rien() -> void:
	var path: String = _write("vide.atlas.json", JSON.stringify({"format": "atlas_animation", "version": 1,
			"pages": [], "animations": {"rien": {"ips": 10, "cadre": [8, 8],
			"images": [{"page": -1, "zone": [0, 0, 0, 0], "decalage": [0, 0]}]}}}))
	var sprites: SpriteSet = SpriteLoader.load_atlas(path)
	assert_str(sprites.error).is_empty()
	assert_bool(sprites.animations["rien"].frames[0].is_empty()).is_true()


func test_un_fichier_qui_n_est_pas_un_atlas_est_une_erreur() -> void:
	var path: String = _write("autre.atlas.json", "{\"format\": \"autre\"}")
	assert_str(SpriteLoader.load_atlas(path).error).is_equal(
			"pas un atlas « atlas_animation » version 1 : " + path)


func test_une_page_absente_est_une_erreur() -> void:
	var path: String = _write("sans_page.atlas.json", JSON.stringify({"format": "atlas_animation", "version": 1,
			"pages": ["absente_0.png"], "animations": {}}))
	assert_str(SpriteLoader.load_atlas(path).error).is_equal("page introuvable ou illisible : absente_0.png")


func test_la_cadence_d_une_animation_boucle_ou_s_arrete_sur_la_derniere_image() -> void:
	var spark: SpriteAnimation = SpriteLoader.load_frames(SPARK, 16.0).animations["etincelle"]
	assert_int(spark.frame_at(0.0, true)).is_equal(0)
	assert_int(spark.frame_at(0.19, true)).is_equal(3)
	assert_int(spark.frame_at(0.5, true)).is_equal(0)
	assert_int(spark.frame_at(2.0, false)).is_equal(7)
