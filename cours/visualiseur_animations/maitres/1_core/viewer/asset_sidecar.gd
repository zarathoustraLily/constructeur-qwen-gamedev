class_name AssetSidecar extends RefCounted
## Le fichier d'accompagnement d'un asset (AssetEntry.sidecar_path) : ce que le fichier de Blender ou les images ne
## disent pas. Les animations qui bouclent, et la cadence d'un dossier d'images. Un fichier absent n'est pas une
## erreur : rien ne boucle, la cadence est celle par défaut.

## Images par seconde d'un dossier d'images, quand le fichier n'en dit rien.
const DEFAULT_FPS: float = 24.0

## Les animations qui bouclent.
var loops: Array[String] = []
## Images par seconde d'un dossier d'images.
var fps: float = DEFAULT_FPS
## Ce qui n'a pas pu être lu.
var errors: Array[String] = []


## Le fichier d'accompagnement de `entry`, ou un accompagnement vide s'il n'existe pas.
static func load_for(entry: AssetEntry) -> AssetSidecar:
	var path: String = entry.sidecar_path()
	if not FileAccess.file_exists(path):
		return AssetSidecar.new()
	return parse(FileAccess.get_file_as_string(path))


## L'accompagnement écrit dans le texte JSON `text`.
static func parse(text: String) -> AssetSidecar:
	var sidecar: AssetSidecar = AssetSidecar.new()
	var json: JSON = JSON.new()
	if json.parse(text) != OK or not JsonValues.is_object(json.data):
		sidecar.errors.append("accompagnement illisible : un objet JSON est attendu")
		return sidecar
	var data: Dictionary[String, Variant] = JsonValues.object(json.data)
	var loops_value: Variant = data.get("boucles", [])
	if not JsonValues.is_list(loops_value):
		sidecar.errors.append("« boucles » doit être une liste de noms d'animations")
	else:
		for clip: Variant in JsonValues.list(loops_value):
			if typeof(clip) == TYPE_STRING:
				sidecar.loops.append(clip as String)
	var fps_value: Variant = data.get("ips", DEFAULT_FPS)
	if JsonValues.is_number(fps_value) and float(fps_value) > 0.0:
		sidecar.fps = float(fps_value)
	else:
		sidecar.errors.append("« ips » doit être un nombre plus grand que 0")
	return sidecar


## Vrai si l'animation `clip` boucle.
func loops_clip(clip: String) -> bool:
	return loops.has(clip)
