@tool
extends RefCounted
## Devanture du rez-de-chaussée, de trois sortes :
##   - un magasin : une vitrine de verre du sol au coffre du rideau, et une porte de verre ;
##   - un restaurant : un mur de bois, une fenêtre basse, une porte coulissante sous un rideau
##     de toile (noren), une lanterne rouge ;
##   - un service : la même vitrine que le magasin, couverte d'affichettes.
## Devant, un rideau métallique plus ou moins baissé ; au-dessus, l'enseigne.
## La sorte, le nom et les teintes sont tirés au sort.
## {STATUS}
##
## Les listes où l'on tire (noms, teintes) ne sont pas dans ce script : ce sont des données de
## conception, rangées dans « 5_data ». Ajouter une boutique ne demande pas de toucher au code.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")
const SignBuilder := preload("{MESH}_enseignes.gd")
const Palette := preload("{DATA}_palette.gd")

## Sortes de pièce du shader de fenêtre : vitrine, porte de boutique.
const KIND_SHOP: float = 3.0
const KIND_SHOP_DOOR: float = 4.0
## États du rideau métallique.
const SHUTTER_UP: int = 1
const SHUTTER_HALF: int = 2
const SHUTTER_DOWN: int = 3
## Retrait des vitrages par rapport au nu du mur.
const RECESS: float = 0.12
## Hauteur du coffre où s'enroule le rideau.
const SHUTTER_BOX_HEIGHT: float = 0.3
## Largeur d'une porte de boutique.
const DOOR_WIDTH: float = 0.95


## Habille l'ouverture qui va de l'abscisse « left » à « right » et du sol à « opening_top ».
## « lintel_height » : hauteur du bandeau de mur au-dessus, où se pose l'enseigne.
## « shutter_choice » : SHUTTER_UP, SHUTTER_HALF ou SHUTTER_DOWN.
static func build(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, left: float, right: float, opening_top: float,
		lintel_height: float, shutter_choice: int, fascia_sign: bool, japanese: bool) -> void:
	var width: float = right - left
	var center_x: float = 0.5 * (left + right)

	# 1. Les tirages : quelle boutique, de quelles teintes.
	var entry: Array[Variant] = Palette.SHOPS[random.randi_range(0, Palette.SHOPS.size() - 1)]
	var kind: int = entry[2]
	var shop_name: String = entry[0] if japanese else entry[1]
	var frame_color: Color = Palette.SHOP_FRAME_COLORS[random.randi_range(0, Palette.SHOP_FRAME_COLORS.size() - 1)]
	var sign_color: Color = Palette.SIGN_COLORS[random.randi_range(0, Palette.SIGN_COLORS.size() - 1)]
	var shutter_color: Color = Palette.SHUTTER_COLORS[random.randi_range(0, Palette.SHUTTER_COLORS.size() - 1)]
	# La porte est à un bout de la devanture ou à l'autre.
	var door_side: float = -1.0 if random.randf() < 0.5 else 1.0
	# La part du rideau métallique qui est baissée. Un restaurant ne le baisse pas à moitié.
	# La hauteur d'un rideau à moitié baissé est tirée dans tous les cas : imposer l'état du
	# rideau ne décale pas les tirages suivants.
	var half_lowered: float = random.randf_range(0.3, 0.6)
	var lowered: float = 0.0
	if shutter_choice == SHUTTER_DOWN:
		lowered = 1.0
	elif shutter_choice == SHUTTER_HALF and kind != Palette.SHOP_RESTAURANT:
		lowered = half_lowered

	# 2. Le coffre où s'enroule le rideau, sous le bandeau de mur.
	var glass_top: float = opening_top - SHUTTER_BOX_HEIGHT
	mesh.box(Vector3(width, SHUTTER_BOX_HEIGHT, 0.26), Vector3(center_x, opening_top - 0.5 * SHUTTER_BOX_HEIGHT, -0.11), materials.dark_metal)

	# 3. Ce qui ferme l'ouverture, selon la sorte de boutique.
	var door: Vector2 = Vector2(minf(DOOR_WIDTH, width), minf(2.05, glass_top))
	var door_x: float = center_x + door_side * 0.5 * (width - door.x)
	var rest_left: float = left if door_side > 0.0 else left + door.x
	var rest_right: float = right - door.x if door_side > 0.0 else right
	if kind == Palette.SHOP_RESTAURANT:
		_restaurant(mesh, materials, random, shop_name, rest_left, rest_right, glass_top, door, door_x, lowered < 1.0)
	else:
		_glazing(mesh, materials, frame_color, rest_left, rest_right, glass_top, door, door_x)
		if kind == Palette.SHOP_SERVICE:
			_notices(mesh, materials, random, rest_left, rest_right, glass_top)

	# 4. Le rideau métallique : un rectangle instancié devant les vitrages. Son shader dessine
	#    les lames ; sa hauteur est la part baissée.
	if lowered > 0.0:
		var curtain: Vector2 = Vector2(width, lowered * glass_top)
#@ 13+
		# À toute distance, sans ombre portée : il est dans l'épaisseur du mur.
		mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
		mesh.panel(curtain, Transform3D(Basis.IDENTITY, Vector3(center_x, glass_top - 0.5 * curtain.y, -0.04)), materials.shutter, Color(0.0, 0.0, 0.0, 0.0), shutter_color)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# 5. L'enseigne, sur le bandeau de mur.
	if fascia_sign:
		var size: Vector2 = Vector2(minf(width, 4.5), lintel_height - 0.22)
		SignBuilder.fascia(mesh, materials, shop_name, sign_color, Vector3(center_x, opening_top + 0.14 + 0.5 * size.y, 0.0), size)


# --- Magasin et service -----------------------------------------------------

## Vitrine et porte de verre. Ce sont deux rectangles instanciés ; le shader de fenêtre y
## dessine les montants, les glaces, et la boutique derrière. La donnée de l'instance lui dit
## « vitrine » ou « porte » ; la couleur de l'instance, la teinte des menuiseries.
static func _glazing(mesh: MeshBuilder, materials: Materials, frame_color: Color, left: float, right: float, glass_top: float,
		door: Vector2, door_x: float) -> void:
#@ 13+
	# À toute distance, sans ombre portée.
	mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
	if right - left > 0.2:
		mesh.panel(Vector2(right - left, glass_top), Transform3D(Basis.IDENTITY, Vector3(0.5 * (left + right), 0.5 * glass_top, -RECESS)),
				materials.shop_window, Color(KIND_SHOP, 0.0, 0.0, 0.0), frame_color)
	mesh.panel(door, Transform3D(Basis.IDENTITY, Vector3(door_x, 0.5 * door.y, -RECESS)), materials.shop_window, Color(KIND_SHOP_DOOR, 0.0, 0.0, 0.0), frame_color)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all
	# Au-dessus de la porte, jusqu'au coffre : une imposte pleine.
	if glass_top - door.y > 0.02:
		mesh.box(Vector3(door.x, glass_top - door.y, 0.05), Vector3(door_x, 0.5 * (glass_top + door.y), -RECESS), materials.lacquer(frame_color))


## Affichettes collées sur la vitrine d'un service : des feuilles blanches en rangs. Chaque
## feuille est un rectangle instancié de plus, où le shader des enseignes écrit quelques faux
## caractères.
static func _notices(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, left: float, right: float, glass_top: float) -> void:
	var sheet: Vector2 = Vector2(0.3, 0.42)
	var columns: int = int((right - left - 0.3) / (sheet.x + 0.06))
	var rows: int = clampi(int((glass_top - 1.0) / (sheet.y + 0.06)), 1, 3)
#@ 13+
	# De loin, ces feuilles ne se distinguent plus de la vitrine.
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	for row: int in range(rows):
		for column: int in range(columns):
			# Une feuille sur cinq manque.
			if random.randf() < 0.2:
				continue
			var x: float = left + 0.2 + (float(column) + 0.5) * (sheet.x + 0.06)
			var y: float = 0.75 + (float(row) + 0.5) * (sheet.y + 0.06)
			mesh.panel(sheet, Transform3D(Basis.IDENTITY, Vector3(x, y, -RECESS + 0.02)), materials.signage,
					Color(3.0, 0.0, random.randf_range(0.0, 50.0), SignBuilder.KIND_PAINTED), Color(0.93, 0.93, 0.90))
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


# --- Restaurant -------------------------------------------------------------

## Façade de restaurant : un mur habillé de bois, une fenêtre en longueur, une porte
## coulissante et, quand il est ouvert, un rideau de toile fendu (noren) et une lanterne.
static func _restaurant(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, shop_name: String,
		left: float, right: float, glass_top: float, door: Vector2, door_x: float, open: bool) -> void:
	var wood_color: Color = Palette.SHOP_FRAME_COLORS[3 + random.randi_range(0, 1)]
	var wood: StandardMaterial3D = materials.lacquer(wood_color)
	var width: float = right - left
	var center_x: float = 0.5 * (left + right)
	# La fenêtre : une bande de verre à hauteur de table.
	var window_low: float = 0.95
	var window_high: float = minf(1.85, glass_top - 0.2)
	if width > 0.2:
		# Le mur de bois sous la fenêtre, puis au-dessus.
		mesh.box(Vector3(width, window_low, 0.06), Vector3(center_x, 0.5 * window_low, -RECESS), wood)
		mesh.box(Vector3(width, glass_top - window_high, 0.06), Vector3(center_x, 0.5 * (glass_top + window_high), -RECESS), wood)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
		# La donnée de l'instance : « vitrine », la hauteur de l'allège, et 1 pour « restaurant ».
		mesh.panel(Vector2(width, window_high - window_low), Transform3D(Basis.IDENTITY, Vector3(center_x, 0.5 * (window_low + window_high), -RECESS)),
				materials.shop_window, Color(KIND_SHOP, window_low, 1.0, 0.0), wood_color)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
	# La porte, de la teinte du bois.
	mesh.panel(door, Transform3D(Basis.IDENTITY, Vector3(door_x, 0.5 * door.y, -RECESS)), materials.shop_window, Color(KIND_SHOP_DOOR, 0.0, 1.0, 0.0), wood_color)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all
	if glass_top - door.y > 0.02:
		mesh.box(Vector3(door.x, glass_top - door.y, 0.05), Vector3(door_x, 0.5 * (glass_top + door.y), -RECESS), wood)

	# Un restaurant fermé a rentré son rideau de toile et sa lanterne.
	if not open:
		return

	# Le noren : trois pans de toile pendus devant le haut de la porte.
	var cloth_color: Color = Palette.NOREN_COLORS[random.randi_range(0, Palette.NOREN_COLORS.size() - 1)]
	var cloth: StandardMaterial3D = materials.lacquer(cloth_color)
	var strip: Vector2 = Vector2((door.x - 0.04) / 3.0, 0.5)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	for index: int in range(3):
		var strip_x: float = door_x + (float(index) - 1.0) * strip.x
		mesh.box(Vector3(strip.x - 0.02, strip.y, 0.012), Vector3(strip_x, door.y - 0.5 * strip.y + 0.05, 0.03), cloth)
	# Sa tringle.
	mesh.box(Vector3(door.x + 0.1, 0.03, 0.03), Vector3(door_x, door.y + 0.06, 0.03), materials.dark_metal)
#@ 13+
	# Le caractère peint sur le pan du milieu : de près seulement.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	var mark: Label3D = Label3D.new()
	mark.text = shop_name.left(1)
	mark.font = SignBuilder.sign_font()
	mark.font_size = SignBuilder.FONT_SIZE
	mark.pixel_size = 0.26 / float(SignBuilder.FONT_SIZE)
	mark.outline_size = 0
	mark.modulate = SignBuilder.ink_for(cloth_color)
	mark.shaded = true
	mark.double_sided = false
	mark.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	mark.position = Vector3(door_x, door.y - 0.5 * strip.y + 0.05, 0.04)
	mesh.node(mark)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# La lanterne, pendue à côté de la porte, du côté du mur de bois.
	var lantern_side: float = 1.0 if center_x > door_x else -1.0
	SignBuilder.lantern(mesh, materials, Vector3(door_x + lantern_side * (0.5 * door.x + 0.22), 1.95, 0.3))
