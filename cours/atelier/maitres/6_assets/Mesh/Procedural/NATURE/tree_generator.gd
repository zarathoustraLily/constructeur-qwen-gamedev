@tool
class_name TreeGenerator extends Node3D
## Le générateur d'arbre : il construit le bois (un maillage) et les feuilles (un MultiMesh) d'après ses réglages,
## à l'ouverture de la scène et à chaque changement de réglages, dans l'éditeur aussi.

## Les réglages de l'arbre ; les changer reconstruit l'arbre.
@export var settings: TreeSettings:
	set(value):
		settings = value
		if is_inside_tree():
			rebuild()


func _ready() -> void:
	rebuild()


## Reconstruit l'arbre : retire l'ancien bois et les anciennes feuilles, puis pose les nouveaux.
func rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	if settings == null:
		return
	var segments: Array[TreeBuilder.Segment] = TreeBuilder.grow(settings)
	var wood: MeshInstance3D = MeshInstance3D.new()
	wood.name = "Wood"
	wood.mesh = TreeBuilder.wood_mesh(segments)
	add_child(wood)
	var leaf: QuadMesh = QuadMesh.new()
	leaf.size = Vector2(0.4, 0.4)
	var transforms: Array[Transform3D] = []
	for point: Vector3 in TreeBuilder.leaf_positions(segments, settings):
		transforms.append(Transform3D(Basis.IDENTITY, point))
	var leaves: MultiMeshInstance3D = MultiMeshInstance3D.new()
	leaves.name = "Leaves"
	leaves.multimesh = Scatter.multimesh(leaf, transforms)
	add_child(leaves)
