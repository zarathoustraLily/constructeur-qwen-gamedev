extends SceneTree
## Un corps tombe entre deux pentes de 70° : Godot le dit-il sur un sol ?

var _corps: CharacterBody3D
var _images: int = 0


func _initialize() -> void:
	for cote: float in [-1.0, 1.0]:
		var pente: StaticBody3D = StaticBody3D.new()
		var forme: CollisionShape3D = CollisionShape3D.new()
		var boite: BoxShape3D = BoxShape3D.new()
		boite.size = Vector3(0.4, 8.0, 8.0)
		forme.shape = boite
		pente.add_child(forme)
		pente.position = Vector3(1.58 * cote, 4.76, 0.0)
		pente.rotation.z = deg_to_rad(-20.0 * cote)
		root.add_child(pente)
	_corps = CharacterBody3D.new()
	var capsule: CollisionShape3D = CollisionShape3D.new()
	var forme_capsule: CapsuleShape3D = CapsuleShape3D.new()
	forme_capsule.radius = 0.35
	forme_capsule.height = 1.8
	capsule.shape = forme_capsule
	capsule.position.y = 0.9
	_corps.add_child(capsule)
	_corps.position = Vector3(0.0, 4.0, 0.0)
	root.add_child(_corps)


func _physics_process(delta: float) -> bool:
	_images += 1
	_corps.velocity.y -= 24.0 * delta
	_corps.move_and_slide()
	if _images == 120:
		print("calé à y = %.2f, sol %s, mur %s, normale du sol %s" % [_corps.global_position.y, _corps.is_on_floor(), _corps.is_on_wall(),
				_corps.get_floor_normal().snappedf(0.01)])
		return true
	return false
