class_name AssetScanner extends RefCounted
## Cherche les assets dans les dossiers des réglages, sous-dossiers compris. Ce qui compte comme un asset :
## - un modèle 3D : un fichier .glb ou .gltf ;
## - une animation 2D en atlas : un fichier .atlas.json (celui de l'optimiseur de l'éditeur de cartes) ;
## - une animation 2D en images : un dossier d'au moins deux PNG numérotés au même nom (001.png, 002.png… ou
##   feu_01.png, feu_02.png…), sans modèle ni atlas ; ses sous-dossiers ne sont pas fouillés.
## Les dossiers cachés (nom qui commence par un point) sont ignorés. Le résultat est trié par catégorie, dans l'ordre
## de ViewerConfig.CATEGORIES, puis par identifiant : deux recherches sur les mêmes dossiers donnent la même liste.

## Les extensions d'un modèle 3D.
const MODEL_EXTENSIONS: Array[String] = ["glb", "gltf"]
## La fin du nom d'un atlas d'animation.
const ATLAS_SUFFIX: String = ".atlas.json"

## Les assets trouvés, triés.
var entries: Array[AssetEntry] = []
## Les problèmes : dossier introuvable, identifiant en double.
var errors: Array[String] = []

var _numbered: RegEx = RegEx.create_from_string("^(.*?)\\d+\\.png$")
var _ids: Dictionary[String, String] = {}


## Cherche dans chaque dossier de `sources`.
static func scan(sources: Array[AssetSource]) -> AssetScanner:
	var scanner: AssetScanner = AssetScanner.new()
	for source: AssetSource in sources:
		if not DirAccess.dir_exists_absolute(source.folder):
			scanner.errors.append("dossier introuvable : " + source.folder)
			continue
		scanner._scan_folder(source, source.folder)
	scanner.entries.sort_custom(func(a: AssetEntry, b: AssetEntry) -> bool:
		var rank_a: int = ViewerConfig.CATEGORIES.find(a.category)
		var rank_b: int = ViewerConfig.CATEGORIES.find(b.category)
		return a.id < b.id if rank_a == rank_b else rank_a < rank_b)
	return scanner


## Le nombre d'assets de la catégorie `category`.
func count(category: String) -> int:
	var total: int = 0
	for entry: AssetEntry in entries:
		if entry.category == category:
			total += 1
	return total


func _scan_folder(source: AssetSource, folder: String) -> void:
	var files: PackedStringArray = DirAccess.get_files_at(folder)
	var has_asset_file: bool = false
	for file: String in files:
		var lower: String = file.to_lower()
		if lower.ends_with(ATLAS_SUFFIX):
			_add(source, folder.path_join(file), AssetEntry.Kind.ATLAS_2D)
			has_asset_file = true
		elif MODEL_EXTENSIONS.has(lower.get_extension()):
			_add(source, folder.path_join(file), AssetEntry.Kind.MODEL_3D)
			has_asset_file = true
	if not has_asset_file and _is_frame_folder(files):
		_add(source, folder, AssetEntry.Kind.FRAMES_2D)
		return
	for sub: String in DirAccess.get_directories_at(folder):
		if not sub.begins_with("."):
			_scan_folder(source, folder.path_join(sub))


## Vrai si les PNG de `files` sont au moins deux, tous numérotés au même nom.
func _is_frame_folder(files: PackedStringArray) -> bool:
	var prefix: String = ""
	var total: int = 0
	for file: String in files:
		var lower: String = file.to_lower()
		if lower.get_extension() != "png":
			continue
		var found: RegExMatch = _numbered.search(lower)
		if found == null or (total > 0 and found.get_string(1) != prefix):
			return false
		prefix = found.get_string(1)
		total += 1
	return total >= 2


func _add(source: AssetSource, path: String, kind: AssetEntry.Kind) -> void:
	var relative: String = path.trim_prefix(source.folder).trim_prefix("/")
	if relative.is_empty():
		relative = path.get_file()
	if kind == AssetEntry.Kind.ATLAS_2D:
		relative = relative.trim_suffix(ATLAS_SUFFIX)
	elif kind == AssetEntry.Kind.MODEL_3D:
		relative = relative.get_basename()
	var entry: AssetEntry = AssetEntry.new()
	entry.id = source.category + "/" + relative
	entry.display_name = relative.get_file()
	entry.category = source.category
	entry.kind = kind
	entry.path = path
	if _ids.has(entry.id):
		errors.append("identifiant en double : %s (%s et %s)" % [entry.id, _ids[entry.id], path])
		return
	_ids[entry.id] = path
	entries.append(entry)
