class_name WeakListeners extends RefCounted
## Une liste d'objets à prévenir, tenus par des références faibles (weakref) : la liste ne garde pas un objet en vie.
## Un nœud libéré disparaît de la liste au prochain passage, sans erreur sur une instance déjà libérée.

var _refs: Array[WeakRef] = []


## Ajoute `object` (une seule fois).
func add(object: Object) -> void:
	for ref: WeakRef in _refs:
		if ref.get_ref() == object:
			return
	_refs.append(weakref(object))


## Les objets encore en vie, et la liste nettoyée des autres.
func alive() -> Array[Object]:
	var living: Array[Object] = []
	var kept: Array[WeakRef] = []
	for ref: WeakRef in _refs:
		var object: Object = ref.get_ref()
		if object != null and is_instance_valid(object):
			living.append(object)
			kept.append(ref)
	_refs = kept
	return living


## Appelle la méthode `method` sur chaque objet encore en vie ; rend le nombre d'objets prévenus.
func notify(method: StringName) -> int:
	var count: int = 0
	for object: Object in alive():
		if object.has_method(method):
			object.call(method)
			count += 1
	return count
