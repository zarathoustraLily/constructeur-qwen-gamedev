class_name SelectionModel
extends RefCounted
## La sélection de l'éditeur : des identifiants de choses, jamais des indices ni des nœuds. Un indice change dès qu'on
## supprime une chose ; un nœud disparaît quand la vue se redessine ; l'identifiant, lui, reste. Les vues et les panneaux
## s'abonnent à `changed` : la sélection est un modèle, que chacun montre à sa façon.

## La sélection vient de changer.
signal changed

var _ids: Array[int] = []


## Les identifiants sélectionnés, dans l'ordre où on les a choisis (une copie).
func ids() -> Array[int]:
	return _ids.duplicate()


## Vrai si la chose `thing_id` est sélectionnée.
func contains(thing_id: int) -> bool:
	return _ids.has(thing_id)


## Vrai si rien n'est sélectionné.
func is_empty() -> bool:
	return _ids.is_empty()


## Remplace la sélection par `values` (doublons et identifiants nuls ou négatifs retirés).
func replace(values: Array[int]) -> void:
	var next: Array[int] = []
	for thing_id: int in values:
		if thing_id > 0 and not next.has(thing_id):
			next.append(thing_id)
	if next == _ids:
		return
	_ids = next
	changed.emit()


## Ajoute `thing_id` à la sélection.
func add(thing_id: int) -> void:
	var next: Array[int] = ids()
	next.append(thing_id)
	replace(next)


## Retire `thing_id` de la sélection.
func remove(thing_id: int) -> void:
	var next: Array[int] = ids()
	next.erase(thing_id)
	replace(next)


## Ajoute `thing_id` s'il n'y est pas, le retire sinon (clic avec Maj).
func toggle(thing_id: int) -> void:
	if contains(thing_id):
		remove(thing_id)
	else:
		add(thing_id)


## Vide la sélection.
func clear() -> void:
	replace([])


## Ne garde que les identifiants encore présents dans `available` (après une suppression ou une annulation).
func retain(available: PackedInt32Array) -> void:
	var next: Array[int] = []
	for thing_id: int in _ids:
		if available.has(thing_id):
			next.append(thing_id)
	replace(next)
