class_name SheetImport
extends RefCounted
## L'import d'une planche peinte dans le catalogue du jeu. Une planche est un PNG à fond transparent où des éléments de
## toutes tailles sont peints, déjà vus par la caméra du jeu. L'import :
## - en trouve les pièces et les range dans des pages d'atlas (`SheetImporter`) ;
## - écrit chaque page en `PortableCompressedTexture2D` (`.res`), compressée pour la mémoire vidéo : Godot la charge telle
##   quelle, sans passer par son propre import, si bien que l'éditeur, lancé comme un jeu, s'en sert aussitôt ;
## - met à jour le catalogue : une pièce = un asset peint en projection (`painted`), à l'échelle commune des planches.
## L'identifiant d'une pièce est stable : la planche `sol_01.png` donne `sol_01_01`, `sol_01_02`… dans l'ordre de lecture,
## et un nouvel import retrouve chaque pièce à son cadre dans la planche (elle garde son identifiant, son calque et sa
## catégorie). Une pièce disparue de la planche quitte le catalogue ; l'import est refusé si une salle s'en sert encore.
## Le catalogue est modifié en mémoire ; c'est à l'appelant de l'enregistrer.

## La part de son cadre qu'une pièce doit partager avec celle d'un import précédent pour en garder l'identifiant.
const SAME_PIECE_OVERLAP: float = 0.5
## Le suffixe du fichier voisin où s'écrit une page avant de remplacer l'ancienne (il garde l'extension `.res`).
const PENDING_SUFFIX: String = ".enregistrement.res"

## Les erreurs du dernier import, une phrase par erreur.
var errors: Array[String] = []
## Les pièces du dernier import, dans l'ordre de lecture de la planche.
var pieces: Array[SheetPiece] = []
## Les identifiants de leurs assets, dans le même ordre.
var asset_ids: Array[StringName] = []
## Les assets retirés du catalogue : leurs pièces ont disparu de la planche.
var removed_ids: Array[StringName] = []
## Les chemins des pages écrites.
var page_paths: PackedStringArray = PackedStringArray()
## La mémoire vidéo de la planche si on la gardait telle quelle (RGBA8, quatre octets par pixel), en octets.
var sheet_bytes: int = 0
## La mémoire vidéo de ses pages, en octets, mesurée sur les textures relues.
var pages_bytes: int = 0
var _settings: EditorSettingsDef


## Prend les réglages (échelle des planches, écart, marge, taille des pages, compression).
func setup(settings: EditorSettingsDef) -> void:
	_settings = settings


## Importe la planche `sheet_path` (un PNG à fond transparent) dans `catalog` ; ses pages vont dans
## `pages_dir/<identifiant de la planche>/`. `used_assets` : les assets dont se servent les salles du projet. Rend vrai
## si les pages sont écrites et le catalogue mis à jour ; sinon rien n'est écrit (les raisons sont dans `errors`).
func import_sheet(sheet_path: String, catalog: AssetCatalogDef, pages_dir: String,
		used_assets: PackedStringArray) -> bool:
	_reset()
	var image: Image = _read(sheet_path)
	if image == null:
		return false
	var sheet_id: StringName = StringName(sheet_path.get_file().get_basename().to_snake_case())
	pieces = SheetImporter.find_pieces(image, _settings.sheet_merge_gap_px, _settings.sheet_min_area_px)
	if pieces.is_empty():
		errors.append("%s : aucune pièce (rien que de la transparence)" % sheet_path.get_file())
		return false
	var page_sizes: Array[Vector2i] = SheetImporter.pack(pieces, _settings.sheet_padding_px,
			_settings.sheet_page_max_px)
	if page_sizes.is_empty():
		errors.append("%s : une pièce dépasse une page de %d pixels" % [sheet_path.get_file(),
				_settings.sheet_page_max_px])
		return false
	var previous: Array[AssetDef] = []
	for asset: AssetDef in catalog.assets:
		if asset.source_sheet == sheet_id:
			previous.append(asset)
	asset_ids = _match(previous, sheet_id)
	for asset: AssetDef in previous:
		if not asset_ids.has(asset.id):
			removed_ids.append(asset.id)
			if used_assets.has(String(asset.id)):
				errors.append("%s : la pièce a disparu de la planche, mais une salle s'en sert" % asset.id)
	if not errors.is_empty():
		return false
	var textures: Array[Texture2D] = _write_pages(SheetImporter.build_pages(image, pieces, page_sizes),
			pages_dir.path_join(String(sheet_id)))
	if textures.is_empty():
		return false
	sheet_bytes = image.get_width() * image.get_height() * 4
	_apply(catalog, sheet_id, previous, textures)
	return true


func _reset() -> void:
	errors.clear()
	pieces.clear()
	asset_ids.clear()
	removed_ids.clear()
	page_paths = PackedStringArray()
	sheet_bytes = 0
	pages_bytes = 0


# La planche `sheet_path`, ou null. Elle se lit comme un fichier, pas comme une ressource : les planches restent hors de
# l'import de Godot (dans un dossier qui porte un `.gdignore`, ou hors du projet).
func _read(sheet_path: String) -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(sheet_path))
	if image == null or image.is_empty():
		errors.append("%s : planche illisible" % sheet_path)
		return null
	if image.detect_alpha() == Image.ALPHA_NONE:
		errors.append("%s : planche sans transparence (un fond plein ferait une seule pièce)" % sheet_path.get_file())
		return null
	return image


# L'identifiant de chaque pièce, dans l'ordre : celui de la pièce d'un import précédent (`previous`) dont le cadre
# recouvre le sien au moins pour moitié, sinon un numéro neuf, après le plus grand déjà donné.
func _match(previous: Array[AssetDef], sheet_id: StringName) -> Array[StringName]:
	var prefix: String = String(sheet_id) + "_"
	var next_number: int = 1
	for asset: AssetDef in previous:
		next_number = maxi(next_number, String(asset.id).trim_prefix(prefix).to_int() + 1)
	var ids: Array[StringName] = []
	var taken: Dictionary[StringName, bool] = {}
	for piece: SheetPiece in pieces:
		var best: AssetDef = null
		var best_overlap: float = SAME_PIECE_OVERLAP
		for asset: AssetDef in previous:
			var overlap: float = _overlap(asset.source_rect, piece.source_rect)
			if not taken.has(asset.id) and overlap >= best_overlap:
				best = asset
				best_overlap = overlap
		if best == null:
			ids.append(StringName("%s%02d" % [prefix, next_number]))
			next_number += 1
		else:
			ids.append(best.id)
			taken[best.id] = true
	return ids


# La part commune de deux cadres : la surface de leur intersection sur celle de leur union.
func _overlap(a: Rect2i, b: Rect2i) -> float:
	var common: Rect2i = a.intersection(b)
	var shared: int = common.get_area() if a.intersects(b) else 0
	var union_area: int = a.get_area() + b.get_area() - shared
	return 0.0 if union_area <= 0 else float(shared) / float(union_area)


# Écrit les pages dans `folder` (`page_0.res`, `page_1.res`…), chacune d'un coup, puis les relit ; rend les textures
# relues, ou une liste vide en cas d'échec. Les pages d'un import précédent en surnombre sont effacées.
func _write_pages(pages: Array[Image], folder: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var status: Error = DirAccess.make_dir_recursive_absolute(folder)
	if status != OK:
		errors.append("%s : dossier impossible à créer (%s)" % [folder, error_string(status)])
		return textures
	var mode: PortableCompressedTexture2D.CompressionMode = PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS
	if _settings.sheet_vram_compression:
		mode = PortableCompressedTexture2D.COMPRESSION_MODE_BPTC
	for index: int in pages.size():
		var path: String = folder.path_join("page_%d.res" % index)
		var texture: PortableCompressedTexture2D = PortableCompressedTexture2D.new()
		# Hors de l'éditeur de Godot, une telle texture oublie ses données compressées une fois données à la carte : sans
		# ce drapeau, la page enregistrée ne pèse que quelques centaines d'octets et se relit vide (0 × 0).
		texture.keep_compressed_buffer = true
		texture.create_from_image(pages[index], mode)
		var pending: String = folder.path_join("." + path.get_file().get_basename() + PENDING_SUFFIX)
		status = ResourceSaver.save(texture, pending)
		if status == OK:
			status = DirAccess.rename_absolute(pending, path)
		if status != OK:
			DirAccess.remove_absolute(pending)
			errors.append("%s : page non enregistrée (%s)" % [path, error_string(status)])
			textures.clear()
			return textures
		# Relue en remplaçant celle du cache : les assets qui la citent déjà voient la nouvelle.
		var written: Texture2D = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as Texture2D
		textures.append(written)
		page_paths.append(path)
		pages_bytes += written.get_image().get_data_size()
	var extra: int = pages.size()
	while FileAccess.file_exists(folder.path_join("page_%d.res" % extra)):
		DirAccess.remove_absolute(folder.path_join("page_%d.res" % extra))
		extra += 1
	return textures


# Met le catalogue à jour : les assets des pièces (neufs ou retrouvés), sans ceux des pièces disparues.
func _apply(catalog: AssetCatalogDef, sheet_id: StringName, previous: Array[AssetDef],
		textures: Array[Texture2D]) -> void:
	var found: Dictionary[StringName, AssetDef] = {}
	for asset: AssetDef in previous:
		found[asset.id] = asset
	var kept: Array[AssetDef] = []
	for asset: AssetDef in catalog.assets:
		if not removed_ids.has(asset.id):
			kept.append(asset)
	for index: int in pieces.size():
		var piece: SheetPiece = pieces[index]
		var asset: AssetDef = found.get(asset_ids[index])
		if asset == null:
			asset = AssetDef.new()
			asset.id = asset_ids[index]
			asset.category = _settings.sheet_category
			asset.default_layer = _settings.sheet_layer
			asset.tags = PackedStringArray([String(sheet_id)])
			kept.append(asset)
		asset.atlas = textures[piece.page]
		asset.region = Rect2i(piece.page_position, piece.source_rect.size)
		asset.size_m = Vector2(piece.source_rect.size) / _settings.painted_pixels_per_meter
		asset.painted = true
		asset.source_sheet = sheet_id
		asset.source_rect = piece.source_rect
	catalog.assets = kept
