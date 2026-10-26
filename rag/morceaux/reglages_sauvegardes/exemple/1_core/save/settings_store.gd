class_name SettingsStore
extends RefCounted
## Réglages du joueur (volume, sensibilité) gardés dans un fichier ConfigFile, d'une partie à l'autre. Un fichier
## absent ou illisible redonne les valeurs par défaut. Entrées : load_from(), save_to().

const SECTION := "reglages"

var music_volume: float = 1.0
var sensitivity: float = 1.0


## Lit le fichier ; rend le code d'erreur de ConfigFile.load (OK, ERR_FILE_NOT_FOUND, ERR_PARSE_ERROR…). En cas
## d'erreur, les valeurs par défaut restent.
func load_from(path: String) -> Error:
	var file := ConfigFile.new()
	var error := file.load(path)
	if error != OK:
		return error
	music_volume = file.get_value(SECTION, "music_volume", music_volume)
	sensitivity = file.get_value(SECTION, "sensitivity", sensitivity)
	return OK


func save_to(path: String) -> Error:
	var file := ConfigFile.new()
	file.set_value(SECTION, "music_volume", music_volume)
	file.set_value(SECTION, "sensitivity", sensitivity)
	return file.save(path)
