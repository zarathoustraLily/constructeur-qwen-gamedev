class_name ObjectPool extends Node
## Une réserve d'objets : au lieu d'instancier une scène à chaque tir et de la libérer ensuite (allocations,
## fragmentation, à-coups), on en prépare d'avance et on les réutilise. Un objet rendu est caché et ne tourne plus ;
## il reste enfant de la réserve, prêt à repartir.

## La scène des objets.
@export var scene: PackedScene
## Combien d'avance, combien au plus.
@export var settings: PoolSettings

var _free: Array[Node] = []
var _active: Array[Node] = []


func _ready() -> void:
	prewarm(settings.prewarm)


## Crée `count` objets d'avance (sans dépasser le maximum), rangés et inactifs.
func prewarm(count: int) -> void:
	for _i: int in mini(count, settings.max_size - total()):
		var node: Node = scene.instantiate()
		add_child(node)
		_sleep(node)
		_free.append(node)


## Un objet prêt à servir : un objet rendu s'il y en a, sinon un nouveau tant que le maximum n'est pas atteint ;
## null au-delà. L'objet est montré et tourne.
func acquire() -> Node:
	var node: Node = null
	if not _free.is_empty():
		node = _free.pop_back()
	elif total() < settings.max_size:
		node = scene.instantiate()
		add_child(node)
	else:
		return null
	_wake(node)
	_active.append(node)
	return node


## Rend `node` à la réserve : caché, arrêté, prêt à resservir. Un objet qui n'est pas en service est ignoré.
func release(node: Node) -> void:
	var index: int = _active.find(node)
	if index < 0:
		return
	_active.remove_at(index)
	_sleep(node)
	_free.append(node)


## Les objets en service.
func active_count() -> int:
	return _active.size()


## Les objets prêts dans la réserve.
func available_count() -> int:
	return _free.size()


## Tous les objets de la réserve, en service ou non.
func total() -> int:
	return _active.size() + _free.size()


func _sleep(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is Node3D:
		(node as Node3D).hide()


func _wake(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node is Node3D:
		(node as Node3D).show()
