class_name GhostTrail extends Node3D

## Traînée d'images fantômes (« ghost trail », d'après le tutoriel « Ghost Trail - Godot 4.4 » de Pixezy) :
## pendant un boost, une copie figée du kart et du pilote est laissée derrière lui à intervalle régulier.
## Chaque copie est rendue avec un shader fresnel (ghost.gdshader) dont la teinte défile en
## arc-en-ciel, puis s'efface. Les copies sont recyclées pour ne pas créer de nœuds en continu.

## Nœud dont les maillages sont copiés (kart + pilote). Par défaut : ../Visual
@export var source : Node3D
## Matériau des fantômes (ghost.gdshader).
@export var ghost_material : Material
## Distance parcourue entre deux fantômes (m) : traînée continue même à pleine vitesse
@export var spawn_spacing : float = 0.4
## Délai maximal entre deux fantômes (s), pour les virages serrés à vitesse réduite
@export var spawn_interval : float = 0.035
## Durée de vie d'un fantôme (s)
@export var ghost_lifetime : float = 0.6
## Courbe de disparition : 1 = linéaire, plus grand = devient transparent plus tôt
@export var fade_exponent : float = 2.0
## Durée (s) de l'effet à pleine intensité
@export var full_duration : float = 1.0
## Durée (s) pendant laquelle toute la traînée devient progressivement transparente, puis s'arrête
@export var fade_out_duration : float = 1.0
## Défilement des couleurs (tours de la roue chromatique par seconde)
@export var hue_speed : float = 1.2
## Saturation des couleurs des fantômes.
@export_range(0.0, 1.0) var saturation : float = 0.85
## Pas de fantômes en dessous de cette vitesse (m/s)
@export var min_speed : float = 2.0
## Apparition en fondu (s) : le fantôme qui vient de naître ne recouvre pas le kart
@export var fade_in_time : float = 0.07
## Fantômes préparés au chargement (évite un à-coup au premier boost)
@export var prewarm_count : int = 40

var _kart : Kart
var _sources : Array[MeshInstance3D] = []
var _container : Node3D
var _running : bool = false
var _elapsed : float = 0.0
## Opacité globale de la traînée : 1 pendant full_duration, puis descend jusqu'à 0
var _effect_strength : float = 0.0
var _spawn_timer : float = 0.0
var _hue : float = 0.0
var _last_spawn_position : Vector3
var _ghosts : Array[Dictionary] = []
var _pool : Array[Dictionary] = []

## Lance (ou relance) l'effet : full_duration à pleine intensité, puis fade_out_duration de disparition.
func start() -> void:
	_running = true
	_elapsed = 0.0

func _ready() -> void:
	_kart = get_parent() as Kart
	if not source:
		source = get_parent().get_node_or_null("Visual")
	# Scène ouverte seule, hors d'un kart : rien à copier, la traînée reste éteinte.
	if not source:
		set_process(false)
		return
	for node in source.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh:
			_sources.append(mi)
	# Les fantômes restent sur place dans le monde : conteneur indépendant du kart
	_container = Node3D.new()
	_container.top_level = true
	add_child(_container)
	for i in prewarm_count:
		var ghost := _create_ghost()
		(ghost.root as Node3D).visible = false
		_pool.append(ghost)

func _process(delta: float) -> void:
	if _running:
		_elapsed += delta
		if _elapsed >= full_duration + fade_out_duration:
			_running = false
		_effect_strength = 1.0 - clampf((_elapsed - full_duration) / maxf(fade_out_duration, 0.001), 0.0, 1.0)
	else:
		_effect_strength = 0.0

	if _running:
		_hue = fposmod(_hue + delta * hue_speed, 1.0)
		_spawn_timer -= delta
		var speed := _kart.get_horizontal_velocity().length() if _kart else INF
		var moved := source.global_position.distance_to(_last_spawn_position)
		if speed > min_speed and (moved >= spawn_spacing or _spawn_timer <= 0.0):
			_spawn_timer = spawn_interval
			_last_spawn_position = source.global_position
			_spawn_ghost()

	for i in range(_ghosts.size() - 1, -1, -1):
		var ghost := _ghosts[i]
		ghost.age += delta
		var t : float = ghost.age / ghost_lifetime
		if t >= 1.0:
			(ghost.root as Node3D).visible = false
			_pool.append(ghost)
			_ghosts.remove_at(i)
			continue
		# Chaque fantôme s'efface en vieillissant (après une apparition en fondu),
		# et toute la traînée s'efface avec l'opacité globale de l'effet
		var fade := pow(1.0 - t, fade_exponent) * smoothstep(0.0, fade_in_time, ghost.age) * _effect_strength
		for part: Variant in ghost.parts:
			(part as MeshInstance3D).set_instance_shader_parameter("ghost_fade", fade)

func _spawn_ghost() -> void:
	var ghost : Dictionary = _pool.pop_back() if not _pool.is_empty() else _create_ghost()
	ghost.age = 0.0
	var color := Color.from_hsv(_hue, saturation, 1.0)
	for i in _sources.size():
		var src := _sources[i]
		var part : MeshInstance3D = ghost.parts[i]
		part.visible = src.is_visible_in_tree()
		var skeleton : Skeleton3D = ghost.skeletons[i]
		if skeleton:
			# Pilote animé : on fige la pose actuelle du squelette dans une copie de celui-ci
			var src_skeleton := src.get_node(src.skeleton) as Skeleton3D
			skeleton.global_transform = src_skeleton.global_transform
			for bone in src_skeleton.get_bone_count():
				skeleton.set_bone_global_pose(bone, src_skeleton.get_bone_global_pose(bone))
			part.transform = src.transform
		else:
			part.global_transform = src.global_transform
		part.set_instance_shader_parameter("ghost_color", color)
		part.set_instance_shader_parameter("ghost_fade", 0.0)
	(ghost.root as Node3D).visible = true
	_ghosts.append(ghost)

func _create_ghost() -> Dictionary:
	var root := Node3D.new()
	_container.add_child(root)
	var parts : Array[MeshInstance3D] = []
	var skeletons : Array[Skeleton3D] = []
	for src in _sources:
		var part := MeshInstance3D.new()
		part.mesh = src.mesh
		part.material_override = ghost_material
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var src_skeleton : Skeleton3D = null
		if src.skin:
			src_skeleton = src.get_node_or_null(src.skeleton) as Skeleton3D
		if src_skeleton:
			var skeleton := Skeleton3D.new()
			for bone in src_skeleton.get_bone_count():
				skeleton.add_bone(src_skeleton.get_bone_name(bone))
			for bone in src_skeleton.get_bone_count():
				skeleton.set_bone_parent(bone, src_skeleton.get_bone_parent(bone))
				skeleton.set_bone_rest(bone, src_skeleton.get_bone_rest(bone))
			root.add_child(skeleton)
			skeleton.add_child(part)
			part.skin = src.skin
			part.skeleton = NodePath("..")
			skeletons.append(skeleton)
		else:
			root.add_child(part)
			skeletons.append(null)
		parts.append(part)
	return {"root": root, "parts": parts, "skeletons": skeletons, "age": 0.0}
