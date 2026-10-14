@tool
extends Node3D
## Tour new-yorkaise, étape 001 : une tour, des piliers et des bandeaux.
## {STATUS}
##
## La tour la plus simple possible : un prisme, et quatre façades en grille. Les proportions
## sont celles d'une tour de bureaux de Manhattan des années 1920 : des travées de 2 m, des
## étages de 3,66 m (12 pieds), trente étages, un plan de 26 m sur 18 m.
## Pas encore de fenêtre, pas encore de matériau calculé.
##
## Les quatre idées de l'étape :
##   1. Un maillage procédural est une liste de triangles qu'on écrit dans un SurfaceTool.
##      Chaque sommet reçoit une position et une normale. Ici, tout est fait de boîtes :
##      une boîte = six rectangles, un rectangle = deux triangles.
##   2. On ne « perce » jamais un mur : on pose du mur autour des trous. Mais une tour a
##      plus de mille fenêtres, et quatre boîtes par fenêtre en feraient quatre mille. On
##      compte donc autrement : un pilier par travée, d'un seul tenant du pied au sommet, et un
##      bandeau par étage, sur toute la largeur de la façade. Les fenêtres sont les vides
##      laissés entre les piliers et les bandeaux. Les piliers avancent devant les bandeaux :
##      c'est la verticalité des tours de cette époque.
##   3. Tout est en mètres, dans un repère qui ne changera plus : la façade principale est dans
##      le plan z = 0, elle regarde vers +Z (la rue), elle est centrée sur x = 0 et posée sur
##      y = 0. La tour s'enfonce vers -Z. Ses quatre façades sont construites par la même
##      fonction, tournée d'un quart de tour à chaque fois.
##   4. Le script est un « @tool » : il tourne dans l'éditeur. Chaque variable « @export »
##      apparaît dans l'inspecteur ; dès qu'une valeur change, la tour est reconstruite.
##      La scène n'enregistre que les variables, jamais la géométrie.
##
## À lire dans l'ordre :
##   rebuild()  ->  _build_face()  ->  _add_box()  ->  _add_quad()  ->  _add_triangle()

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Épaisseur des bandeaux, et saillie des piliers devant eux.
const WALL_DEPTH: float = 0.35
const PIER_PROJECTION: float = 0.12
## Les morceaux de mur voisins se recouvrent de quelques millimètres : posés bord à bord, ils
## laisseraient passer un liseré de lumière à leur jonction.
const WALL_OVERLAP: float = 0.006
## Teinte de la brique, et teinte du noyau sombre qu'on aperçoit par les fenêtres.
const BRICK_COLOR: Color = Color(0.62, 0.46, 0.36)
const CORE_COLOR: Color = Color(0.06, 0.06, 0.07)

@export_group("Plan")
## Nombre de travées des façades avant et arrière, puis des façades latérales.
@export_range(2, 30, 1) var bay_count: int = 13
@export_range(2, 30, 1) var side_bay_count: int = 9
## Largeur d'une travée : une fenêtre et un pilier.
@export_range(1.4, 3.0, 0.05, "suffix:m") var bay_width: float = 2.0

@export_group("Niveaux")
## Nombre d'étages, rez-de-chaussée compris. Ils sont tous pareils jusqu'à l'étape 006.
@export_range(1, 80, 1) var floor_count: int = 30
## Hauteur d'un étage, de plancher à plancher : 12 pieds.
@export_range(3.0, 4.5, 0.01, "suffix:m") var floor_height: float = 3.66

@export_group("Baies")
## Largeur et hauteur d'une fenêtre. La largeur fixe celle des piliers : ce qui reste de la
## travée.
@export_range(0.6, 2.4, 0.05, "suffix:m") var window_width: float = 1.2
@export_range(0.8, 3.0, 0.05, "suffix:m") var window_height: float = 1.9
## Hauteur de l'allège : du plancher au bas de la fenêtre.
@export_range(0.2, 1.4, 0.05, "suffix:m") var sill_height: float = 0.85

## Empreinte des variables au moment de la dernière construction.
var _signature: int = 0


func _ready() -> void:
	# Dans le jeu, la tour est montée une fois ; inutile de surveiller ses variables.
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(_delta: float) -> void:
	# Dans l'éditeur, à chaque image : une variable a-t-elle changé dans l'inspecteur ?
	if _current_signature() != _signature:
		rebuild()


## Largeur de la façade principale, et profondeur de la tour.
func get_facade_width() -> float:
	return float(bay_count) * bay_width


func get_depth() -> float:
	return float(side_bay_count) * bay_width


## Démonte la tour et la remonte d'après les variables courantes.
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

	# 3. On écrit les triangles. Un SurfaceTool par matériau : ici, la brique et le noyau.
	var wall: SurfaceTool = SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var width: float = get_facade_width()
	var depth: float = get_depth()
	var height: float = float(floor_count) * floor_height
	# Les quatre façades. Chacune est décrite dans son propre repère : son plan est z = 0, elle
	# regarde vers +Z, elle est centrée sur x = 0. Le repère est ensuite tourné et posé à sa
	# place : devant, à droite, derrière, à gauche.
	var faces: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0)),
		Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(0.5 * width, 0.0, -0.5 * depth)),
		Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -depth)),
		Transform3D(Basis(Vector3.UP, -0.5 * PI), Vector3(-0.5 * width, 0.0, -0.5 * depth)),
	]
	for index: int in range(faces.size()):
		var bays: int = bay_count if index % 2 == 0 else side_bay_count
		_build_face(wall, faces[index], bays, height)

	# Le noyau : une boîte sombre, en retrait d'un mètre derrière les façades. C'est elle qu'on
	# voit par les fenêtres, tant qu'il n'y a ni vitre ni bureau derrière.
	var core: SurfaceTool = SurfaceTool.new()
	core.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(core, Vector3(width - 2.0, height, depth - 2.0), Vector3(0.0, 0.5 * height, -0.5 * depth))

	# 4. Chaque SurfaceTool devient un maillage, porté par un MeshInstance3D.
	_commit(wall, root, _plain_material(BRICK_COLOR))
	_commit(core, root, _plain_material(CORE_COLOR))


# --- Façades ----------------------------------------------------------------

## Monte une façade de « bays » travées sur « height » mètres, dans le repère « frame » : les
## piliers d'abord, puis un bandeau sous chaque rangée de fenêtres, un dernier en haut, et le
## pilier d'angle de son bout gauche.
func _build_face(surface: SurfaceTool, frame: Transform3D, bays: int, height: float) -> void:
	var width: float = float(bays) * bay_width
	# La fenêtre ne peut pas être plus grande que sa case.
	var opening: Vector2 = Vector2(minf(window_width, bay_width - 0.3), minf(window_height, floor_height - sill_height - 0.3))
	var pier: float = bay_width - opening.x

	# Un pilier entre deux travées, sur toute la hauteur. Les piliers d'angle sont à part.
	for bay: int in range(1, bays):
		var x: float = -0.5 * width + float(bay) * bay_width
		_add_box_in(surface, frame, Vector3(pier, height, WALL_DEPTH + PIER_PROJECTION),
				Vector3(x, 0.5 * height, 0.5 * (PIER_PROJECTION - WALL_DEPTH)))

	# Un bandeau par étage : du haut de la fenêtre de l'étage du dessous jusqu'au bas de celle
	# de cet étage. Il court sur toute la largeur, derrière les piliers.
	var band_z: float = -0.5 * WALL_DEPTH
	for floor_index: int in range(floor_count):
		var sill_y: float = float(floor_index) * floor_height + sill_height
		var bottom: float = maxf(sill_y - (floor_height - opening.y), 0.0)
		_add_box_in(surface, frame, Vector3(width + WALL_OVERLAP, sill_y - bottom, WALL_DEPTH),
				Vector3(0.0, 0.5 * (bottom + sill_y), band_z))
	# Le dernier bandeau, du haut des fenêtres du dernier étage jusqu'au sommet.
	var last_head: float = float(floor_count - 1) * floor_height + sill_height + opening.y
	_add_box_in(surface, frame, Vector3(width + WALL_OVERLAP, height - last_head, WALL_DEPTH),
			Vector3(0.0, 0.5 * (last_head + height), band_z))

	# Le pilier d'angle. Au bout de la façade, il reste une demi-largeur de pilier avant la
	# première fenêtre ; la façade voisine a la même au même coin. Le pilier d'angle prend les
	# deux, et avance comme les autres piliers sur les deux façades : vu de dessus, c'est un
	# carré de côté « corner » qui enveloppe le coin. Chaque façade pose celui de son bout
	# gauche : les quatre coins sont faits.
	var corner: float = 0.5 * pier + PIER_PROJECTION
	_add_box_in(surface, frame, Vector3(corner, height, corner),
			Vector3(-0.5 * width - PIER_PROJECTION + 0.5 * corner, 0.5 * height, PIER_PROJECTION - 0.5 * corner))


## Boîte décrite dans le repère d'une façade : on transforme son centre, puis on la pose.
## Les façades sont tournées d'un quart de tour exact : une boîte y reste une boîte droite,
## dont il suffit de permuter la largeur et la profondeur.
func _add_box_in(surface: SurfaceTool, frame: Transform3D, size: Vector3, center: Vector3) -> void:
	var turned: Vector3 = (frame.basis * size).abs()
	_add_box(surface, turned, frame * center)


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
