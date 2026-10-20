@tool
extends RefCounted
## Comble brisé en zinc : pans de toiture, pignons, lucarnes de plusieurs formes, souches de
## cheminée.
## {STATUS}
##
## Le toit a son propre script : c'est un objet à part, qu'on pose sur une base rectangulaire.
## Il ne connaît de l'immeuble que ce qu'on lui donne en arguments. Tout est « static » : le
## script de l'immeuble appelle RoofBuilder.build(...) sans créer d'objet.
##
## Vocabulaire : le BRISIS est la partie raide du comble, côté rue ; le TERRASSON la partie
## douce au-dessus ; l'ÉGOUT le bas du toit ; le FAÎTE son sommet.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")
const Profiles := preload("{MESH}_profils.gd")

enum DormerStyle { RECTANGULAR = 1, ARCHED = 2, PEDIMENT = 3, BULLSEYE = 4 }

## Pente du terrasson, la partie douce du comble au-dessus du brisis.
const TERRASSON_ANGLE: float = 22.0
## Profondeur minimale d'une lucarne, de sa face avant à son fond noyé dans le comble.
const DORMER_DEPTH: float = 1.3
## Codes de forme attendus par le shader de fenêtre.
const SHAPE_RECTANGLE: float = 0.0
const SHAPE_ARCH: float = 1.0
const SHAPE_OVAL: float = 2.0


## Monte le comble sur une base rectangulaire de « width » sur « depth », posée en « base_y ».
## « dormer_styles » donne la forme de la lucarne de chaque travée ; vide : pas de lucarnes.
static func build(mesh: MeshBuilder, materials: Materials, width: float, depth: float, base_y: float,
		bay_centers: PackedFloat32Array, bay_width: float, brisis_angle: float, brisis_length: float,
		dormer_styles: PackedInt32Array, chimneys: bool) -> void:
	var zinc: ShaderMaterial = materials.zinc
	var slope: float = deg_to_rad(TERRASSON_ANGLE)
	var front_eave: Vector3 = Vector3(0.0, base_y, -0.1)
	var back_eave: Vector3 = Vector3(0.0, base_y, -depth + 0.1)
	var ridge_z: float = -0.5 * depth

	# Brisis raide côté rue, puis terrasson jusqu'au faîte ; même profil côté cour.
	var front_break: Vector3 = _slab(mesh, zinc, width, front_eave, brisis_angle, brisis_length, 1.0)
	var run: float = maxf(front_break.z - ridge_z, 0.3)
	var ridge: Vector3 = _slab(mesh, zinc, width, front_break, TERRASSON_ANGLE, run / cos(slope), 1.0)
	var back_break: Vector3 = _slab(mesh, zinc, width, back_eave, brisis_angle, brisis_length, -1.0)
	_slab(mesh, zinc, width, back_break, TERRASSON_ANGLE, run / cos(slope), -1.0)
	# Faîtage, membron à la brisure, chéneau à l'égout.
	mesh.box(Vector3(width, 0.09, 0.2), ridge + Vector3(0.0, 0.03, 0.0), zinc)
	mesh.box(Vector3(width, 0.1, 0.12), front_break + Vector3(0.0, 0.02, 0.02), zinc)
	mesh.box(Vector3(width, 0.12, 0.2), front_eave + Vector3(0.0, 0.06, 0.12), zinc)

	# Pignons : la face plane qui ferme le comble contre chaque mitoyen. Dans leur repère,
	# x est la profondeur depuis la façade et y la hauteur.
	var gable: PackedVector2Array = PackedVector2Array()
	for corner: Vector3 in [front_eave, front_break, ridge, back_break, back_eave]:
		gable.append(Vector2(-corner.z, corner.y))
	for side: float in [-1.0, 1.0]:
		var frame: Transform3D = Transform3D(Basis(Vector3.FORWARD, Vector3.UP, Vector3.RIGHT), Vector3(side * 0.5 * width, 0.0, 0.0))
		mesh.polygon(gable, frame, materials.plaster, side < 0.0)

	if not dormer_styles.is_empty():
		var rise: float = front_break.y - base_y
		var height: float = clampf(rise - 0.95, 0.9, 1.75)
		var dormer_width: float = minf(1.15, bay_width - 0.7)
		var steepness: float = tan(deg_to_rad(brisis_angle))
		var front_z: float = front_eave.z - 0.45 / steepness + 0.12
		# Plus le brisis est couché, plus la lucarne doit s'enfoncer pour le rejoindre en haut.
		var dormer_depth: float = maxf(DORMER_DEPTH, (0.8 + height) / steepness + 0.3)
		for bay: int in range(bay_centers.size()):
			_dormer(mesh, materials, dormer_styles[bay % dormer_styles.size()], bay_centers[bay], base_y + 0.45, front_z, dormer_width, height, dormer_depth)

	if chimneys:
		_chimneys(mesh, materials, width, depth, base_y, ridge.y - base_y + 0.5)


## Pan de toiture posé à partir de « bottom ». « side » vaut 1 côté rue, -1 côté cour.
## Renvoie le haut du pan.
static func _slab(mesh: MeshBuilder, zinc: Material, width: float, bottom: Vector3, angle_degrees: float, length: float, side: float) -> Vector3:
	var angle: float = deg_to_rad(angle_degrees)
	var direction: Vector3 = Vector3(0.0, sin(angle), -side * cos(angle))
	mesh.box(Vector3(width, 0.1, length), bottom + direction * (0.5 * length), zinc, Basis(Vector3.RIGHT, side * angle))
	return bottom + direction * length


## Lucarne posée sur le brisis : un petit volume de zinc qui avance jusqu'à « front_z », profond
## de « depth », et une fenêtre de la forme correspondante.
static func _dormer(mesh: MeshBuilder, materials: Materials, style: int, x: float, bottom_y: float, front_z: float,
		width: float, height: float, depth: float) -> void:
	var zinc: ShaderMaterial = materials.zinc
	var middle_z: float = front_z - 0.5 * depth
#@ 13+
	# À mi-distance et de loin, toutes les lucarnes se ressemblent : une boîte de zinc et une
	# fenêtre rectangulaire. C'est la silhouette qui compte, et elle est conservée.
	mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
	mesh.box(Vector3(width, height, depth), Vector3(x, bottom_y + 0.5 * height, middle_z), zinc)
	mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR, false)
	# La fenêtre est posée 3 cm devant la boîte : de loin, la profondeur est mesurée moins
	# finement, et deux faces trop proches se disputeraient les mêmes pixels.
	mesh.panel(Vector2(width - 0.3, height - 0.45), Transform3D(Basis.IDENTITY, Vector3(x, bottom_y + 0.5 * height - 0.02, front_z + 0.03)),
			materials.dormer_window, Color(SHAPE_RECTANGLE, 0.0, 0.0, 0.0))
	# De près : la lucarne ouvragée, dans sa forme.
	mesh.set_zones(MeshBuilder.ZONE_NEAR)
#@ all
	var glass_z: float = front_z + 0.04
	var custom: Color = Color(SHAPE_RECTANGLE, 0.0, 0.0, 0.0)
	var window_size: Vector2 = Vector2(width - 0.3, height - 0.45)
	var window_y: float = bottom_y + 0.5 * height - 0.02

	if style == DormerStyle.ARCHED:
		# Lucarne cintrée : le toit suit l'arc de la baie.
		var rise: float = 0.36 * width
		mesh.extrude(Profiles.arched_outline(0.5 * width, height, rise), MeshBuilder.facing_street(Vector3(x, bottom_y, middle_z)), depth, zinc)
		mesh.extrude(Profiles.arched_outline(0.5 * width + 0.08, height + 0.08, rise + 0.04), MeshBuilder.facing_street(Vector3(x, bottom_y, front_z - 0.03)), 0.12, zinc)
		window_size = Vector2(width - 0.3, height - 0.3)
		window_y = bottom_y + 0.14 + 0.5 * window_size.y
		custom = Color(SHAPE_ARCH, (rise - 0.1) / (0.5 * window_size.x), 0.0, 0.0)
	elif style == DormerStyle.BULLSEYE:
		# Œil-de-bœuf : une baie ronde sous un toit en plein cintre.
		var body_height: float = minf(height, 1.3)
		mesh.extrude(Profiles.arched_outline(0.5 * width, body_height, 0.5 * width), MeshBuilder.facing_street(Vector3(x, bottom_y, middle_z)), depth, zinc)
		mesh.extrude(Profiles.arched_outline(0.5 * width + 0.08, body_height + 0.08, 0.5 * width + 0.08), MeshBuilder.facing_street(Vector3(x, bottom_y, front_z - 0.03)), 0.12, zinc)
		var diameter: float = width - 0.34
		window_size = Vector2(diameter, diameter)
		window_y = bottom_y + body_height - 0.5 * width
		custom = Color(SHAPE_OVAL, 0.0, 0.0, 0.0)
	else:
		mesh.box(Vector3(width, height, depth), Vector3(x, bottom_y + 0.5 * height, middle_z), zinc)
		if style == DormerStyle.PEDIMENT:
			# Fronton triangulaire débordant.
			var pediment: PackedVector2Array = PackedVector2Array([Vector2(-0.5 * width - 0.14, 0.0), Vector2(0.5 * width + 0.14, 0.0), Vector2(0.0, 0.42)])
			mesh.extrude(pediment, MeshBuilder.facing_street(Vector3(x, bottom_y + height, middle_z + 0.06)), depth + 0.12, zinc)
			mesh.box(Vector3(width + 0.3, 0.07, 0.1), Vector3(x, bottom_y + height + 0.01, front_z + 0.03), zinc)
		else:
			# Toit plat débordant.
			mesh.box(Vector3(width + 0.24, 0.1, depth + 0.2), Vector3(x, bottom_y + height + 0.05, middle_z + 0.02), zinc)
		glass_z = front_z + 0.006
#@ 13+
	# La fenêtre ne porte pas d'ombre.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	mesh.panel(window_size, Transform3D(Basis.IDENTITY, Vector3(x, window_y, glass_z)), materials.dormer_window, custom)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Souches de cheminée aux deux mitoyens, coiffées de mitrons en terre cuite.
static func _chimneys(mesh: MeshBuilder, materials: Materials, width: float, depth: float, base_y: float, stack_height: float) -> void:
	var stack_length: float = minf(2.6, 0.3 * depth)
	var stack_z: float = -0.34 * depth
	var pot_count: int = maxi(int(stack_length / 0.5), 1)
	for side: float in [-1.0, 1.0]:
		# En léger retrait du mitoyen, pour ne pas se confondre avec le plan du pignon.
		var x: float = side * (0.5 * width - 0.33)
		mesh.box(Vector3(0.6, stack_height, stack_length), Vector3(x, base_y + 0.5 * stack_height, stack_z), materials.stone)
		mesh.box(Vector3(0.7, 0.16, stack_length + 0.1), Vector3(x, base_y + stack_height + 0.08, stack_z), materials.stone)
#@ 9-12
		for pot: int in range(pot_count):
			var pot_z: float = stack_z + (float(pot) - 0.5 * float(pot_count - 1)) * 0.5
			mesh.cone(Vector3(x, base_y + stack_height + 0.41, pot_z), 0.12, 0.09, 0.5, materials.clay)
#@ 13+
		# Mitrons : douze pans de près, six à mi-distance, plus rien de loin. Un même objet
		# peut ainsi avoir plusieurs finesses, une par zone.
		for pot: int in range(pot_count):
			var pot_z: float = stack_z + (float(pot) - 0.5 * float(pot_count - 1)) * 0.5
			mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
			mesh.cone(Vector3(x, base_y + stack_height + 0.41, pot_z), 0.12, 0.09, 0.5, materials.clay)
			mesh.set_zones(MeshBuilder.ZONE_MID, false)
			mesh.cone(Vector3(x, base_y + stack_height + 0.41, pot_z), 0.12, 0.09, 0.5, materials.clay, Basis.IDENTITY, 6)
		mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all
