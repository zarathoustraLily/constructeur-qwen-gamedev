class_name SaveSystem extends RefCounted
## Lit et écrit les sauvegardes, un fichier JSON par emplacement (`SavesDef`). Chaque fichier porte la version de son
## format : un fichier d'une autre version, ou illisible, n'est jamais chargé, et l'écran le dit. L'écriture est
## atomique : on écrit d'abord un fichier temporaire à côté, puis on le renomme à la place de l'ancien. Si le jeu
## s'arrête au milieu, l'ancienne sauvegarde reste entière.

## L'état d'un emplacement.
enum SlotState {
	EMPTY, ## aucun fichier
	VALID, ## une sauvegarde de la bonne version
	UNREADABLE, ## un fichier qui n'est pas une sauvegarde
	OTHER_VERSION, ## une sauvegarde d'une autre version du format
}

const _KEYS: Array[String] = ["version", "graine", "temps_s", "salle", "date"]
const _TEMPORARY: String = ".tmp"

var _saves: SavesDef = null


## Un système de sauvegarde réglé par `saves`.
func _init(saves: SavesDef) -> void:
	_saves = saves


## Le chemin du fichier de l'emplacement `slot` (compté à partir de 0).
func path_of(slot: int) -> String:
	return _saves.directory.path_join(_saves.file_pattern % (slot + 1))


## L'état de l'emplacement `slot`.
func state_of(slot: int) -> SlotState:
	var path: String = path_of(slot)
	if not FileAccess.file_exists(path):
		return SlotState.EMPTY
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not (parser.data is Dictionary):
		return SlotState.UNREADABLE
	var data: Dictionary = parser.data
	for key: String in _KEYS:
		if not data.has(key):
			return SlotState.UNREADABLE
	if int(data["version"]) != _saves.version:
		return SlotState.OTHER_VERSION
	return SlotState.VALID


## La sauvegarde de l'emplacement `slot` ; vide si elle n'est pas `VALID`.
func read(slot: int) -> Dictionary:
	if state_of(slot) != SlotState.VALID:
		return {}
	var parser := JSON.new()
	parser.parse(FileAccess.get_file_as_string(path_of(slot)))
	return parser.data


## Écrit `data` dans l'emplacement `slot`, avec la version du format, de façon atomique.
func write(slot: int, data: Dictionary) -> Error:
	var made: Error = DirAccess.make_dir_recursive_absolute(_saves.directory)
	if made != OK:
		return made
	var content: Dictionary = data.duplicate()
	content["version"] = _saves.version
	var temporary: String = path_of(slot) + _TEMPORARY
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(content, "\t"))
	file.close()
	return DirAccess.rename_absolute(temporary, path_of(slot))


## Commence une partie neuve dans l'emplacement `slot`, avec la graine `seed_value`.
func new_game(slot: int, seed_value: int) -> Error:
	return write(slot, {"graine": seed_value, "temps_s": 0.0, "salle": _saves.start_room,
			"date": Time.get_datetime_string_from_system(false, true)})


## Efface l'emplacement `slot`.
func erase(slot: int) -> Error:
	if not FileAccess.file_exists(path_of(slot)):
		return OK
	return DirAccess.remove_absolute(path_of(slot))
