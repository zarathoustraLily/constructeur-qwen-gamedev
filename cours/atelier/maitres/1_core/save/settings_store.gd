class_name SettingsStore extends RefCounted
## Les réglages du joueur sur le disque, dans un ConfigFile (un fichier .cfg lisible, par sections) : le volume de
## chaque bus et le bouton de chaque action remappée. Un fichier absent ou illisible donne des réglages vides : le jeu
## garde alors ses valeurs par défaut.

## La version du format du fichier.
const VERSION: int = 1
## La section des volumes.
const AUDIO: String = "audio"
## La section des boutons de manette.
const PAD: String = "manette"

## Le chemin du fichier (user:// : le dossier de données du joueur).
var path: String = ""


func _init(file_path: String) -> void:
	path = file_path


## Écrit les volumes `volumes` (bus → 0 à 1) et les boutons `bindings` (action → bouton) ; rend le code d'erreur.
func save(volumes: Dictionary[StringName, float], bindings: Dictionary[String, int]) -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("meta", "version", VERSION)
	for bus: StringName in volumes:
		config.set_value(AUDIO, String(bus), volumes[bus])
	for action: String in bindings:
		config.set_value(PAD, action, bindings[action])
	return config.save(path)


## Les volumes enregistrés, bornés entre 0 et 1 ; vide si le fichier manque ou ne se lit pas.
func load_volumes() -> Dictionary[StringName, float]:
	var volumes: Dictionary[StringName, float] = {}
	var config: ConfigFile = _read()
	if config == null or not config.has_section(AUDIO):
		return volumes
	for key: String in config.get_section_keys(AUDIO):
		volumes[StringName(key)] = clampf(float(config.get_value(AUDIO, key, 1.0)), 0.0, 1.0)
	return volumes


## Les boutons enregistrés (action → bouton) ; vide si le fichier manque ou ne se lit pas.
func load_bindings() -> Dictionary[String, int]:
	var bindings: Dictionary[String, int] = {}
	var config: ConfigFile = _read()
	if config == null or not config.has_section(PAD):
		return bindings
	for key: String in config.get_section_keys(PAD):
		bindings[key] = int(config.get_value(PAD, key, 0))
	return bindings


func _read() -> ConfigFile:
	if not FileAccess.file_exists(path):
		return null
	var config: ConfigFile = ConfigFile.new()
	return config if config.load(path) == OK else null
