class_name ResourceCache extends RefCounted
## Un cache de ressources : la première demande charge la ressource (ResourceLoader.load), les suivantes rendent la
## même instance sans relire le disque. Il compte ses succès et ses échecs, et se vide d'un coup (changement de
## niveau) pour que les ressources qui ne servent plus soient libérées.

## Les demandes servies par le cache.
var hits: int = 0
## Les demandes qui ont dû charger.
var misses: int = 0

var _resources: Dictionary[String, Resource] = {}


## La ressource de `path`, chargée une seule fois ; null si elle n'existe pas (rien n'est gardé alors).
func fetch(path: String) -> Resource:
	if _resources.has(path):
		hits += 1
		return _resources[path]
	misses += 1
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = ResourceLoader.load(path)
	_resources[path] = resource
	return resource


## Vrai si `path` est déjà dans le cache.
func has(path: String) -> bool:
	return _resources.has(path)


## Le nombre de ressources gardées.
func size() -> int:
	return _resources.size()


## Oublie toutes les ressources : celles que plus rien ne tient seront libérées.
func clear() -> void:
	_resources.clear()
