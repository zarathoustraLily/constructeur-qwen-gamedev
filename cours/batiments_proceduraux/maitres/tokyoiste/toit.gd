@tool
extends RefCounted
## Toit-terrasse : étanchéité, acrotères, édicule de l'escalier, réservoir d'eau, climatiseurs,
## antenne.
## {STATUS}
##
## Le toit a son propre script : c'est un objet à part, qu'on pose sur une base rectangulaire.
## Il ne connaît de l'immeuble que ce qu'on lui donne en arguments. Tout est « static » : le
## script de l'immeuble appelle RoofBuilder.build(...) sans créer d'objet.
##
## Vocabulaire : l'ACROTÈRE est le muret qui borde un toit plat ; l'ÉDICULE, la petite
## construction où l'escalier arrive sur le toit ; l'ÉTANCHÉITÉ, la nappe qui garde l'eau
## dehors.
##
## Limite : l'édicule et le réservoir dépassent du toit sans être comptés dans le gabarit
## oblique. La règle réelle n'exempte ces ouvrages que sous conditions ; le cours ne les
## vérifie pas.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")

## Épaisseur des acrotères.
const PARAPET_DEPTH: float = 0.2
## Motif « grille de climatiseur » du shader de garde-corps.
const MOTIF_FAN_GRILLE: float = 2.0
## Formes de réservoir.
const TANK_CYLINDER: int = 0
const TANK_PANELS: int = 1
## Taille de l'édicule : profondeur et hauteur. Sa largeur est celle de la travée d'escalier.
const PENTHOUSE_LENGTH: float = 3.2
const PENTHOUSE_HEIGHT: float = 2.5


## Monte le toit sur le dernier niveau : une base de « width » sur « depth », posée en
## « base_y », dont la façade est en retrait de « setback ». L'acrotère côté rue est déjà monté
## par l'immeuble. « core_x » : abscisse de la travée d'escalier, où se dresse l'édicule.
static func build(mesh: MeshBuilder, materials: Materials, width: float, depth: float, base_y: float, setback: float,
		parapet_height: float, core_x: float, penthouse_width: float, penthouse: bool, water_tank: bool, roof_units: int,
		tank_style: int) -> void:
	var front_z: float = -setback
	var length: float = depth - setback
	var inner_front: float = front_z - PARAPET_DEPTH

	# L'étanchéité : une nappe mince, d'un acrotère à l'autre.
	mesh.box(Vector3(width - 2.0 * PARAPET_DEPTH, 0.05, length - 2.0 * PARAPET_DEPTH), Vector3(0.0, base_y + 0.025, front_z - 0.5 * length), materials.roofing)
	# Les acrotères des deux côtés, puis celui du fond.
	var side_length: float = length - PARAPET_DEPTH
	for side: float in [-1.0, 1.0]:
		mesh.box(Vector3(PARAPET_DEPTH, parapet_height, side_length), Vector3(side * 0.5 * (width - PARAPET_DEPTH), base_y + 0.5 * parapet_height, inner_front - 0.5 * side_length), materials.side)
	mesh.box(Vector3(width, parapet_height, PARAPET_DEPTH), Vector3(0.0, base_y + 0.5 * parapet_height, -depth + 0.5 * PARAPET_DEPTH), materials.side)
#@ 13+
	# Leurs couvertines : de simples tôles plates, de près et à mi-distance.
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	var cap_y: float = base_y + parapet_height + 0.02
	for side: float in [-1.0, 1.0]:
		mesh.box(Vector3(PARAPET_DEPTH + 0.06, 0.04, side_length), Vector3(side * 0.5 * (width - PARAPET_DEPTH), cap_y, inner_front - 0.5 * side_length), materials.aluminium)
	mesh.box(Vector3(width + 0.06, 0.04, PARAPET_DEPTH + 0.06), Vector3(0.0, cap_y, -depth + 0.5 * PARAPET_DEPTH), materials.aluminium)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# L'édicule : la cage d'escalier qui continue au-dessus du toit, juste derrière la façade.
	var penthouse_size: Vector3 = Vector3(penthouse_width - 0.3, PENTHOUSE_HEIGHT, minf(PENTHOUSE_LENGTH, length - 1.5))
	var penthouse_center: Vector3 = Vector3(core_x, base_y + 0.5 * penthouse_size.y, inner_front - 0.5 * penthouse_size.z)
	if penthouse:
		mesh.box(penthouse_size, penthouse_center, materials.facade)
		# Sa dalle de toit, qui déborde un peu.
		mesh.box(Vector3(penthouse_size.x + 0.2, 0.15, penthouse_size.z + 0.2), penthouse_center + Vector3(0.0, 0.5 * penthouse_size.y + 0.075, 0.0), materials.concrete)

	if water_tank:
		# Le réservoir : sur l'édicule s'il y en a un, sinon sur le toit, au même endroit.
		var stand_y: float = base_y + (penthouse_size.y + 0.15 if penthouse else 0.05)
		_tank(mesh, materials, Vector3(penthouse_center.x, stand_y, penthouse_center.z), minf(penthouse_size.x, penthouse_size.z), tank_style)

	# Les climatiseurs des bureaux : une rangée, du côté opposé à l'édicule.
	var row_side: float = -1.0 if core_x > 0.0 else 1.0
	var unit: Vector3 = Vector3(0.9, 1.2, 0.35)
	for index: int in range(roof_units):
		var x: float = row_side * (0.5 * width - PARAPET_DEPTH - 0.7 - float(index) * 1.1)
		# La rangée s'arrête avant d'arriver sous l'édicule.
		if absf(x - core_x) < 0.5 * penthouse_size.x + 0.6 and penthouse:
			break
		var center: Vector3 = Vector3(x, base_y + 0.05 + 0.5 * unit.y, front_z - 0.55 * length)
#@ 13+
		# De loin, on ne les voit plus derrière l'acrotère.
		mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
		mesh.box(unit, center, materials.appliance)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
		mesh.panel(Vector2(unit.x, unit.y), Transform3D(Basis.IDENTITY, center + Vector3(0.0, 0.0, 0.5 * unit.z + 0.004)), materials.railing, Color(MOTIF_FAN_GRILLE, 0.0, 0.0, 0.0))
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# L'antenne de télévision : un mât, une traverse, des brins. Tout est en boîtes fines.
	var mast: Vector3 = Vector3(row_side * (0.5 * width - 0.5), base_y + parapet_height, -depth + 0.6)
#@ 13+
	# Des pièces de trois centimètres : de près seulement, et sans ombre portée.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	mesh.box(Vector3(0.035, 2.4, 0.035), mast + Vector3(0.0, 1.2, 0.0), materials.aluminium)
	mesh.box(Vector3(0.025, 0.025, 1.1), mast + Vector3(0.0, 2.3, 0.0), materials.aluminium)
	for element: int in range(5):
		mesh.box(Vector3(0.5 + 0.08 * float(element), 0.02, 0.02), mast + Vector3(0.0, 2.3, -0.5 + 0.25 * float(element)), materials.aluminium)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Réservoir d'eau posé en « base » (le milieu de son pied), sur une surface large de « room ».
static func _tank(mesh: MeshBuilder, materials: Materials, base: Vector3, room: float, style: int) -> void:
	var leg: float = 0.4
	if style == TANK_PANELS:
		# Cuve à panneaux : une boîte, et les nervures de ses panneaux d'un mètre.
		var size: Vector3 = Vector3(minf(1.9, room - 0.2), 1.5, minf(1.4, room - 0.2))
		var center: Vector3 = base + Vector3(0.0, leg + 0.5 * size.y, 0.0)
		mesh.box(size, center, materials.tank)
#@ 13+
		# Nervures et pieds : de près seulement.
		mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
		for rib: int in range(3):
			var offset: float = (float(rib) - 1.0) * 0.5 * size.x
			mesh.box(Vector3(0.05, size.y + 0.04, size.z + 0.04), center + Vector3(offset * 0.98, 0.0, 0.0), materials.tank)
		mesh.box(Vector3(size.x + 0.04, 0.05, size.z + 0.04), center, materials.tank)
		for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
			mesh.box(Vector3(0.08, leg, 0.08), base + Vector3(corner.x * 0.45 * size.x, 0.5 * leg, corner.y * 0.45 * size.z), materials.pipe)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all
		return

	# Réservoir cylindrique : un tronc de cône à deux rayons égaux, sur quatre pieds.
	var radius: float = minf(0.7, 0.5 * room - 0.15)
	var height: float = 1.6
	var middle: Vector3 = base + Vector3(0.0, leg + 0.5 * height, 0.0)
#@ 9-12
	mesh.cone(middle, radius, radius, height, materials.tank, Basis.IDENTITY, 16)
	# Son couvercle, un cône très plat.
	mesh.cone(middle + Vector3(0.0, 0.5 * height + 0.06, 0.0), radius, 0.15, 0.12, materials.tank, Basis.IDENTITY, 16)
#@ 13+
	# Seize pans de près, huit au-delà : la silhouette reste ronde, avec la moitié des triangles.
	for zones: int in [MeshBuilder.ZONE_NEAR, MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR]:
		var segments: int = 16 if zones == MeshBuilder.ZONE_NEAR else 8
		mesh.set_zones(zones)
		mesh.cone(middle, radius, radius, height, materials.tank, Basis.IDENTITY, segments)
		# Son couvercle, un cône très plat.
		mesh.cone(middle + Vector3(0.0, 0.5 * height + 0.06, 0.0), radius, 0.15, 0.12, materials.tank, Basis.IDENTITY, segments)
	# Les pieds : de près seulement.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	for corner: Vector2 in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)]:
		mesh.box(Vector3(0.08, leg, 0.08), base + Vector3(corner.x * 0.6 * radius, 0.5 * leg, corner.y * 0.6 * radius), materials.pipe)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all
