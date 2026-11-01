extends SceneTree
## Un rayon voit-il une Area3D qui ne surveille rien (monitoring faux) ?

var _zone: Area3D
var _images: int = 0


func _initialize() -> void:
	_zone = Area3D.new()
	_zone.monitoring = false
	var forme: CollisionShape3D = CollisionShape3D.new()
	forme.shape = SphereShape3D.new()
	_zone.add_child(forme)
	root.add_child(_zone)


func _physics_process(_delta: float) -> bool:
	_images += 1
	if _images < 3:
		return false
	var rayon: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(0.0, 5.0, 0.0), Vector3(0.0, -5.0, 0.0))
	var espace: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	rayon.collide_with_areas = true
	print("monitoring ", _zone.monitoring, ", collide_with_areas vrai : touché ", not espace.intersect_ray(rayon).is_empty())
	rayon.collide_with_areas = false
	print("monitoring ", _zone.monitoring, ", collide_with_areas faux : touché ", not espace.intersect_ray(rayon).is_empty())
	return true
