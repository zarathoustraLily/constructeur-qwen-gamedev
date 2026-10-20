class_name QuadTree3DView extends Node3D
## Maillage de la surface de l'océan découpé en arbre quaternaire, avec niveaux de détail (CDLOD) :
## près de la caméra, chaque carré se divise en quatre carrés plus fins ; loin, un seul carré grossier
## suffit. La racine choisit une image sur deux les maillages affichés, avec une transition (geomorph)
## entre deux niveaux. C'est une présentation : elle ne décide que de ce qui est dessiné (règle ARC-02).


## Niveau de détail de ce carré : il a lod_level niveaux de sous-carrés sous lui.
@export_range(0, 1000000, 1) var lod_level := 2

## Côté (m) de ce carré.
@export_range(1.0, 65535.0) var quad_size := 1024.0

## Part de la plage d'un niveau où le maillage se transforme vers le niveau voisin (geomorph CDLOD).
@export_range(0.0, 1.0, 0.001) var morph_range := 0.15

## Nombre de sommets par côté du maillage de chaque carré.
@export_range(0, 32000, 1) var mesh_vertex_resolution := 256

## Distance (m) de chaque niveau de détail : ranges[lod_level].
@export var ranges:Array[float] = [512.0, 1024.0, 2048.0]

## Matériau de la surface, donné à chaque carré.
@export var material:ShaderMaterial

## Surface montrée à la place des carrés quand la houle ne peut pas être calculée : sans RenderingDevice (rendu
## de compatibilité, ou sans fenêtre), pas de shaders de calcul.
@export var fallback: Node3D


## Scène de l'arbre, chargée par la racine pour créer les sous-carrés. Elle ne peut pas être préchargée
## (preload) : la scène se contiendrait elle-même (https://github.com/godotengine/godot/issues/70985).
var quad_scene: PackedScene

## Vrai pour la racine de l'arbre : elle construit tous les sous-carrés à son entrée dans l'arbre.
var is_root_quad := true

## Vrai : le choix des niveaux de détail est figé dans son état.
var pause_cull := false

## Boîte qui enferme ce carré, pour le test de distance.
var cull_box:AABB

## Maillages de chaque niveau de détail, partagés par tous les carrés d'un même niveau.
var lod_meshes:Array[PlaneMesh] = []

## Le maillage affiché de ce carré.
var mesh_instance:MeshInstance3D

var _visibility_detector:VisibleOnScreenNotifier3D
var _subquads: Array[QuadTree3DView] = []


func _ready() -> void:
	var subquad_node: Node3D
	# Scène ouverte seule : sans le matériau que lui donne l'océan, il n'y a rien à construire.
	if material == null:
		set_process(false)
		return
	# Sans RenderingDevice, la houle ne tourne pas : la surface de repli prend sa place, et aucun carré n'est
	# construit (en compatibilité, leurs paramètres d'instance dépasseraient la réserve du moteur de rendu).
	if is_root_quad and RenderingServer.get_rendering_device() == null:
		if fallback != null:
			fallback.visible = true
		set_process(false)
		return

	if is_root_quad:
		quad_scene = load("res://1_core/water/fft/quad_tree_3d_view.tscn")
		
		## Distance de vue maximale et début du fondu
		var camera := get_viewport().get_camera_3d()
		# Sans caméra (scène de test, par exemple) : la distance de vue garde la valeur du matériau.
		if camera:
			material.set_shader_parameter("view_distance_max", camera.far)
		material.set_shader_parameter("vertex_resolution", mesh_vertex_resolution)
		
		## Un maillage par niveau de détail
		var current_size: float = quad_size
		
		for _level: int in range(lod_level + 1):
			var mesh := PlaneMesh.new()
			mesh.size = Vector2.ONE * current_size
			mesh.subdivide_depth = mesh_vertex_resolution - 1
			mesh.subdivide_width = mesh_vertex_resolution - 1
			
			lod_meshes.insert(0, mesh)
			current_size *= 0.5
		
		mesh_instance = MeshInstance3D.new()
		subquad_node = Node3D.new()
		_visibility_detector = VisibleOnScreenNotifier3D.new()
		
		add_child(subquad_node)
		add_child(mesh_instance)
		add_child(_visibility_detector)
	
	else:
		mesh_instance = $MeshInstance3D
		subquad_node = $SubQuads
		_visibility_detector = $VisibleOnScreenNotifier3D
	
	var offset_length:float = quad_size * 0.25
	
	mesh_instance.visible = false
	mesh_instance.mesh = lod_meshes[lod_level]
	mesh_instance.material_override = material
	mesh_instance.set_instance_shader_parameter("patch_size", quad_size)
	mesh_instance.set_instance_shader_parameter("min_lod_morph_distance", ranges[lod_level] * 2 * (1.0 - morph_range))
	mesh_instance.set_instance_shader_parameter("max_lod_morph_distance", ranges[lod_level] * 2)
	
	_visibility_detector.aabb = AABB(Vector3(-quad_size * 0.75, -quad_size * 0.5, -quad_size * 0.75),
			Vector3(quad_size * 1.5, quad_size, quad_size * 1.5))
	mesh_instance.custom_aabb = _visibility_detector.aabb
	cull_box = AABB(global_position + Vector3(-quad_size * 0.5, -10, -quad_size * 0.5),
			Vector3(quad_size, 20, quad_size))
	
	## Hors du niveau le plus fin, quatre sous-carrés plus détaillés.
	if lod_level > 0:
		for offset: Vector3 in [Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, -1)]:
			var new_quad := quad_scene.instantiate() as QuadTree3DView
			new_quad.lod_level = lod_level - 1
			new_quad.quad_size = quad_size * 0.5
			new_quad.ranges = ranges
			new_quad.process_mode = PROCESS_MODE_DISABLED
			new_quad.position = offset * offset_length
			new_quad.morph_range = morph_range
			new_quad.quad_scene = quad_scene
			new_quad.lod_meshes = lod_meshes
			new_quad.is_root_quad = false
			new_quad.material = material
			
			subquad_node.add_child(new_quad)
			_subquads.append(new_quad)


## Les sous-carrés sont désactivés (PROCESS_MODE_DISABLED) : seule la racine passe ici ; elle choisit
## les niveaux une image sur deux.
func _process(_delta:float) -> void:
	if not pause_cull and Engine.get_frames_drawn() % 2:
		var camera := get_viewport().get_camera_3d()
		if camera:
			lod_select(camera.global_position)


## Choisit les maillages affichés à chaque niveau de détail, pour une caméra en `cam_pos` (coordonnées du
## monde). Rend vrai si ce carré a traité sa zone ; faux si son parent doit l'afficher à un niveau moins
## fin.
func lod_select(cam_pos:Vector3) -> bool:
	## On part de la racine, au niveau le moins fin, vers le niveau 0, le plus fin.
	
	if not within_sphere(cam_pos, ranges[lod_level]):
		## Trop loin pour ce niveau : le parent affichera la zone à un niveau moins fin. Faux : zone non
		## traitée.
		reset_visibility()
		return false
	
	if not _visibility_detector.is_on_screen():
		## Hors de l'écran : rien à afficher, mais la zone est traitée.
		mesh_instance.visible = false
		return true
	
	if lod_level == 0:
		## À portée, au niveau le plus fin : aucun enfant plus détaillé, ce carré s'affiche. Zone
		## traitée.
		mesh_instance.visible = true
		return true
	
	else:
		## À portée, avec des enfants plus détaillés : on regarde s'ils sont à portée de leur propre
		## niveau.
		if not within_sphere(cam_pos, ranges[lod_level - 1]):
			reset_visibility()
			
			## Aucun enfant à portée de son niveau : les quatre s'affichent, au niveau de ce carré.
			for subquad: QuadTree3DView in _subquads:
				subquad.mesh_instance.visible = true
		
		else:
			## Au moins un enfant à portée : on descend dans chacun, et ceux qui ne traitent pas leur zone
			## s'affichent.
			for subquad: QuadTree3DView in _subquads:
				if not subquad.lod_select(cam_pos):
					subquad.mesh_instance.visible = true
		
		## La zone est traitée.
		return true


## Cache ce carré et tous ses sous-carrés.
func reset_visibility() -> void:
	if mesh_instance.visible:
		## Ce carré est affiché : aucun enfant ne l'est.
		mesh_instance.visible = false
	
	else:
		## Ce carré est caché : des enfants affichent sans doute sa zone.
		for subquad: QuadTree3DView in _subquads:
			subquad.reset_visibility()


## Vrai si la boîte de ce carré (cull_box) touche la sphère de centre `center` et de rayon `radius`.
func within_sphere(center:Vector3, radius:float) -> bool:
	var radius_squared := radius * radius
	var dmin := 0.0
	
	for axis: int in range(3):
		if center[axis] < cull_box.position[axis]:
			dmin += pow(center[axis] - cull_box.position[axis], 2.0)
		
		elif center[axis] > cull_box.end[axis]:
			dmin += pow(center[axis] - cull_box.end[axis], 2.0)
	
	return dmin <= radius_squared
