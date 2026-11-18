class_name SpriteSet extends RefCounted
## Les animations 2D d'un asset et les pages d'images qu'elles partagent, ou l'erreur qui a empêché de les lire.

## Les pages d'images, dans l'ordre du fichier ; SpriteFrame.page en est l'indice.
var pages: Array[Texture2D] = []
## Les animations, par nom.
var animations: Dictionary[String, SpriteAnimation] = {}
## Le mélange : « normal », ou « additif » pour une lumière sur fond noir.
var blend: String = "normal"
## L'erreur de lecture, vide si tout va bien.
var error: String = ""


## Les noms des animations, triés.
func clips() -> Array[String]:
	var names: Array[String] = []
	names.assign(animations.keys())
	names.sort()
	return names
