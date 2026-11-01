extends SceneTree
## Le héros court vers une chaise et saute : son état, sa hauteur, ses vitesses, toutes les 30 images.

var _scene: Node3D
var _hero: Hero
var _images: int = 0


func _initialize() -> void:
	_scene = (load("res://2_sequence/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_scene)


func _physics_process(_delta: float) -> bool:
	_images += 1
	if _images == 2:
		_hero = _scene.get_node("Hero") as Hero
		_hero.get_node("Input").free()
		(_scene.get_node("Golem") as Golem).machine.process_mode = Node.PROCESS_MODE_DISABLED
		_hero.camera = null
		_hero.global_position = Vector3(-3.3, 0.05, -11.37)
		_hero.stick = Vector2.LEFT
	if _images == 40:
		_hero.jump_buffer.press()
	if _images % 30 == 0:
		print("%3d %s y %.2f vitesse %.1f réelle %.1f sol %s" % [_images, _hero.machine.current.name, _hero.global_position.y,
				_hero.velocity.length(), _hero.get_real_velocity().length(), _hero.is_on_floor()])
	if _images >= 180:
		_scene.free()
		return true
	return false
