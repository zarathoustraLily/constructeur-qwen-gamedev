@tool
extends RefCounted
## Le couronnement de la tour : ce qui se dresse au-dessus de son dernier étage, et le château
## d'eau.
## {STATUS}
##
## Selon la famille de la tour :
##   - tour de brique : un toit plat et la salle des machines des ascenseurs ; ou des gradins
##     de couronne en pierre ; ou une flèche d'acier sur ces gradins ; ou une pyramide de
##     cuivre. Et le château d'eau de bois, posé sur une terrasse ;
##   - tour de verre de 1961 : les machines du toit, cachées derrière un écran de ventelles ;
##   - tour tout en verre : le verre continue au-dessus du dernier étage, sans planchers derrière
##     lui ; la nuit, des projecteurs l'éclairent de l'intérieur.
##
## Les fonctions reçoivent un rectangle du plan du terrain (x de gauche à droite, y vers
## l'arrière), comme les gradins, et le convertissent elles-mêmes : un point (x, y) du plan est
## le point (x, 0, -y) de la tour. Les cotes sont plausibles ; elles ne sont pas relevées sur
## une tour réelle. Toutes les fonctions sont « static ».

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")

## Les couronnements de la tour de brique, dans l'ordre de la liste de l'inspecteur.
const CROWN_FLAT: int = 0
const CROWN_STEPS: int = 1
const CROWN_SPIRE: int = 2
const CROWN_PYRAMID: int = 3
## Le château d'eau : rayon et hauteur de la cuve, hauteur du pied d'acier.
const TANK_RADIUS: float = 2.5
const TANK_HEIGHT: float = 4.5
const TANK_STAND: float = 3.0


## Couronnement de la tour de brique, sur son toit « rect », posé à la hauteur « top ».
## « unit » : la largeur d'une travée ; « storey » : la hauteur d'un étage. Renvoie la hauteur
## du point le plus haut.
static func brick_crown(mesh: MeshBuilder, materials: Materials, rect: Rect2, top: float, kind: int, unit: float, storey: float) -> float:
	if kind == CROWN_FLAT:
		# Toit plat : la salle des machines des ascenseurs, une boîte de brique au milieu, sous
		# une dalle débordante.
		var room: Rect2 = rect.grow(-maxf(unit, 0.3 * minf(rect.size.x, rect.size.y)))
		_slab(mesh, room, top, top + 1.6 * storey, materials.brick)
		_slab(mesh, room.grow(0.15), top + 1.6 * storey, top + 1.6 * storey + 0.2, materials.stone)
		return top + 1.6 * storey + 0.2
	if kind == CROWN_PYRAMID:
		# Pyramide de cuivre sur tout le toit, en retrait du parapet. Sa pente : la moitié du
		# petit côté du toit pour la hauteur, un peu plus de 45 degrés.
		var base: Rect2 = rect.grow(-0.3)
		var height: float = 0.55 * minf(base.size.x, base.size.y)
		_pyramid(mesh, base, top, height, materials.copper)
		return top + height
	# Gradins de couronne : des boîtes de pierre, chacune en retrait d'une travée sur la
	# précédente, coiffées d'une dalle débordante. Trois pour la couronne à gradins, deux sous
	# une flèche.
	var steps: int = 3 if kind == CROWN_STEPS else 2
	var y: float = top
	var step: Rect2 = rect
	for index: int in range(steps):
		step = step.grow(-unit)
		if step.size.x < 2.0 * unit or step.size.y < 2.0 * unit:
			break
		var height: float = 1.2 * storey
		_slab(mesh, step, y, y + height, materials.stone)
		_slab(mesh, step.grow(0.12), y + height, y + height + 0.15, materials.stone)
		y += height + 0.15
	if kind == CROWN_STEPS:
		# Un mât de drapeau sur le dernier gradin.
		var center: Vector2 = step.get_center()
#@ 13+
		# Huit centimètres de diamètre : de près et à mi-distance seulement.
		mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ 9+
		mesh.cone(Vector3(center.x, y + 6.0, -center.y), 0.08, 0.04, 12.0, materials.steel, Basis.IDENTITY, 6)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 9+
		return y + 12.0
	# La flèche : une pyramide d'acier, très haute, puis une aiguille.
	var spire_base: Rect2 = step.grow(-0.5 * unit)
	var spire_height: float = 2.0 * minf(spire_base.size.x, spire_base.size.y)
	_pyramid(mesh, spire_base, y, spire_height, materials.steel)
	var tip: Vector2 = spire_base.get_center()
	var needle: float = 0.35 * spire_height
	mesh.cone(Vector3(tip.x, y + spire_height + 0.5 * needle - 0.5, -tip.y), 0.3, 0.02, needle, materials.steel, Basis.IDENTITY, 8)
	return y + spire_height + needle - 0.5


## Le château d'eau de bois de New York : une cuve de douelles cerclées d'acier, sous un toit
## conique, sur un pied de quatre poteaux d'acier et une plateforme. « base » : le point du toit
## sous son centre.
static func water_tank(mesh: MeshBuilder, materials: Materials, base: Vector3) -> void:
#@ 13+
	# Le pied d'acier, de près et à mi-distance ; la cuve et son toit, à toute distance : c'est
	# leur silhouette qu'on reconnaît de loin.
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ 9+
	for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
		var leg: Vector3 = base + Vector3(corner.x * 1.7, 0.5 * TANK_STAND, corner.y * 1.7)
		mesh.box(Vector3(0.2, TANK_STAND, 0.2), leg, materials.dark_steel)
	mesh.box(Vector3(4.6, 0.2, 4.6), base + Vector3(0.0, TANK_STAND + 0.1, 0.0), materials.dark_steel)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 9+
	# Un cylindre est un tronc de cône à deux rayons égaux.
	var bottom: float = TANK_STAND + 0.2
	mesh.cone(base + Vector3(0.0, bottom + 0.5 * TANK_HEIGHT, 0.0), TANK_RADIUS, TANK_RADIUS, TANK_HEIGHT, materials.tank_wood, Basis.IDENTITY, 20)
	mesh.cone(base + Vector3(0.0, bottom + TANK_HEIGHT + 0.6, 0.0), TANK_RADIUS + 0.2, 0.15, 1.2, materials.tank_wood, Basis.IDENTITY, 20)


## Machines du toit de la tour de 1961, cachées derrière un écran de ventelles en retrait du
## bord du toit, haut de deux étages. Renvoie la hauteur de son sommet.
static func louvred_screen(mesh: MeshBuilder, materials: Materials, rect: Rect2, top: float, storey: float) -> float:
	var screen: Rect2 = rect.grow(-3.0)
	_slab(mesh, screen, top, top + 2.0 * storey, materials.louvres)
	return top + 2.0 * storey


## Couronne de la tour tout en verre : le mur-rideau continue au-dessus du dernier étage, haut
## de « height », sans planchers derrière lui. Dedans, les machines du toit : une boîte sombre,
## plus basse. Renvoie la hauteur de son sommet.
static func glass_crown(mesh: MeshBuilder, materials: Materials, rect: Rect2, top: float, height: float) -> float:
	for side: int in range(4):
		var frame: Transform3D = _face_frame(rect, side)
		var width: float = rect.size.x if side % 2 == 0 else rect.size.y
		# Un seul rectangle par face, que le shader du mur-rideau dessine en mode couronne.
		mesh.panel(Vector2(width, height), frame * Transform3D(Basis.IDENTITY, Vector3(0.0, top + 0.5 * height, 0.0)),
				materials.crown_glass, Color(0.0, 0.0, float(side), 0.0))
		# Le dos du verre : une tôle sombre, qu'on voit depuis le dessus.
		mesh.box(Vector3(width, height, 0.05), frame * Vector3(0.0, top + 0.5 * height, -0.06), materials.core, frame.basis)
	_slab(mesh, rect.grow(-1.5), top, top + 0.55 * height, materials.core)
	return top + height


# --- Formes ----------------------------------------------------------------------

## Boîte posée sur le rectangle « rect » du plan, de la hauteur « bottom » à « top ».
static func _slab(mesh: MeshBuilder, rect: Rect2, bottom: float, top: float, material: Material) -> void:
	var center: Vector2 = rect.get_center()
	mesh.box(Vector3(rect.size.x, top - bottom, rect.size.y), Vector3(center.x, 0.5 * (bottom + top), -center.y), material)


## Pyramide à base rectangulaire, posée sur « rect » à la hauteur « bottom », haute de
## « height » : quatre triangles qui montent des côtés de la base vers la pointe.
static func _pyramid(mesh: MeshBuilder, rect: Rect2, bottom: float, height: float, material: Material) -> void:
	var center: Vector2 = rect.get_center()
	var apex: Vector3 = Vector3(center.x, bottom + height, -center.y)
	var corners: Array[Vector3] = [
		Vector3(rect.position.x, bottom, -rect.position.y), Vector3(rect.end.x, bottom, -rect.position.y),
		Vector3(rect.end.x, bottom, -rect.end.y), Vector3(rect.position.x, bottom, -rect.end.y),
	]
	for index: int in range(4):
		var a: Vector3 = corners[index]
		var b: Vector3 = corners[(index + 1) % 4]
		# Le produit vectoriel de deux côtés du triangle donne sa normale : ici, elle regarde vers
		# le dehors et vers le haut.
		var normal: Vector3 = (b - a).cross(apex - a).normalized()
		mesh.triangle(a, b, apex, normal, normal, normal, material)


## Repère d'une face du rectangle, comme celui des façades dans le script de la tour : origine
## au milieu du pied, x le long de la face, z vers le dehors.
static func _face_frame(rect: Rect2, side: int) -> Transform3D:
	var center: Vector2 = rect.get_center()
	match side:
		0:
			return Transform3D(Basis.IDENTITY, Vector3(center.x, 0.0, -rect.position.y))
		1:
			return Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(rect.end.x, 0.0, -center.y))
		2:
			return Transform3D(Basis(Vector3.UP, PI), Vector3(center.x, 0.0, -rect.end.y))
		_:
			return Transform3D(Basis(Vector3.UP, -0.5 * PI), Vector3(rect.position.x, 0.0, -center.y))
