class_name StableSaver
extends RefCounted
## Enregistre une ressource en texte (`.tres`), de façon atomique et stable.
## Atomique : la ressource s'écrit d'abord dans un fichier voisin, qui ne remplace la cible qu'une fois complet.
## Stable : deux enregistrements de la même ressource donnent les mêmes octets. Hors de l'éditeur de Godot, l'éditeur
## de niveaux étant lancé comme un jeu, `ResourceSaver` tire au hasard l'identifiant de chaque ressource externe
## (`id="1_8umkc"`), et `Resource.set_id_for_path`, qui le garderait, « n'est implémentée que dans le contexte de
## l'éditeur » (référence de la classe Resource, 4.7.2). On renomme donc ces identifiants dans leur ordre d'apparition :
## `1_ext`, `2_ext`… Sans cela, chaque enregistrement changerait le fichier, même sans aucune modification.

## Le suffixe du fichier voisin, le temps de l'écriture (il garde l'extension `.tres` : `ResourceSaver` choisit son
## format d'après l'extension).
const PENDING_SUFFIX: String = ".enregistrement.tres"

var _declaration: RegEx = RegEx.create_from_string("\\[ext_resource [^\\]]*\\bid=\"([^\"]+)\"")


## Enregistre `resource` dans `target` ; rend OK, ou l'erreur rencontrée (la cible reste alors intacte).
func save(resource: Resource, target: String) -> Error:
	var pending: String = target.get_base_dir().path_join("." + target.get_file().get_basename() + PENDING_SUFFIX)
	var status: Error = ResourceSaver.save(resource, pending)
	if status == OK:
		status = _stabilize(pending)
	if status == OK:
		status = DirAccess.rename_absolute(pending, target)
	if status != OK:
		DirAccess.remove_absolute(pending)
	return status


## Le texte `text` d'une ressource, ses identifiants de ressources externes renommés dans leur ordre d'apparition.
func stable_text(text: String) -> String:
	var result: String = text
	var rank: int = 0
	for found: RegExMatch in _declaration.search_all(text):
		rank += 1
		var old_id: String = found.get_string(1)
		var new_id: String = "%d_ext" % rank
		result = result.replace("id=\"%s\"]" % old_id, "id=\"%s\"]" % new_id)
		result = result.replace("ExtResource(\"%s\")" % old_id, "ExtResource(\"%s\")" % new_id)
	return result


func _stabilize(path: String) -> Error:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return FileAccess.get_open_error()
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(stable_text(text))
	var status: Error = file.get_error()
	file.close()
	return status
