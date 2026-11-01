extends SceneTree
## Où tombe le point visé quand le héros tire sans viser, caméra au repos ?

var _scene: Node3D
var _images: int = 0


func _initialize() -> void:
	_scene = (load("res://2_sequence/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_scene)


func _physics_process(_delta: float) -> bool:
	_images += 1
	if _images < 10:
		return false
	var hero: Hero = _scene.get_node("Hero") as Hero
	var bouche: Vector3 = hero.gun.global_position
	var point: Vector3 = hero.aim_point()
	var pente: float = rad_to_deg(asin(bouche.direction_to(point).y))
	print("caméra inclinée de %.1f°" % rad_to_deg(hero.aim_camera.global_rotation.x))
	print("arme à %s, point visé %s, à %.1f m" % [bouche.snappedf(0.01), point.snappedf(0.01), bouche.distance_to(point)])
	print("le tir part avec une pente de %.1f°" % pente)
	_scene.free()
	return true
