extends SceneTree
## Le héros reste immobile ; les spectres sont appelés (le golem figé ou non, selon l'argument) : chaque coup reçu est
## tracé avec son image, sa source et les dégâts faits.

var _scene: Node3D
var _hero: Hero
var _frame: int = 0
var _golem_actif: bool = false


func _initialize() -> void:
	_golem_actif = "golem" in OS.get_cmdline_user_args()
	_scene = (load("res://2_sequence/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_scene)
	current_scene = _scene


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_hero = _scene.get_node("Hero") as Hero
		_hero.get_node("Input").free()
		var golem: Golem = _scene.get_node("Golem") as Golem
		if not _golem_actif:
			golem.machine.process_mode = Node.PROCESS_MODE_DISABLED
		for s: Spectre in _scene.get_node("Spectres").get_children():
			s.hitbox.landed.connect(_on_landed.bind(s.name))
		for h: Node in golem.find_children("*", "Hitbox", true, false):
			(h as Hitbox).landed.connect(_on_landed.bind("Golem/" + h.name))
		(_hero.get_node("Health") as HealthComponent).damaged.connect(_on_damaged)
		_hero.machine.state_changed.connect(func(a: StringName, b: StringName) -> void:
			print("%5d  état %s -> %s" % [_frame, a, b]))
		var appel: SpectreCall = _scene.get_node("SpectreCall") as SpectreCall
		appel.has_called = true
		appel.tick(0.0)
	return _frame >= 60 * 25 or (_hero != null and _hero.health.is_dead() and _frame % 60 == 0)


func _on_landed(_body: Node3D, dealt: float, source: String) -> void:
	print("%5d  coup de %s : %.1f" % [_frame, source, dealt])


func _on_damaged(amount: float, remaining: float) -> void:
	print("%5d  santé -%.1f -> %.1f" % [_frame, amount, remaining])
