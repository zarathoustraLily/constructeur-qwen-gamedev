@tool
extends RefCounted
## Enseignes : caisson au-dessus de la boutique, enseigne en drapeau à plaques, panneau sur le
## toit, distributeur de boissons, lanterne.
## {STATUS}
##
## Une enseigne, ici, c'est trois choses superposées :
##   - un caisson : une boîte de métal sombre ;
##   - une face : un rectangle instancié, dont le shader fait le fond, le cadre, la lumière de
##     nuit, et au besoin une fausse écriture ;
##   - le texte : un Label3D, le nœud de Godot qui écrit du vrai texte dans la scène.
#@ 13+ quiet
## Le vrai texte coûte un nœud et un appel de dessin par enseigne : il n'est posé que de près.
## Au-delà, la même face est redessinée avec la fausse écriture du shader.
#@ all
##
## Les caractères japonais viennent d'une police du système (SystemFont) : le projet n'embarque
## aucun fichier de police. La liste des polices essayées est dans la palette (5_data).
##
## Tout est « static » : le script de l'immeuble appelle SignBuilder.fascia(...) sans créer
## d'objet.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")
const Palette := preload("{DATA}_palette.gd")

## Sortes d'enseigne du shader : caisson lumineux, panneau peint, distributeur.
const KIND_LIGHT_BOX: float = 0.0
const KIND_PAINTED: float = 1.0
const KIND_VENDING: float = 2.0
## Taille de police des Label3D. Plus elle est grande, plus les lettres sont nettes de près.
const FONT_SIZE: int = 96
## Saillie d'un caisson mural. La palette donne la saillie permise : fascia() s'y tient.
const BOX_DEPTH: float = 0.12
## Écart entre un rectangle et la face pleine qu'il recouvre, quand il se voit de loin. À
## 100 m, la carte graphique ne distingue plus deux faces séparées de quelques millimètres.
const FAR_OFFSET: float = 0.03

## La police des enseignes, créée à la première demande et partagée par toutes.
static var _font: SystemFont


## Police des enseignes : la première de la liste de la palette que le système possède.
static func sign_font() -> Font:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = Palette.SIGN_FONTS
		_font.font_weight = 700
	return _font


## Encre lisible sur un fond de cette teinte : claire sur fond sombre, sombre sur fond clair.
## Le shader des enseignes applique la même règle à sa fausse écriture.
static func ink_for(background: Color) -> Color:
	return Palette.SIGN_PALE_INK if background.get_luminance() < 0.42 else Palette.SIGN_DARK_INK


## Caisson d'enseigne posé à plat sur le mur, face à la rue. « center » : le milieu de sa face
## arrière, contre le mur ; « size » : sa largeur et sa hauteur.
static func fascia(mesh: MeshBuilder, materials: Materials, text: String, color: Color, center: Vector3, size: Vector2) -> void:
	# Une enseigne murale ne dépasse pas la saillie permise. On garde 5 cm pour sa face.
	var box_depth: float = minf(BOX_DEPTH, Palette.WALL_SIGN_MAX_PROJECTION - 0.05)
	mesh.box(Vector3(size.x, size.y, box_depth), center + Vector3(0.0, 0.0, 0.5 * box_depth), materials.dark_metal)
	var face: Transform3D = Transform3D(Basis.IDENTITY, center + Vector3(0.0, 0.0, box_depth + 0.004))
	_face(mesh, materials, text, color, face, size - Vector2(0.04, 0.04), false)


## Enseigne en drapeau : un caisson vertical perpendiculaire à la façade, avec une plaque par
## occupant sur chacune de ses deux faces. « edge_x » : le bord de la façade où elle
## s'accroche ; « bottom_y » : son point le plus bas ; « floor_tops » : la hauteur du plancher
## haut de chaque étage qu'elle longe.
static func projecting(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, edge_x: float, bottom_y: float,
		floor_tops: PackedFloat32Array, japanese: bool) -> void:
	if floor_tops.is_empty():
		return
	# Elle ne descend pas sous la hauteur libre exigée au-dessus de la voie.
	var low: float = maxf(bottom_y, Palette.SIGN_MIN_CLEARANCE)
	var high: float = floor_tops[floor_tops.size() - 1] - 0.3
	if high - low < 1.5:
		return
	# Sa saillie reste sous le mètre permis.
	var reach: float = minf(0.8, Palette.SIGN_MAX_PROJECTION - 0.15)
	var thickness: float = 0.18
	var side: float = signf(edge_x)
	var x: float = edge_x - side * 0.3
	var middle: Vector3 = Vector3(x, 0.5 * (low + high), 0.12 + 0.5 * reach)
	mesh.box(Vector3(thickness, high - low, reach), middle, materials.dark_metal)
	# Deux potences la tiennent au mur.
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	for bracket_y: float in [low + 0.25, high - 0.25]:
		mesh.box(Vector3(0.05, 0.05, 0.14), Vector3(x, bracket_y, 0.06), materials.dark_metal)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# Une plaque par occupant. Les noms sont tirés sans remise : pas deux fois le même.
	var tenants: Array[Array] = []
	tenants.assign(Palette.TENANTS)
	_shuffle(tenants, random)
	var count: int = clampi(roundi((high - low) / 1.5), 1, mini(6, tenants.size()))
	var plate: Vector2 = Vector2(reach - 0.06, (high - low) / float(count) - 0.05)
	for index: int in range(count):
		var tenant: PackedStringArray = PackedStringArray(tenants[index])
		var color: Color = Palette.SIGN_COLORS[random.randi_range(0, Palette.SIGN_COLORS.size() - 1)]
		var plate_y: float = high - (float(index) + 0.5) * (high - low) / float(count)
		# Une face de chaque côté du caisson : le repère est tourné d'un quart de tour, dans un
		# sens puis dans l'autre.
		for face_side: float in [-1.0, 1.0]:
			var frame: Transform3D = Transform3D(Basis(Vector3.UP, face_side * 0.5 * PI), Vector3(x + face_side * (0.5 * thickness + 0.004), plate_y, middle.z))
			_face(mesh, materials, tenant[0] if japanese else tenant[1], color, frame, plate, true)


## Panneau publicitaire dressé sur le toit, face à la rue.
static func rooftop(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, width: float, base_y: float, setback: float, japanese: bool) -> void:
	var size: Vector2 = Vector2(minf(width - 0.6, 5.0), 2.2)
	var center: Vector3 = Vector3(0.0, base_y + 0.7 + 0.5 * size.y, -setback - 0.45)
	# Ses pieds : deux poteaux et deux jambes de force, en boîtes.
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	for side: float in [-1.0, 1.0]:
		var foot_x: float = side * 0.35 * size.x
		mesh.box(Vector3(0.1, 0.7 + size.y, 0.1), Vector3(foot_x, base_y + 0.5 * (0.7 + size.y), center.z - 0.1), materials.dark_metal)
		mesh.box(Vector3(0.08, 0.08, 1.9), Vector3(foot_x, base_y + 0.95, center.z - 0.85), materials.dark_metal, Basis(Vector3.RIGHT, -0.9))
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all
	var tenant: PackedStringArray = PackedStringArray(Palette.TENANTS[random.randi_range(0, Palette.TENANTS.size() - 1)])
	var color: Color = Palette.SIGN_COLORS[random.randi_range(0, Palette.SIGN_COLORS.size() - 1)]
	fascia(mesh, materials, tenant[0] if japanese else tenant[1], color, center, size)


## Distributeur de boissons adossé à la façade. « foot » : le milieu de son pied, contre le mur.
static func vending(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, foot: Vector3, width: float) -> void:
	var size: Vector3 = Vector3(width, 1.83, 0.68)
	var color: Color = Palette.VENDING_COLORS[random.randi_range(0, Palette.VENDING_COLORS.size() - 1)]
	var center: Vector3 = foot + Vector3(0.0, 0.5 * size.y, 0.02 + 0.5 * size.z)
	mesh.box(size, center, materials.lacquer(color))
#@ 13+
	# Sa façade éclairée : à toute distance, sans ombre portée.
	mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
	# Sa façade : la vitrine de canettes est dessinée par le shader des enseignes.
	mesh.panel(Vector2(size.x - 0.04, size.y - 0.06), Transform3D(Basis.IDENTITY, center + Vector3(0.0, 0.0, 0.5 * size.z + FAR_OFFSET)),
			materials.signage, Color(0.0, 0.0, random.randf_range(0.0, 50.0), KIND_VENDING), color)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Lanterne de papier rouge, pendue en « position » (son milieu) : deux troncs de cône dos à
## dos, entre deux bagues noires.
static func lantern(mesh: MeshBuilder, materials: Materials, position: Vector3) -> void:
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	mesh.cone(position + Vector3(0.0, 0.1, 0.0), 0.15, 0.09, 0.2, materials.lantern, Basis.IDENTITY, 10)
	mesh.cone(position + Vector3(0.0, -0.1, 0.0), 0.09, 0.15, 0.2, materials.lantern, Basis.IDENTITY, 10)
	for cap: float in [-1.0, 1.0]:
		mesh.cone(position + Vector3(0.0, cap * 0.22, 0.0), 0.07, 0.07, 0.04, materials.dark_metal, Basis.IDENTITY, 10)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


# --- Parties communes -------------------------------------------------------

## Face d'une enseigne : le rectangle que le shader habille, et son texte. « frame » : où est
## son centre et vers où elle regarde ; « vertical » : écriture de haut en bas.
static func _face(mesh: MeshBuilder, materials: Materials, text: String, color: Color, frame: Transform3D, size: Vector2, vertical: bool) -> void:
	var seed_value: float = float(text.hash() % 97)
#@ 10-12
	# Le rectangle, sans fausse écriture : le vrai texte vient par-dessus.
	mesh.panel(size, frame, materials.signage, Color(0.0, 0.0, seed_value, KIND_LIGHT_BOX), color)
	mesh.node(_label(text, ink_for(color), frame, size, vertical))
#@ 13+
	# De près : le rectangle sans fausse écriture, et le vrai texte par-dessus.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
	mesh.panel(size, frame, materials.signage, Color(0.0, 0.0, seed_value, KIND_LIGHT_BOX), color)
	mesh.node(_label(text, ink_for(color), frame, size, vertical))
	# Au-delà : le même rectangle, où le shader écrit autant de faux caractères que le texte
	# en compte. Un nœud et un appel de dessin de moins par enseigne. Il est posé 3 cm devant
	# son caisson : de loin, la profondeur est mesurée moins finement, et deux faces trop
	# proches se disputeraient les mêmes pixels.
	mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR, false)
	mesh.panel(size, frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, FAR_OFFSET)), materials.signage,
			Color(float(text.length()), 1.0 if vertical else 0.0, seed_value, KIND_LIGHT_BOX), color)
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Le texte d'une enseigne, ajusté à sa face. En écriture verticale, un caractère par ligne.
static func _label(text: String, ink: Color, frame: Transform3D, size: Vector2, vertical: bool) -> Label3D:
	var label: Label3D = Label3D.new()
	label.font = sign_font()
	label.font_size = FONT_SIZE
	label.outline_size = 0
	label.modulate = ink
	# Une enseigne lumineuse ne dépend pas de l'éclairage de la rue : son texte non plus.
	label.shaded = false
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD

	# Largeur d'un caractère, en hauteurs de caractère : un idéogramme est carré, une lettre
	# latine plus étroite.
	var advance: float = 0.0
	for index: int in range(text.length()):
		advance += 1.0 if text.unicode_at(index) > 0x2E7F else 0.68
	var height: float
	if vertical:
		# Un caractère par ligne : on insère un retour à la ligne entre deux caractères.
		var lines: PackedStringArray = PackedStringArray()
		for index: int in range(text.length()):
			lines.append(text[index])
		label.text = "\n".join(lines)
		# Les lignes d'une police sont plus espacées que ses caractères ne sont hauts : on les
		# resserre.
		label.line_spacing = -0.22 * float(FONT_SIZE)
		height = minf(0.62 * size.x, 0.9 * size.y / (1.08 * float(text.length())))
	else:
		label.text = text
		height = minf(0.62 * size.y, 0.9 * size.x / maxf(advance, 1.0))
	# « pixel_size » règle la taille du texte dans la scène : un caractère de FONT_SIZE pixels
	# doit mesurer « height » mètres.
	label.pixel_size = height / float(FONT_SIZE)
	# Le texte est posé un demi-centimètre devant sa face.
	label.transform = frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.005))
	return label


## Mélange un tableau sur place avec le générateur de l'immeuble (Fisher-Yates).
static func _shuffle(items: Array[Variant], random: RandomNumberGenerator) -> void:
	for last: int in range(items.size() - 1, 0, -1):
		var other: int = random.randi_range(0, last)
		var swapped: Variant = items[last]
		items[last] = items[other]
		items[other] = swapped
