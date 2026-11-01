extends SceneTree
## Un rayon tiré de dehors vers une chaise : que voit-il, selon hit_back_faces ?

var _scene: Node3D
var _images: int = 0


func _initialize() -> void:
	_scene = (load("res://2_sequence/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_scene)


func _physics_process(_delta: float) -> bool:
	_images += 1
	if _images < 3:
		return false
	var chaise: MeshInstance3D = _scene.get_node("Saloon/Meshes/SM_Res_Fur_Chair_Wood_Worn_02_327") as MeshInstance3D
	var boite: AABB = chaise.global_transform * chaise.mesh.get_aabb()
	var centre: Vector3 = boite.get_center()
	var rayon: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			centre + Vector3.RIGHT * boite.size.x, centre, Layers.bit(Layers.WORLD))
	var espace: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var forme: ConcavePolygonShape3D = (_scene.get_node("Saloon/Collision/Shape") as CollisionShape3D).shape as ConcavePolygonShape3D
	print("chaise de x = %.2f à %.2f, rayon venu de la droite ; backface_collision %s" % [boite.position.x, boite.end.x, forme.backface_collision])
	for dos: bool in [true, false]:
		rayon.hit_back_faces = dos
		var impact: Dictionary = espace.intersect_ray(rayon)
		print("hit_back_faces ", dos, " : ", "rien" if impact.is_empty() else "touché à x = %.2f" % (impact["position"] as Vector3).x)
	rayon.from = Vector3(centre.x, 6.0, centre.z)
	rayon.to = Vector3(centre.x, -2.0, centre.z)
	print("rayon vertical : touché à y = %.2f" % (espace.intersect_ray(rayon)["position"] as Vector3).y)
	_scene.free()
	return true
