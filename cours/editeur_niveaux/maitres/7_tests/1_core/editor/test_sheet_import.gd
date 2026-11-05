extends GdUnitTestSuite
## L'import d'une planche dans le catalogue : la planche de laurent y entre en onze assets peints en projection, à
## l'échelle commune, dans des pages compressées en BPTC qui pèsent bien moins que la planche gardée telle quelle ; un
## nouvel import garde les identifiants ; une pièce disparue quitte le catalogue, sauf si une salle s'en sert (l'import
## est alors refusé, rien n'est écrit) ; une pièce neuve prend un numéro neuf ; une planche sans transparence est
## refusée. Les pages et les planches d'essai s'écrivent dans un dossier à part, et le catalogue est une copie : rien du
## projet n'est réécrit par un test.

const SHEET: String = "res://6_assets/planches_peintes/sol_01.png"
const ROOT: String = "user://test_planches"

var _settings: EditorSettingsDef
var _catalog: AssetCatalogDef


func before_test() -> void:
	_vider(ROOT)
	DirAccess.make_dir_recursive_absolute(ROOT)
	_settings = ResourceLoader.load("res://5_data/editeur/reglages.tres") as EditorSettingsDef
	_catalog = ResourceLoader.load("res://5_data/catalogue/catalogue.tres", "",
			ResourceLoader.CACHE_MODE_IGNORE) as AssetCatalogDef


func after_test() -> void:
	_vider(ROOT)


func _vider(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	for sub: String in DirAccess.get_directories_at(folder):
		_vider(folder.path_join(sub))
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)


func _import(sheet_path: String, used: PackedStringArray = PackedStringArray()) -> SheetImport:
	var sheet: SheetImport = SheetImport.new()
	sheet.setup(_settings)
	sheet.import_sheet(sheet_path, _catalog, ROOT.path_join("peint"), used)
	return sheet


# Écrit dans le dossier d'essai la planche `file` : une image transparente de 64 × 64 où chaque rectangle de `rects`
# est opaque.
func _write_sheet(file: String, rects: Array[Rect2i]) -> String:
	var image: Image = Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for rect: Rect2i in rects:
		image.fill_rect(rect, Color(0.6, 0.5, 0.3))
	var path: String = ROOT.path_join(file)
	image.save_png(path)
	return path


func _sheet_ids(prefix: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	for asset: AssetDef in _catalog.assets:
		if String(asset.id).begins_with(prefix):
			ids.append(asset.id)
	return ids


func test_la_planche_de_laurent_entre_au_catalogue() -> void:
	var count: int = _catalog.assets.size()
	var sheet: SheetImport = _import(SHEET)
	assert_array(sheet.errors).is_empty()
	assert_int(_catalog.assets.size()).is_equal(count + 11)
	assert_array(_catalog.validate()).is_empty()
	var tiles: AssetDef = _catalog.find(&"sol_01_01")
	assert_bool(tiles.painted).is_true()
	assert_bool(tiles.source_rect == Rect2i(1, 11, 469, 472)).is_true()
	assert_vector(Vector2(tiles.region.size)).is_equal(Vector2(469, 472))
	assert_vector(tiles.size_m).is_equal_approx(Vector2(469, 472) / _settings.painted_pixels_per_meter,
			Vector2.ONE * 0.0001)
	assert_str(tiles.atlas.resource_path).is_equal(ROOT.path_join("peint/sol_01/page_0.res"))


func test_les_pages_sont_compressees_et_pesent_bien_moins_que_la_planche() -> void:
	var sheet: SheetImport = _import(SHEET)
	assert_int(sheet.sheet_bytes).is_equal(2000 * 2000 * 4)
	var pixels: int = 0
	for path: String in sheet.page_paths:
		var page: Texture2D = ResourceLoader.load(path) as Texture2D
		var image: Image = page.get_image()
		assert_int(image.get_format()).is_equal(Image.FORMAT_BPTC_RGBA)
		pixels += image.get_width() * image.get_height()
	# BPTC : un octet par pixel.
	assert_int(sheet.pages_bytes).is_equal(pixels)
	assert_int(sheet.pages_bytes * 10).is_less(sheet.sheet_bytes)


func test_un_nouvel_import_garde_les_identifiants() -> void:
	_import(SHEET)
	var first: Array[StringName] = _sheet_ids("sol_01_")
	var again: SheetImport = _import(SHEET)
	assert_array(again.errors).is_empty()
	assert_array(_sheet_ids("sol_01_")).is_equal(first)
	assert_array(again.removed_ids).is_empty()


func test_une_piece_disparue_qui_sert_encore_refuse_l_import() -> void:
	var path: String = _write_sheet("essai.png", [Rect2i(2, 2, 10, 10), Rect2i(30, 2, 10, 10), Rect2i(2, 40, 10, 10)])
	_import(path)
	assert_array(_sheet_ids("essai_")).is_equal([&"essai_01", &"essai_02", &"essai_03"])
	_write_sheet("essai.png", [Rect2i(2, 2, 10, 10), Rect2i(2, 40, 10, 10)])
	var refused: SheetImport = _import(path, PackedStringArray(["essai_02"]))
	assert_int(refused.errors.size()).is_equal(1)
	assert_array(_sheet_ids("essai_")).is_equal([&"essai_01", &"essai_02", &"essai_03"])


func test_une_piece_disparue_quitte_le_catalogue_et_une_neuve_prend_un_numero_neuf() -> void:
	var path: String = _write_sheet("essai.png", [Rect2i(2, 2, 10, 10), Rect2i(30, 2, 10, 10), Rect2i(2, 40, 10, 10)])
	_import(path)
	# La pièce du haut à droite disparaît ; une autre apparaît en bas à droite ; celle du bas grandit un peu.
	_write_sheet("essai.png", [Rect2i(2, 2, 10, 10), Rect2i(2, 40, 11, 11), Rect2i(40, 40, 12, 12)])
	var sheet: SheetImport = _import(path)
	assert_array(sheet.errors).is_empty()
	assert_array(sheet.removed_ids).is_equal([&"essai_02"])
	assert_array(sheet.asset_ids).is_equal([&"essai_01", &"essai_03", &"essai_04"])
	assert_object(_catalog.find(&"essai_02")).is_null()
	assert_bool(_catalog.find(&"essai_03").source_rect == Rect2i(2, 40, 11, 11)).is_true()
	assert_array(_catalog.validate()).is_empty()


func test_une_planche_sans_transparence_est_refusee() -> void:
	var image: Image = Image.create_empty(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	var path: String = ROOT.path_join("fond_blanc.png")
	image.save_png(path)
	var sheet: SheetImport = _import(path)
	assert_int(sheet.errors.size()).is_equal(1)
	assert_str(sheet.errors[0]).contains("sans transparence")
	assert_bool(DirAccess.dir_exists_absolute(ROOT.path_join("peint/fond_blanc"))).is_false()
