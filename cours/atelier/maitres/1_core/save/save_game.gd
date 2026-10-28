class_name SaveGame extends RefCounted
## La sauvegarde d'une partie en JSON : un numéro de version et l'état. Une sauvegarde d'une version plus ancienne est
## migrée ; une sauvegarde illisible, d'une version inconnue ou plus récente, est refusée (état vide) plutôt que de
## charger n'importe quoi. En JSON, tout nombre revient en flottant (3 se relit 3.0) : convertir avec int() à l'usage.

## La version actuelle du format.
const VERSION: int = 2


## Le texte JSON de l'état `state`, avec sa version.
static func encode(state: Dictionary) -> String:
	return JSON.stringify({"version": VERSION, "state": state}, "\t")


## L'état lu dans `text`, migré au besoin ; vide si le texte n'est pas une sauvegarde lisible de ce jeu.
static func decode(text: String) -> Dictionary:
	# Une instance de JSON rend un code d'erreur sans rien écrire dans la sortie (JSON.parse_string, lui, écrit une
	# ERROR pour un texte illisible).
	var json: JSON = JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return {}
	var data: Dictionary = migrate(json.data as Dictionary)
	if int(data.get("version", -1)) != VERSION or not data.get("state") is Dictionary:
		return {}
	return data["state"]


## Une sauvegarde de la version 1 ({"version": 1, "hp": …, "level": …}) au format de la version 2
## ({"version": 2, "state": {"health": …, "level": …}}) ; les autres versions passent telles quelles.
static func migrate(data: Dictionary) -> Dictionary:
	if int(data.get("version", -1)) != 1:
		return data
	var state: Dictionary = {}
	for key: String in data:
		if key != "version":
			state["health" if key == "hp" else key] = data[key]
	return {"version": 2, "state": state}


## Écrit l'état `state` dans le fichier `path` ; rend le code d'erreur.
static func write(path: String, state: Dictionary) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(encode(state))
	file.close()
	return OK


## L'état lu dans le fichier `path` ; vide s'il manque ou ne se lit pas.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return decode(FileAccess.get_file_as_string(path))
