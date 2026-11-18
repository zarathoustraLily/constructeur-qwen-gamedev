extends GdUnitTestSuite
## La recherche trouve les modèles 3D, les atlas et les dossiers d'images numérotées, sous-dossiers compris, et rien
## d'autre : ni les dossiers cachés, ni les images sans numéro, ni des images numérotées à des noms différents, ni les
## pages d'un atlas. Le résultat est trié par catégorie puis par identifiant ; un dossier introuvable et un identifiant
## en double sont signalés.
#@ 2+
## Le fichier d'accompagnement d'un asset se trouve à côté de lui.
#@ all

const ROOT: String = "user://test_recherche"


func before_test() -> void:
	_remove_tree(ROOT)
	for file: String in ["heros/heros.glb", "heros/.cache/vieux.glb", "ennemis/golem/golem.gltf",
			"effets/feu/feu_01.png", "effets/feu/feu_02.png", "effets/feu/feu_03.png", "effets/feu/visu.json",
			"effets/flamme/flamme.atlas.json", "effets/flamme/flamme_0.png", "effets/flamme/flamme_1.png",
			"effets/divers/fond.png", "effets/divers/ombre.png", "effets/melange/a_01.png", "effets/melange/b_02.png"]:
		var path: String = ROOT.path_join(file)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		FileAccess.open(path, FileAccess.WRITE).close()


func after_test() -> void:
	_remove_tree(ROOT)


func _remove_tree(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for sub: String in DirAccess.get_directories_at(folder):
		_remove_tree(folder.path_join(sub))
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)


func _sources() -> Array[AssetSource]:
	var sources: Array[AssetSource] = [AssetSource.new(ROOT.path_join("effets"), "effet"),
			AssetSource.new(ROOT.path_join("ennemis"), "ennemi"), AssetSource.new(ROOT.path_join("heros"), "heros")]
	return sources


func _ids(scanner: AssetScanner) -> Array[String]:
	var ids: Array[String] = []
	for entry: AssetEntry in scanner.entries:
		ids.append(entry.id)
	return ids


func test_la_recherche_trouve_chaque_forme_d_asset_et_rien_d_autre() -> void:
	var scanner: AssetScanner = AssetScanner.scan(_sources())
	assert_array(scanner.errors).is_empty()
	assert_array(_ids(scanner)).is_equal(["heros/heros", "ennemi/golem/golem", "effet/feu", "effet/flamme/flamme"])


func test_chaque_asset_a_sa_forme_son_nom_et_son_chemin() -> void:
	var entries: Array[AssetEntry] = AssetScanner.scan(_sources()).entries
	assert_int(entries[0].kind).is_equal(AssetEntry.Kind.MODEL_3D)
	assert_int(entries[1].kind).is_equal(AssetEntry.Kind.MODEL_3D)
	assert_int(entries[2].kind).is_equal(AssetEntry.Kind.FRAMES_2D)
	assert_int(entries[3].kind).is_equal(AssetEntry.Kind.ATLAS_2D)
	assert_str(entries[2].path).is_equal(ROOT.path_join("effets/feu"))
	assert_str(entries[3].display_name).is_equal("flamme")


func test_un_dossier_introuvable_est_signale() -> void:
	var sources: Array[AssetSource] = [AssetSource.new(ROOT.path_join("absent"), "boss")]
	var scanner: AssetScanner = AssetScanner.scan(sources)
	assert_array(scanner.entries).is_empty()
	assert_array(scanner.errors).is_equal(["dossier introuvable : " + ROOT.path_join("absent")])


func test_un_identifiant_en_double_est_signale_et_le_premier_reste() -> void:
	var sources: Array[AssetSource] = [AssetSource.new(ROOT.path_join("heros"), "heros"),
			AssetSource.new(ROOT.path_join("heros"), "heros")]
	var scanner: AssetScanner = AssetScanner.scan(sources)
	assert_int(scanner.entries.size()).is_equal(1)
	assert_int(scanner.errors.size()).is_equal(1)
	assert_str(scanner.errors[0]).starts_with("identifiant en double : heros/heros")


func test_les_assets_d_exemple_du_projet_sont_trouves() -> void:
	var config: ViewerConfig = ViewerConfig.load_file("res://5_data/visualiseur/config.json")
	var scanner: AssetScanner = AssetScanner.scan(config.sources)
	assert_array(scanner.errors).is_empty()
	assert_array(_ids(scanner)).is_equal(["heros/heros", "ennemi/golem", "prop/coffre", "effet/etincelle",
			"effet/flamme/flamme"])
	assert_int(scanner.count("effet")).is_equal(2)
#@ 2+


func test_le_fichier_d_accompagnement_est_a_cote_de_l_asset() -> void:
	var entries: Array[AssetEntry] = AssetScanner.scan(_sources()).entries
	assert_str(entries[0].sidecar_path()).is_equal(ROOT.path_join("heros/heros.visu.json"))
	assert_str(entries[2].sidecar_path()).is_equal(ROOT.path_join("effets/feu/visu.json"))
	assert_str(entries[3].sidecar_path()).is_equal(ROOT.path_join("effets/flamme/flamme.visu.json"))
#@ all
