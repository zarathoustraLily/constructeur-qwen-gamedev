class_name BackgroundLoader extends RefCounted
## Charge des ressources en fond, sur les fils de Godot (`ResourceLoader.load_threaded_request`), pendant que l'écran
## montre autre chose. On lui donne une liste de chemins ; il dit où il en est (de 0 à 1), quand tout est là, et ce
## qui n'a pas pu être chargé. Un chemin qui n'existe pas n'est pas demandé : il compte tout de suite comme un échec.

var _requested: Array[String] = []
var _progress: Dictionary[String, float] = {}
var _loaded: Dictionary[String, Resource] = {}
var _failed: Array[String] = []


## Demande le chargement de `paths`.
func start(paths: Array[String]) -> void:
	for path: String in paths:
		if not ResourceLoader.exists(path) or ResourceLoader.load_threaded_request(path) != OK:
			_failed.append(path)
			continue
		_requested.append(path)
		_progress[path] = 0.0


## Relit l'état de chaque chargement demandé ; à appeler à chaque image.
func poll() -> void:
	for path: String in _requested:
		if _is_finished(path):
			continue
		var progress_out: Array = []
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, progress_out)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_loaded[path] = ResourceLoader.load_threaded_get(path)
			_progress[path] = 1.0
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not progress_out.is_empty():
				_progress[path] = float(progress_out[0])
		else:
			_failed.append(path)
			_progress[path] = 1.0


## Où en est l'ensemble, de 0 à 1 : un échec compte comme fini ; 1 quand il n'y a rien à charger.
func progress() -> float:
	var missing: int = _failed.size() - _failed_requested()
	var total: int = _requested.size() + missing
	if total == 0:
		return 1.0
	var sum: float = missing
	for path: String in _requested:
		sum += _progress[path]
	return sum / total


## Vrai quand chaque chemin demandé est chargé ou a échoué.
func is_done() -> bool:
	for path: String in _requested:
		if not _is_finished(path):
			return false
	return true


## Reprend les chargements encore en cours (en attendant leur fin) : une demande jamais reprise reste dans le
## chargeur de Godot, et ses ressources fuient à la sortie du jeu. À appeler quand on abandonne le chargement.
func release() -> void:
	for path: String in _requested:
		if not _is_finished(path):
			_loaded[path] = ResourceLoader.load_threaded_get(path)
			_progress[path] = 1.0


## Les chemins qui n'ont pas pu être chargés.
func failed() -> Array[String]:
	return _failed.duplicate()


## La ressource chargée à `path`, ou null.
func get_resource(path: String) -> Resource:
	return _loaded.get(path, null)


func _is_finished(path: String) -> bool:
	return _loaded.has(path) or _failed.has(path)


func _failed_requested() -> int:
	var count: int = 0
	for path: String in _failed:
		if _requested.has(path):
			count += 1
	return count
