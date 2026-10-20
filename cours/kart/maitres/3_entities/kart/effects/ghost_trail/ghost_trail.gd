class_name GhostTrail extends Node3D
## Traînée d'images fantômes (d'après le tutoriel « Ghost Trail - Godot 4.4 » de Pixezy) : pendant un turbo,
## une copie figée du kart et du pilote est laissée derrière lui à intervalle régulier. Chaque copie est rendue
## avec un shader de contour lumineux (ghost.gdshader, et son halo en seconde passe) dont la teinte défile en
## arc-en-ciel, puis s'efface. Les copies sont recyclées : aucun nœud n'est créé pendant la course. Elle écoute
## le kart (boost_changed) et ne change jamais son état.


## Une copie du kart.
class Ghost:
	## Racine de la copie, laissée sur place dans le monde.
	var root: Node3D
	## Un maillage par maillage copié.
	var parts: Array[MeshInstance3D] = []
	## Pour chaque maillage animé (le pilote), la copie de son squelette ; sinon null.
	var skeletons: Array[Skeleton3D] = []
	## Matériau propre à la copie : sa couleur et son fondu.
	var material: ShaderMaterial
	## Son halo (seconde passe du matériau), ou null.
	var halo: ShaderMaterial
	## Âge de la copie (s).
	var age: float = 0.0


## Le kart suivi.
@export var kart: Kart
## Nœud dont les maillages sont copiés (le modèle du kart et le pilote).
@export var source: Node3D
## Matériau des fantômes (ghost.gdshader, avec le halo en seconde passe) : chaque fantôme en reçoit une copie.
@export var ghost_material: ShaderMaterial
## Distance parcourue entre deux fantômes (m) : traînée continue même à pleine vitesse.
@export var spawn_spacing: float = 0.4
## Délai maximal entre deux fantômes (s), pour les virages serrés à vitesse réduite.
@export var spawn_interval: float = 0.035
## Durée de vie d'un fantôme (s).
@export var ghost_lifetime: float = 0.6
## Courbe de disparition : 1 linéaire ; plus grand, le fantôme devient transparent plus tôt.
@export var fade_exponent: float = 2.0
## Durée (s) de l'effet à pleine intensité.
@export var full_duration: float = 1.0
## Durée (s) pendant laquelle toute la traînée devient transparente, puis s'arrête.
@export var fade_out_duration: float = 1.0
## Défilement des couleurs (tours de la roue chromatique par seconde).
@export var hue_speed: float = 1.2
## Saturation des couleurs des fantômes.
@export_range(0.0, 1.0) var saturation: float = 0.85
## Pas de fantômes en dessous de cette vitesse (m/s).
@export var min_speed: float = 2.0
## Apparition en fondu (s) : le fantôme qui vient de naître ne recouvre pas le kart.
@export var fade_in_time: float = 0.07
## Fantômes préparés au chargement (évite un à-coup au premier turbo).
@export var prewarm_count: int = 40

var _sources: Array[MeshInstance3D] = []
var _container: Node3D
var _running: bool = false
var _elapsed: float = 0.0
## Opacité de toute la traînée : 1 pendant full_duration, puis jusqu'à 0.
var _effect_strength: float = 0.0
var _spawn_timer: float = 0.0
var _hue: float = 0.0
var _last_spawn_position: Vector3
var _ghosts: Array[Ghost] = []
var _pool: Array[Ghost] = []


## Lance (ou relance) l'effet : full_duration à pleine intensité, puis fade_out_duration de disparition.
func start() -> void:
	_running = true
	_elapsed = 0.0


## Vrai tant que l'effet dure.
func is_running() -> bool:
	return _running


## Nombre de fantômes visibles.
func ghost_count() -> int:
	return _ghosts.size()


func _ready() -> void:
	# Scène ouverte seule, hors d'un kart : rien à copier, la traînée reste éteinte.
	if kart == null or source == null or ghost_material == null:
		set_process(false)
		return
	kart.boost_changed.connect(_on_kart_boost_changed)
	for node: Node in source.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			_sources.append(mesh_instance)
	# Les fantômes restent sur place dans le monde : un conteneur indépendant du kart.
	_container = Node3D.new()
	_container.top_level = true
	add_child(_container)
	for _index: int in prewarm_count:
		var ghost := _create_ghost()
		ghost.root.visible = false
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
		var speed := kart.get_horizontal_velocity().length()
		var moved := source.global_position.distance_to(_last_spawn_position)
		if speed > min_speed and (moved >= spawn_spacing or _spawn_timer <= 0.0):
			_spawn_timer = spawn_interval
			_last_spawn_position = source.global_position
			_spawn_ghost()
	for index: int in range(_ghosts.size() - 1, -1, -1):
		var ghost := _ghosts[index]
		ghost.age += delta
		var life := ghost.age / ghost_lifetime
		if life >= 1.0:
			ghost.root.visible = false
			_pool.append(ghost)
			_ghosts.remove_at(index)
			continue
		# Chaque fantôme s'efface en vieillissant (après une apparition en fondu), et toute la traînée s'efface
		# avec l'opacité de l'effet.
		var fade := pow(1.0 - life, fade_exponent) * smoothstep(0.0, fade_in_time, ghost.age) * _effect_strength
		_set_fade(ghost, fade)


func _on_kart_boost_changed(active: bool) -> void:
	if active:
		start()


func _spawn_ghost() -> void:
	var ghost: Ghost
	if _pool.is_empty():
		ghost = _create_ghost()
	else:
		ghost = _pool.pop_back()
	ghost.age = 0.0
	for index: int in _sources.size():
		var original := _sources[index]
		var part := ghost.parts[index]
		part.visible = original.is_visible_in_tree()
		var skeleton := ghost.skeletons[index]
		if skeleton != null:
			# Pilote animé : on fige sa pose dans la copie de son squelette.
			var original_skeleton := original.get_node(original.skeleton) as Skeleton3D
			skeleton.global_transform = original_skeleton.global_transform
			for bone: int in original_skeleton.get_bone_count():
				skeleton.set_bone_global_pose(bone, original_skeleton.get_bone_global_pose(bone))
			part.transform = original.transform
		else:
			part.global_transform = original.global_transform
	_set_parameter(ghost, &"ghost_color", Color.from_hsv(_hue, saturation, 1.0))
	_set_fade(ghost, 0.0)
	ghost.root.visible = true
	_ghosts.append(ghost)


func _set_fade(ghost: Ghost, fade: float) -> void:
	_set_parameter(ghost, &"ghost_fade", fade)


# Donne `value` au paramètre `parameter` du fantôme et de son halo.
func _set_parameter(ghost: Ghost, parameter: StringName, value: Variant) -> void:
	ghost.material.set_shader_parameter(parameter, value)
	if ghost.halo != null:
		ghost.halo.set_shader_parameter(parameter, value)


func _create_ghost() -> Ghost:
	var ghost := Ghost.new()
	ghost.root = Node3D.new()
	_container.add_child(ghost.root)
	ghost.material = ghost_material.duplicate() as ShaderMaterial
	if ghost_material.next_pass != null:
		ghost.halo = ghost_material.next_pass.duplicate() as ShaderMaterial
		ghost.material.next_pass = ghost.halo
	for original: MeshInstance3D in _sources:
		var part := MeshInstance3D.new()
		part.mesh = original.mesh
		part.material_override = ghost.material
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var original_skeleton: Skeleton3D = null
		if original.skin != null:
			original_skeleton = original.get_node_or_null(original.skeleton) as Skeleton3D
		if original_skeleton != null:
			var skeleton := Skeleton3D.new()
			for bone: int in original_skeleton.get_bone_count():
				skeleton.add_bone(original_skeleton.get_bone_name(bone))
			for bone: int in original_skeleton.get_bone_count():
				skeleton.set_bone_parent(bone, original_skeleton.get_bone_parent(bone))
				skeleton.set_bone_rest(bone, original_skeleton.get_bone_rest(bone))
			ghost.root.add_child(skeleton)
			skeleton.add_child(part)
			part.skin = original.skin
			part.skeleton = NodePath("..")
			ghost.skeletons.append(skeleton)
		else:
			ghost.root.add_child(part)
			ghost.skeletons.append(null)
		ghost.parts.append(part)
	return ghost
