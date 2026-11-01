class_name SolidProp extends MeshInstance3D
## Un objet du décor, agrandi à volonté : il se donne une boîte de collision à sa taille. Le corps n'hérite pas de son
## échelle : une forme de collision à l'échelle non uniforme se comporte mal. Il prend sa rotation et sa position, et la
## boîte reçoit la taille agrandie.


func _ready() -> void:
	var size: Vector3 = global_basis.get_scale()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = mesh.get_aabb().size * size
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.shape = box
	shape.position = mesh.get_aabb().get_center() * size
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = Layers.bit(Layers.WORLD)
	body.collision_mask = 0
	body.top_level = true
	body.add_child(shape)
	add_child(body)
	body.global_transform = Transform3D(global_basis.orthonormalized(), global_position)
