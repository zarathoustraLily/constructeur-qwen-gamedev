class_name DrawOrder
extends RefCounted
## L'ordre de dessin des choses d'une salle : d'abord par calque (dans l'ordre de `layers`, du sol vers l'avant-plan),
## puis par rang dans le calque (`sort`), puis par identifiant, pour qu'à rang égal l'ordre ne dépende pas de la
## place des choses dans les tableaux. La même règle sert à la vue de l'éditeur et au jeu.


## Les identifiants des choses de `document`, du premier dessiné (dessous) au dernier (dessus).
static func sorted(document: RoomDocument, layers: PackedStringArray) -> PackedInt32Array:
	var keys: Array[Vector3i] = []
	var ids: PackedInt32Array = document.ids()
	var layer_column: PackedStringArray = document.column(&"layer")
	var sort_column: PackedInt32Array = document.column(&"sort")
	for index: int in ids.size():
		keys.append(Vector3i(layers.find(layer_column[index]), sort_column[index], ids[index]))
	keys.sort()
	var result: PackedInt32Array = PackedInt32Array()
	for key: Vector3i in keys:
		result.append(key.z)
	return result
