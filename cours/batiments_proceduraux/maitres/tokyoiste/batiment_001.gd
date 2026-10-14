@tool
extends Node3D
## Immeuble tokyoïte, étape 001 : un mur percé de baies, immeuble étroit.
## {STATUS}
##
## La façade la plus simple possible : une grille. Des travées en largeur, des niveaux en
## hauteur, une baie par case. Pas encore de fenêtre, pas encore de matériau calculé.
## Les proportions sont celles d'un petit immeuble de Tokyo : une façade de 6,60 m, six
## niveaux, des fenêtres larges et basses au-dessus d'une allège haute.
##
## Les quatre idées de l'étape :
##   1. Un maillage procédural est une liste de triangles qu'on écrit dans un SurfaceTool.
##      Chaque sommet reçoit une position et une normale. Ici, tout est fait de boîtes :
##      une boîte = six rectangles, un rectangle = deux triangles.
##   2. On ne « perce » jamais un mur. On pose du mur autour du trou : un trumeau à gauche, un
##      à droite, une allège dessous, un linteau dessus. Quatre boîtes par baie.
##   3. Tout est en mètres, dans un repère qui ne changera plus : la façade est dans le plan
##      z = 0, elle regarde vers +Z (la rue), elle est centrée sur x = 0 et posée sur y = 0.
##      L'immeuble s'enfonce vers -Z.
##   4. Le script est un « @tool » : il tourne dans l'éditeur. Chaque variable « @export »
##      apparaît dans l'inspecteur ; dès qu'une valeur change, l'immeuble est reconstruit.
##      La scène n'enregistre que les variables, jamais la géométrie.
##
## À lire dans l'ordre :
##   rebuild()  ->  _build_level()  ->  _add_wall()  ->  _add_box()  ->  _add_quad()  ->  _add_triangle()

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Épaisseur du mur de façade : un voile de béton, bien plus mince qu'un mur de pierre.
const WALL_DEPTH: float = 0.25
## Les morceaux de mur voisins se recouvrent de quelques millimètres : posés bord à bord, ils
## laisseraient passer un liseré de lumière à leur jonction.
const WALL_OVERLAP: float = 0.006
## Teinte du carrelage de façade et teinte du mortier du volume arrière.
const TILE_COLOR: Color = Color(0.80, 0.78, 0.72)
const MORTAR_COLOR: Color = Color(0.60, 0.60, 0.58)

@export_group("Plan")
## Nombre de travées : une fenêtre par travée et par niveau.
@export_range(1, 8, 1) var bay_count: int = 3
## Largeur d'une travée.
@export_range(1.6, 4.0, 0.05, "suffix:m") var bay_width: float = 2.2
## Profondeur de l'immeuble, de la façade au mur du fond.
@export_range(6.0, 25.0, 0.5, "suffix:m") var depth: float = 12.0

@export_group("Niveaux")
## Nombre de niveaux, rez-de-chaussée compris. Ils sont tous pareils jusqu'à l'étape 006.
@export_range(1, 12, 1) var floor_count: int = 6
## Hauteur d'un niveau, de plancher à plancher.
@export_range(2.6, 4.5, 0.05, "suffix:m") var floor_height: float = 3.1

@export_group("Baies")
## Largeur et hauteur du trou laissé dans le mur. Elles sont rabotées si la case est trop petite.
@export_range(0.8, 3.5, 0.05, "suffix:m") var window_width: float = 1.8
@export_range(0.6, 3.5, 0.05, "suffix:m") var window_height: float = 1.3
## Hauteur de l'allège : le morceau de mur sous la fenêtre. 0 : porte-fenêtre.
@export_range(0.0, 1.5, 0.05, "suffix:m") var sill_height: float = 0.9

## Empreinte des variables au moment de la dernière construction.
var _signature: int = 0


func _ready() -> void:
	# Dans le jeu, l'immeuble est monté une fois ; inutile de surveiller ses variables.
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(_delta: float) -> void:
	# Dans l'éditeur, à chaque image : une variable a-t-elle changé dans l'inspecteur ?
	if _current_signature() != _signature:
		rebuild()


## Largeur de la façade sur rue.
func get_facade_width() -> float:
	return float(bay_count) * bay_width


## Démonte l'immeuble et le remonte d'après les variables courantes.
func rebuild() -> void:
	_signature = _current_signature()

	# 1. On jette l'ancien résultat.
	for child: Node in get_children(true):
		if child.name == GENERATED_NAME:
			remove_child(child)
			child.queue_free()

	# 2. On prépare un nœud « interne » : il n'apparaît pas dans l'arbre de la scène et n'est
	#    pas enregistré avec elle. La scène ne garde que les variables, jamais la géométrie.
	var root: Node3D = Node3D.new()
	root.name = GENERATED_NAME
	add_child(root, false, Node.INTERNAL_MODE_BACK)

	# 3. On écrit les triangles. Un SurfaceTool par matériau : ici, le mur et le volume arrière.
	var wall: SurfaceTool = SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	for level: int in range(floor_count):
		_build_level(wall, level)

	var back: SurfaceTool = SurfaceTool.new()
	back.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height: float = float(floor_count) * floor_height
	_add_box(back, Vector3(get_facade_width(), height, depth - WALL_DEPTH),
			Vector3(0.0, 0.5 * height, -0.5 * (depth + WALL_DEPTH)))

	# 4. Chaque SurfaceTool devient un maillage, porté par un MeshInstance3D.
	_commit(wall, root, _plain_material(TILE_COLOR))
	_commit(back, root, _plain_material(MORTAR_COLOR))


# --- Façade -----------------------------------------------------------------

## Abscisse du milieu d'une travée, la façade étant centrée sur x = 0.
func _bay_center(bay: int) -> float:
	return (float(bay) - 0.5 * float(bay_count - 1)) * bay_width


## Monte un niveau : pour chaque travée, du mur tout autour de la baie.
func _build_level(surface: SurfaceTool, level: int) -> void:
	var base_y: float = float(level) * floor_height
	# Le mur est derrière le plan z = 0 : son milieu est à une demi-épaisseur en arrière.
	var wall_z: float = -0.5 * WALL_DEPTH
	# La baie ne peut pas être plus grande que sa case.
	var opening: Vector2 = Vector2(
			minf(window_width, bay_width - 0.3),
			minf(window_height, floor_height - sill_height - 0.2))
	var pier: float = 0.5 * (bay_width - opening.x)
	var lintel: float = floor_height - sill_height - opening.y

	for bay: int in range(bay_count):
		var x: float = _bay_center(bay)
		# Trumeaux : le mur plein à gauche et à droite de la baie, sur toute la hauteur du niveau.
		_add_wall(surface, Vector3(pier, floor_height, WALL_DEPTH),
				Vector3(x - 0.5 * bay_width + 0.5 * pier, base_y + 0.5 * floor_height, wall_z))
		_add_wall(surface, Vector3(pier, floor_height, WALL_DEPTH),
				Vector3(x + 0.5 * bay_width - 0.5 * pier, base_y + 0.5 * floor_height, wall_z))
		# Allège : le mur sous la baie.
		if sill_height > 0.001:
			_add_wall(surface, Vector3(opening.x, sill_height, WALL_DEPTH),
					Vector3(x, base_y + 0.5 * sill_height, wall_z))
		# Linteau : le mur au-dessus de la baie.
		_add_wall(surface, Vector3(opening.x, lintel, WALL_DEPTH),
				Vector3(x, base_y + floor_height - 0.5 * lintel, wall_z))


## Morceau de mur : une boîte, élargie du recouvrement.
func _add_wall(surface: SurfaceTool, size: Vector3, center: Vector3) -> void:
	_add_box(surface, size + Vector3(WALL_OVERLAP, WALL_OVERLAP, 0.0), center)


# --- Triangles --------------------------------------------------------------

## Ajoute un triangle. Godot prend pour face avant celle dont les sommets tournent dans le
## sens des aiguilles d'une montre : on vérifie avec la normale, et on inverse deux sommets
## si le triangle tourne dans l'autre sens.
func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	# Le produit vectoriel de deux côtés donne la direction vers laquelle le triangle « tourne ».
	# S'il pointe du même côté que la normale, les sommets sont dans le mauvais ordre.
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var swapped: Vector3 = b
		b = c
		c = swapped
	# Pour chaque sommet : d'abord ses attributs (ici la normale), puis add_vertex() qui le valide.
	for point: Vector3 in [a, b, c]:
		surface.set_normal(normal)
		surface.add_vertex(point)


## Ajoute un rectangle a-b-c-d : deux triangles qui partagent une diagonale.
func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_add_triangle(surface, a, b, c, normal)
	_add_triangle(surface, a, c, d, normal)


## Ajoute une boîte centrée sur « center » : six rectangles, un par face.
func _add_box(surface: SurfaceTool, size: Vector3, center: Vector3) -> void:
	var half: Vector3 = 0.5 * size
	# Pour chacun des trois axes (0 : x, 1 : y, 2 : z), les deux faces perpendiculaires à cet axe.
	for axis: int in range(3):
		# Les deux autres axes : ceux dans lesquels la face s'étend.
		var first: int = (axis + 1) % 3
		var second: int = (axis + 2) % 3
		# -1 : la face du côté négatif de l'axe. +1 : celle du côté positif.
		for direction: float in [-1.0, 1.0]:
			# La normale de la face pointe le long de l'axe, vers l'extérieur de la boîte.
			var normal: Vector3 = Vector3.ZERO
			normal[axis] = direction
			# Les quatre coins de la face, en tournant autour d'elle.
			var corners: Array[Vector3] = []
			for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
				var point: Vector3 = Vector3.ZERO
				point[axis] = direction * half[axis]
				point[first] = corner.x * half[first]
				point[second] = corner.y * half[second]
				corners.append(center + point)
			_add_quad(surface, corners[0], corners[1], corners[2], corners[3], normal)


## Transforme un SurfaceTool en maillage et l'accroche sous « parent ».
func _commit(surface: SurfaceTool, parent: Node3D, material: Material) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	# commit() fabrique l'ArrayMesh à partir de tous les sommets ajoutés.
	instance.mesh = surface.commit()
	# Le matériau est posé sur le nœud, pas dans le maillage : on peut le changer sans refaire les triangles.
	instance.material_override = material
	parent.add_child(instance)


## Matériau uni ordinaire : une couleur, une surface mate. Il sera remplacé par un shader à l'étape 002.
func _plain_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


# --- Variables --------------------------------------------------------------

## Empreinte de toutes les variables exportées : si elle change, il faut reconstruire.
## On demande au script la liste de ses propres variables, on garde celles que l'inspecteur
## montre, et on hache leurs valeurs en un seul nombre.
func _current_signature() -> int:
	var values: Array[Variant] = []
	var properties: Array[Dictionary] = (get_script() as Script).get_script_property_list()
	for index: int in range(properties.size()):
		# « usage » est un champ de bits : on ne garde que les variables du script (pas les
		# groupes) que l'inspecteur affiche, c'est-à-dire les @export.
		var usage: int = properties[index]["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_EDITOR:
			values.append(get(properties[index]["name"]))
	# hash() d'un tableau dépend de toutes ses valeurs : une seule change, le nombre change.
	return hash(values)
