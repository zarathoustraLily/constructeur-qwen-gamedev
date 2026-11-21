class_name GameSettings extends RefCounted
## Les réglages choisis par le joueur : difficulté, définition, plein écran, volume de chaque bus. Ils s'enregistrent
## dans un `ConfigFile` (texte lisible) et se relisent en se corrigeant : une valeur inconnue ou hors bornes, venue
## d'un fichier ancien ou modifié à la main, reprend sa valeur par défaut ; un fichier absent ou illisible donne les
## valeurs par défaut. Le jeu ne plante jamais sur ses options.

const _SECTION_GAME: String = "jeu"
const _SECTION_DISPLAY: String = "ecran"
const _SECTION_AUDIO: String = "son"

## La difficulté.
var difficulty: StringName = &""
## La définition de la fenêtre, en pixels.
var resolution: Vector2i = Vector2i.ZERO
## Le plein écran.
var fullscreen: bool = false
## Le volume de chaque bus, de 0 à 1.
var volumes: Dictionary[StringName, float] = {}


## Les réglages par défaut de `options`.
static func defaults(options: OptionsDef) -> GameSettings:
	var settings := GameSettings.new()
	settings.difficulty = options.default_difficulty
	settings.resolution = options.default_resolution
	settings.fullscreen = options.default_fullscreen
	for bus: StringName in options.volume_buses:
		settings.volumes[bus] = options.default_volume
	return settings


## Les réglages enregistrés dans le fichier de `options`, corrigés ; ceux par défaut si le fichier manque ou est
## illisible.
static func load_from(options: OptionsDef) -> GameSettings:
	var settings := defaults(options)
	var file := ConfigFile.new()
	if not FileAccess.file_exists(options.file_path) or file.load(options.file_path) != OK:
		return settings
	var difficulty_read: Variant = file.get_value(_SECTION_GAME, "difficulte", settings.difficulty)
	if difficulty_read is StringName and options.difficulties.has(difficulty_read):
		settings.difficulty = difficulty_read
	var resolution_read: Variant = file.get_value(_SECTION_DISPLAY, "definition", settings.resolution)
	if resolution_read is Vector2i and options.resolutions.has(resolution_read):
		settings.resolution = resolution_read
	var fullscreen_read: Variant = file.get_value(_SECTION_DISPLAY, "plein_ecran", settings.fullscreen)
	if fullscreen_read is bool:
		settings.fullscreen = fullscreen_read
	for bus: StringName in options.volume_buses:
		var volume_read: Variant = file.get_value(_SECTION_AUDIO, String(bus), settings.volumes[bus])
		if volume_read is float:
			settings.volumes[bus] = clampf(volume_read, 0.0, 1.0)
	return settings


## Enregistre les réglages dans le fichier de `options` ; rend le code d'erreur de Godot (OK si tout va bien).
func save_to(options: OptionsDef) -> Error:
	var file := ConfigFile.new()
	file.set_value(_SECTION_GAME, "difficulte", difficulty)
	file.set_value(_SECTION_DISPLAY, "definition", resolution)
	file.set_value(_SECTION_DISPLAY, "plein_ecran", fullscreen)
	for bus: StringName in volumes:
		file.set_value(_SECTION_AUDIO, String(bus), volumes[bus])
	return file.save(options.file_path)
