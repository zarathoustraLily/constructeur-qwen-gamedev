class_name HeroView extends Node3D
## La vue du héros : le soldat animé. Elle ne décide rien ; elle montre ce que fait le héros. Elle écoute sa machine à
## états (Move, Roll, Hit, Heal, Dead) et ses tirs, lit sa vitesse et sa visée, et pilote l'arbre d'animation du
## modèle :
## - un nœud de transition, une entrée par état ; la roulade et le soin durent ce que durent leurs états ;
## - dans la course, un mélange par la vitesse au sol (attente, course, sprint), fondu vers la marche visée (quatre
##   directions) quand il vise ; chaque boucle joue à la vitesse du corps, pour que les pieds ne glissent pas ;
## - par-dessus, le recul d'un tir, sur le haut du corps seulement : les jambes gardent la course.
## Elle porte aussi la bouche de l'arme (Gun) à celle du fusil que tient le modèle, chaque fois que le squelette a fini
## sa pose : les tirs partent du canon visible. Le fusil pointe droit devant ; la main gauche le tient par une IK
## (LeftHandIK du modèle), que la vue active en course et au tir, et relâche dans les autres états (roulade, coup, soin,
## chute : la main gauche suit alors l'animation).

## L'état du héros → l'entrée du nœud de transition qui le montre.
const STATES: Dictionary[StringName, StringName] = {
	&"Move": &"move", &"Roll": &"roll", &"Hit": &"hit", &"Heal": &"heal", &"Dead": &"dead",
}

## Le héros montré : sa vitesse, sa visée, ses réglages.
@export var hero: Hero
## Sa machine à états : la vue montre l'état actif.
@export var machine: StateMachine
## Son arme : chaque tir joue le recul ; sa bouche suit celle du fusil.
@export var gun: HeroGun
## Vitesses de foulée des clips, fondus.
@export var settings: HeroViewSettings

## Le poids de la marche visée dans la course (0 : course, 1 : marche visée).
var aim_weight: float = 0.0
## Les nœuds des clips de marche, par nom : leur ligne de temps règle leur vitesse.
var clip_nodes: Dictionary[StringName, AnimationNodeAnimation] = {}

## Le soldat : squelette reciblé, fusil, bibliothèque d'animations.
@onready var model: Node3D = $Model
## L'arbre d'animation, construit au démarrage.
@onready var tree: AnimationTree = $AnimationTree
## La bouche du fusil que tient le modèle.
@onready var muzzle: Node3D = model.get_node(^"%Muzzle")
## L'IK qui pose la main gauche sur le garde-main.
@onready var left_hand_ik: SkeletonModifier3D = model.get_node(^"%LeftHandIK")

var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _hand: int = -1
var _hand_to_muzzle: Transform3D = Transform3D.IDENTITY


func _ready() -> void:
	process_physics_priority = ProcessOrder.VIEWS
	_player = model.get_node(^"AnimationPlayer") as AnimationPlayer
	_skeleton = model.get_node(^"%GeneralSkeleton") as Skeleton3D
	_hand = _skeleton.find_bone("RightHand")
	_hand_to_muzzle = (muzzle.get_parent() as Node3D).transform * muzzle.transform
	_skeleton.skeleton_updated.connect(follow_muzzle)
	tree.root_node = tree.get_path_to(model)
	tree.anim_player = tree.get_path_to(_player)
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	tree.tree_root = build_tree()
	tree.active = true
	machine.state_changed.connect(_on_state_changed)
	gun.fired.connect(_on_fired)
	show_state(machine.current.name)


func _physics_process(delta: float) -> void:
	update(delta)


## Avance de `delta` secondes : la vitesse au sol et la visée passent à l'arbre ; la main gauche rejoint le garde-main
## en course (Move) et le lâche ailleurs, en un fondu d'état.
func update(delta: float) -> void:
	var local: Vector3 = hero.global_basis.inverse() * hero.velocity
	var ground: Vector2 = Vector2(local.x, -local.z)
	tree.set(&"parameters/locomotion/blend_position", ground.length())
	tree.set(&"parameters/strafe/blend_position", (ground / hero.settings.aim_speed).limit_length(1.0))
	aim_weight = move_toward(aim_weight, 1.0 if hero.aiming else 0.0, delta / settings.aim_blend_time)
	tree.set(&"parameters/aim/blend_amount", aim_weight)
	var grip: float = 1.0 if machine.current.name == &"Move" else 0.0
	left_hand_ik.influence = move_toward(left_hand_ik.influence, grip, delta / settings.state_blend_time)


## Porte la bouche de l'arme à celle du fusil, calculée depuis l'os de la main droite : le squelette vient de finir sa
## pose (pendant la physique, l'os garde encore la pose de l'image précédente).
func follow_muzzle() -> void:
	gun.global_position = (_skeleton.global_transform * _skeleton.get_bone_global_pose(_hand) * _hand_to_muzzle).origin


## Montre l'état `state_name` du héros (rien pour un état sans animation).
func show_state(state_name: StringName) -> void:
	if STATES.has(state_name):
		tree.set(&"parameters/state/transition_request", String(STATES[state_name]))


## L'arbre : transition entre les états ; la course (vitesse au sol, fondue vers la marche visée) sous le recul des
## tirs ; la roulade et le soin étirés sur la durée de leurs états ; le coup et la chute à leur vitesse.
func build_tree() -> AnimationNodeBlendTree:
	var root: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
	var locomotion: AnimationNodeBlendSpace1D = AnimationNodeBlendSpace1D.new()
	locomotion.max_space = hero.settings.sprint_speed
	locomotion.add_blend_point(_clip(&"idle"), 0.0, -1, &"idle")
	locomotion.add_blend_point(_paced(&"run", settings.run_clip_speed, hero.settings.run_speed), hero.settings.run_speed,
			-1, &"run")
	locomotion.add_blend_point(_paced(&"sprint", settings.sprint_clip_speed, hero.settings.sprint_speed),
			hero.settings.sprint_speed, -1, &"sprint")
	root.add_node(&"locomotion", locomotion)
	var strafe: AnimationNodeBlendSpace2D = AnimationNodeBlendSpace2D.new()
	strafe.add_blend_point(_clip(&"aim_idle"), Vector2.ZERO, -1, &"aim_idle")
	var directions: Dictionary[StringName, Vector2] = {
		&"aim_walk_f": Vector2(0.0, 1.0), &"aim_walk_b": Vector2(0.0, -1.0),
		&"aim_walk_l": Vector2(-1.0, 0.0), &"aim_walk_r": Vector2(1.0, 0.0),
	}
	for clip: StringName in directions:
		strafe.add_blend_point(_paced(clip, settings.aim_walk_clip_speed, hero.settings.aim_speed), directions[clip], -1,
				clip)
	root.add_node(&"strafe", strafe)
	root.add_node(&"aim", AnimationNodeBlend2.new())
	root.connect_node(&"aim", 0, &"locomotion")
	root.connect_node(&"aim", 1, &"strafe")

	var fire: AnimationNodeOneShot = AnimationNodeOneShot.new()
	fire.fadein_time = settings.fire_fade_in
	fire.fadeout_time = settings.fire_fade_out
	fire.filter_enabled = true
	for bone: String in _upper_body():
		fire.set_filter_path(NodePath("%GeneralSkeleton:" + bone), true)
	root.add_node(&"fire", fire)
	root.add_node(&"fire_clip", _clip(&"fire"))
	root.connect_node(&"fire", 0, &"aim")
	root.connect_node(&"fire", 1, &"fire_clip")

	var state: AnimationNodeTransition = AnimationNodeTransition.new()
	state.xfade_time = settings.state_blend_time
	root.add_node(&"state", state)
	var inputs: Dictionary[StringName, StringName] = {
		&"move": &"fire", &"roll": &"roll", &"hit": &"hit", &"heal": &"heal", &"dead": &"dead",
	}
	root.add_node(&"roll", _timed(&"roll", hero.settings.roll_duration))
	root.add_node(&"hit", _clip(&"hit"))
	root.add_node(&"heal", _timed(&"heal", hero.settings.heal_duration))
	root.add_node(&"dead", _clip(&"death"))
	var index: int = 0
	for input: StringName in inputs:
		state.add_input(String(input))
		root.connect_node(&"state", index, inputs[input])
		index += 1
	root.connect_node(&"output", 0, &"state")
	return root


func _clip(clip: StringName) -> AnimationNodeAnimation:
	var node: AnimationNodeAnimation = AnimationNodeAnimation.new()
	node.animation = clip
	return node


## Une boucle de marche jouée à la vitesse du corps : sa ligne de temps est étirée de `clip_speed` à `body_speed`.
func _paced(clip: StringName, clip_speed: float, body_speed: float) -> AnimationNodeAnimation:
	var node: AnimationNodeAnimation = _timed(clip, _player.get_animation(clip).length * clip_speed / body_speed)
	node.loop_mode = Animation.LOOP_LINEAR
	clip_nodes[clip] = node
	return node


## Un clip étiré pour durer `duration` secondes.
func _timed(clip: StringName, duration: float) -> AnimationNodeAnimation:
	var node: AnimationNodeAnimation = _clip(clip)
	node.use_custom_timeline = true
	node.stretch_time_scale = true
	node.timeline_length = duration
	return node


## Les os du haut du corps : l'os Spine et tout ce qui en descend (buste, tête, bras, mains).
func _upper_body() -> PackedStringArray:
	var skeleton: Skeleton3D = model.get_node(^"%GeneralSkeleton") as Skeleton3D
	var spine: int = skeleton.find_bone("Spine")
	var bones: PackedStringArray = PackedStringArray()
	for bone: int in skeleton.get_bone_count():
		var parent: int = bone
		while parent >= 0 and parent != spine:
			parent = skeleton.get_bone_parent(parent)
		if parent == spine:
			bones.append(skeleton.get_bone_name(bone))
	return bones


func _on_state_changed(_from: StringName, to: StringName) -> void:
	show_state(to)


func _on_fired(_origin: Vector3, _direction: Vector3) -> void:
	tree.set(&"parameters/fire/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
