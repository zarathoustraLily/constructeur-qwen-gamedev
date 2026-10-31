extends SceneTree
## Mesure le rendu, fenêtre ouverte (hors de l'écran) : le niveau à l'entrée, le héros immobile qui regarde le golem ;
## après l'échauffement, la carte graphique mesure le temps de rendu de chaque image (RenderingServer : temps processeur
## et carte graphique du rendu de la fenêtre), en médiane ; et le moteur compte, à la dernière image, les appels de
## dessin, les primitives et la mémoire vidéo. Une image enregistrée à la fin. Le temps de la carte dépend de ce qui
## tourne à côté sur elle : comparer deux réglages, lancés l'un après l'autre, plutôt que lire un nombre seul.
## Résultat : une ligne « @@RENDU@@<json> ».
##   godot --path <projet> --resolution 1280x720 --position -6000,-6000 -s res://7_tests/perf/mesurer_rendu.gd --
##       <échauffement> <images> <image.png> [--qualite=basse]
#@ 19+
## Avec `--tir` : le héros, à l'entrée, tire sans arrêt sur le golem figé, l'arme toujours froide, le golem soigné à chaque
## image (la seconde phase ne vient pas changer la scène) : la mesure voit alors les effets des tirs, au plus fort.
#@ 20+
## Avec `--magie` : la seconde phase, spectres compris, et le Gardien enchaîne boules de feu et éclairs sans récupérer, le
## héros invulnérable à l'entrée : la mesure voit alors les sorts, au plus fort.
#@ all

const MARQUEUR: String = "@@RENDU@@"

var _echauffement: int = 120
var _images: int = 120
var _chemin: String = ""
var _scene: Node3D
var _image: int = 0
var _gpu: PackedFloat64Array = PackedFloat64Array()
var _cpu: PackedFloat64Array = PackedFloat64Array()
#@ 19+
var _tir: bool = false
var _hero: Hero
var _golem: Golem
#@ 20+
var _magie: bool = false
var _sort: int = 0
#@ all


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_echauffement = int(args[0])
	_images = int(args[1])
	_chemin = args[2]
#@ 19+
	_tir = "--tir" in args
#@ 20+
	_magie = "--magie" in args
#@ all
	_gpu.resize(_images)
	_cpu.resize(_images)
	_scene = (load("res://2_sequence/main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_scene)
	current_scene = _scene
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)


func _process(_delta: float) -> bool:
	_image += 1
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _image == 2:
		(_scene.get_node("Hero/Input") as Node).free()
		(_scene.get_node("OrbitCamera/Input") as Node).free()
#@ 19+
		if _tir:
			_preparer_le_tir()
	if _tir and _image > 2:
		_hero.trigger = true
		_hero.gun.heat.heat = 0.0
		_golem.health.heal(_golem.health.settings.max_health)
#@ 20+
	if _image == 2 and _magie:
		_preparer_la_magie()
	if _magie and _image > 2:
		_hero.invulnerable = true
		if _golem.machine.current.name != &"Attack":
			_lancer_un_sort()
#@ all
	var rid: RID = root.get_viewport_rid()
	if _image > _echauffement and _image <= _echauffement + _images:
		var i: int = _image - _echauffement - 1
		_gpu[i] = RenderingServer.viewport_get_measured_render_time_gpu(rid)
		_cpu[i] = RenderingServer.viewport_get_measured_render_time_cpu(rid)
	if _image == _echauffement + _images:
		root.get_texture().get_image().save_png(_chemin)
		var reglage: GraphicsQualityApplier = _scene.get_node("GraphicsQuality") as GraphicsQualityApplier
		print(MARQUEUR + JSON.stringify({
			"qualite": String(reglage.current.id),
			"taille": [root.size.x, root.size.y],
			"gpu_ms_mediane": _mediane(_gpu),
			"cpu_rendu_ms_mediane": _mediane(_cpu),
			"appels_de_dessin": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
			"objets_dessines": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
			"memoire_video_mo": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		}))
		return true
	return false


#@ 19+
func _preparer_le_tir() -> void:
	_hero = _scene.get_node("Hero") as Hero
	_golem = _scene.get_node("Golem") as Golem
	_golem.machine.process_mode = Node.PROCESS_MODE_DISABLED
	_hero.invulnerable = true
	var orbit: OrbitCamera = _scene.get_node("OrbitCamera") as OrbitCamera
	orbit.yaw = PI
	orbit.apply_rotation()


#@ 20+
func _preparer_la_magie() -> void:
	_hero = _scene.get_node("Hero") as Hero
	_golem = _scene.get_node("Golem") as Golem
	var orbit: OrbitCamera = _scene.get_node("OrbitCamera") as OrbitCamera
	orbit.yaw = PI
	orbit.apply_rotation()
	_golem.wake_up()
	_golem.enter_phase_two()


func _lancer_un_sort() -> void:
	_sort = (_sort + 1) % 2
	var voulu: StringName = &"fireball" if _sort == 1 else &"lightning"
	for attaque: GolemAttack in _golem.settings.attacks:
		if attaque.id == voulu:
			_golem.attack = attaque
	_golem.rotation.y = Motion.yaw_of(_hero.global_position - _golem.global_position)
	_golem.machine.transition_to(&"Attack")


#@ all
func _mediane(valeurs: PackedFloat64Array) -> float:
	var t: PackedFloat64Array = valeurs.duplicate()
	t.sort()
	return t[floori(t.size() * 0.5)]
