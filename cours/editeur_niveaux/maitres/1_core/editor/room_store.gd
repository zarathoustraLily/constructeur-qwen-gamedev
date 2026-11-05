class_name RoomStore
extends RefCounted
## Lit et écrit les salles (`RoomData`) sur le disque.
## La lecture rend une copie privée : l'éditeur la modifie sans toucher la ressource que le cache de Godot partage avec
## tout le projet. L'écriture passe par `StableSaver` : la salle est d'abord validée, puis enregistrée dans un fichier
## voisin, qui ne remplace l'ancien qu'une fois complet ; en cas d'échec, l'ancien fichier reste intact. Seul le
## dossier des salles peut recevoir une écriture, sous un nom simple.

## Les erreurs de la dernière opération, une phrase par erreur.
var errors: Array[String] = []
var _root: String = ""
var _saver: StableSaver = StableSaver.new()


## Choisit le dossier où les salles s'écrivent : celui des salles du jeu, que donne la coquille (le cœur ne connaît
## pas les dossiers de données), ou celui d'un test.
func setup(root: String) -> void:
	_root = root.simplify_path()


## Le chemin de la salle `filename` dans le dossier des salles.
func path_of(filename: String) -> String:
	return _root.path_join(filename)


## Lit la salle `path` ; rend une copie privée et valide, ou null (les raisons sont dans `errors`).
func load_room(path: String) -> RoomData:
	errors.clear()
	if not ResourceLoader.exists(path):
		errors.append("Salle introuvable : " + path)
		return null
	var room: RoomData = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as RoomData
	if room == null:
		errors.append("Ce fichier n'est pas une salle : " + path)
		return null
	errors.assign(room.validate())
	return room if errors.is_empty() else null


## Enregistre `room` sous `filename` (un nom simple en .tres) dans le dossier des salles ; true si le fichier a été
## remplacé.
func save_room(room: RoomData, filename: String) -> bool:
	errors.clear()
	if room == null:
		errors.append("Aucune salle à enregistrer")
		return false
	errors.assign(room.validate())
	if not errors.is_empty():
		return false
	if not filename.is_valid_filename() or filename.get_extension() != "tres" \
			or filename.ends_with(StableSaver.PENDING_SUFFIX):
		errors.append("Destination refusée : un nom simple en .tres est requis")
		return false
	if DirAccess.make_dir_recursive_absolute(_root) != OK:
		errors.append("Dossier des salles impossible à créer : " + _root)
		return false
	var status: Error = _saver.save(room, path_of(filename))
	if status != OK:
		errors.append("Écriture impossible (%s) : %s" % [error_string(status), path_of(filename)])
		return false
	return true
