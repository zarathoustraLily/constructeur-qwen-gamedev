class_name ViewerConfig extends RefCounted
## Les réglages du visualiseur, lus dans un fichier JSON qu'on modifie à la main : les dossiers où chercher les assets,
## chacun avec sa catégorie.
#@ 2+
## Aussi : combien de pixels d'une image 2D font un mètre dans le jeu.
#@ 3+
## Aussi : la caméra du jeu (inclinaison, rotation, hauteur vue), pour voir un asset comme en partie.
#@ all
## Un problème de lecture ne s'ignore pas : il est rangé dans `errors`, une phrase par problème, et le reste du fichier
## est lu quand même. Un fichier sans dossier n'est pas une erreur : la liste sera vide.

## Les catégories reconnues, dans l'ordre d'affichage de la liste.
const CATEGORIES: Array[String] = ["heros", "ennemi", "boss", "prop", "effet"]
#@ 2+
## Pixels par mètre d'une image 2D, quand les réglages n'en disent rien.
const DEFAULT_PIXELS_PER_METER: float = 100.0
#@ all

## Les dossiers d'assets, dans l'ordre du fichier.
var sources: Array[AssetSource] = []
#@ 2+
## Combien de pixels d'une image 2D font un mètre.
var pixels_per_meter: float = DEFAULT_PIXELS_PER_METER
#@ 3+
## L'inclinaison de la caméra du jeu, en degrés au-dessus de l'horizon.
var game_pitch_deg: float = 30.0
## La rotation de la caméra du jeu autour de la verticale, en degrés (0 : elle regarde le sujet de face).
var game_yaw_deg: float = 45.0
## La hauteur que voit la caméra orthographique du jeu, en mètres.
var game_ortho_size: float = 8.0
#@ all
## Ce qui n'a pas pu être lu, une phrase par problème.
var errors: Array[String] = []


## Les réglages du fichier `path` ; un fichier absent est une erreur.
static func load_file(path: String) -> ViewerConfig:
	if not FileAccess.file_exists(path):
		var missing: ViewerConfig = ViewerConfig.new()
		missing.errors.append("réglages introuvables : " + path)
		return missing
	return parse(FileAccess.get_file_as_string(path))


## Les réglages écrits dans le texte JSON `text`.
static func parse(text: String) -> ViewerConfig:
	var config: ViewerConfig = ViewerConfig.new()
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		# JSON.get_error_line compte à partir de 0 ; un éditeur de texte, à partir de 1.
		config.errors.append("JSON invalide, ligne %d : %s" % [json.get_error_line() + 1, json.get_error_message()])
		return config
	if not JsonValues.is_object(json.data):
		config.errors.append("les réglages doivent être un objet JSON")
		return config
	var data: Dictionary[String, Variant] = JsonValues.object(json.data)
	config._read_sources(data.get("sources", []))
#@ 2+
	config.pixels_per_meter = config._positive(data, "pixels_par_metre", DEFAULT_PIXELS_PER_METER)
#@ 3+
	var game: Variant = data.get("vue_jeu", {})
	if not JsonValues.is_object(game):
		config.errors.append("« vue_jeu » doit être un objet")
	else:
		var view: Dictionary[String, Variant] = JsonValues.object(game)
		config.game_pitch_deg = config._number(view, "inclinaison", config.game_pitch_deg)
		if config.game_pitch_deg <= 0.0 or config.game_pitch_deg > 90.0:
			config.errors.append("« vue_jeu.inclinaison » doit être entre 0 (exclu) et 90 degrés")
			config.game_pitch_deg = 30.0
		config.game_yaw_deg = config._number(view, "rotation", config.game_yaw_deg)
		config.game_ortho_size = config._positive(view, "taille", config.game_ortho_size)
#@ all
	return config


func _read_sources(list: Variant) -> void:
	if not JsonValues.is_list(list):
		errors.append("« sources » doit être une liste")
		return
	var items: Array[Variant] = JsonValues.list(list)
	for i: int in items.size():
		if not JsonValues.is_object(items[i]):
			errors.append("source %d : un objet {dossier, categorie} est attendu" % (i + 1))
			continue
		var item: Dictionary[String, Variant] = JsonValues.object(items[i])
		var folder: Variant = item.get("dossier", "")
		var category: Variant = item.get("categorie", "")
		if typeof(folder) != TYPE_STRING or (folder as String).is_empty():
			errors.append("source %d : « dossier » manque" % (i + 1))
			continue
		if typeof(category) != TYPE_STRING or not CATEGORIES.has(category as String):
			errors.append("source %d : catégorie « %s » inconnue (attendu : %s)"
					% [i + 1, str(category), ", ".join(CATEGORIES)])
			continue
		sources.append(AssetSource.new(folder as String, category as String))
#@ 2+


func _number(data: Dictionary[String, Variant], key: String, fallback: float) -> float:
	if not data.has(key):
		return fallback
	var value: Variant = data[key]
	if not JsonValues.is_number(value):
		errors.append("« %s » doit être un nombre" % key)
		return fallback
	return float(value)


func _positive(data: Dictionary[String, Variant], key: String, fallback: float) -> float:
	var value: float = _number(data, key, fallback)
	if value <= 0.0:
		errors.append("« %s » doit être plus grand que 0" % key)
		return fallback
	return value
#@ all
