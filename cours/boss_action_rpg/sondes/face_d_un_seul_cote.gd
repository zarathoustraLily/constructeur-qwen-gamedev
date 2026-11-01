extends SceneTree
## Une forme concave arrête-t-elle un corps des deux côtés de ses faces ?

var _corps: CharacterBody3D
var _images: int = 0


func _initialize() -> void:
	var a: Vector3 = Vector3(-5.0, 0.0, -5.0)
	var b: Vector3 = Vector3(5.0, 0.0, -5.0)
	var c: Vector3 = Vector3(0.0, 0.0, 5.0)
	print("normale de Plane(a, b, c) : ", Plane(a, b, c).normal)
	var forme: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	forme.set_faces(PackedVector3Array([a, b, c]))
	var noeud: CollisionShape3D = CollisionShape3D.new()
	noeud.shape = forme
	var sol: StaticBody3D = StaticBody3D.new()
	sol.add_child(noeud)
	root.add_child(sol)
	_corps = CharacterBody3D.new()
	var capsule: CollisionShape3D = CollisionShape3D.new()
	capsule.shape = CapsuleShape3D.new()
	_corps.add_child(capsule)
	root.add_child(_corps)


func _physics_process(_delta: float) -> bool:
	_images += 1
	if _images < 3:
		return false
	_corps.global_position = Vector3(0.0, 2.0, 0.0)
	print("descend d'au-dessus : arrêté ", _corps.test_move(_corps.global_transform, Vector3.DOWN * 3.0))
	_corps.global_position = Vector3(0.0, -2.0, 0.0)
	print("monte d'en dessous : arrêté ", _corps.test_move(_corps.global_transform, Vector3.UP * 3.0))
	return true
