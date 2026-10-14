@tool
extends RefCounted
## Boutiques du rez-de-chaussée, de deux sortes :
##   - devanture de bois en applique : bandeau d'enseigne, pilastres, vitrines sur soubassement,
##     porte vitrée, store ;
##   - vitrine pleine surface : une seule glace du seuil au linteau dans un cadre de métal fin,
##     entre les trumeaux de pierre laissés nus.
## Les teintes, les noms et la répartition sont tirés au sort.
## {STATUS}
##
## Les listes où l'on tire (noms d'enseigne, teintes de bois, de toile, de métal) ne sont pas
## dans ce script : ce sont des données de conception, rangées dans « 5_data ». Changer la
## liste des boutiques ne demande pas de toucher au code.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")
const Profiles := preload("{MESH}_profils.gd")
const Palette := preload("{DATA}_palette.gd")

## Retrait des vitrines par rapport au nu du mur.
const RECESS: float = 0.22
const RISER_HEIGHT: float = 0.55
const FONT_SIZE: int = 96


## Habille de boutiques les travées dont les abscisses sont dans « bay_centers » (triées).
## Deux travées voisines peuvent former une seule boutique. « opening » : taille de la baie
## de pierre, « sill » : hauteur de son seuil, « level_height » : hauteur du rez-de-chaussée.
## « showcase_share » : part des boutiques à vitrine pleine surface.
static func build(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, bay_centers: PackedFloat32Array,
		bay_width: float, opening: Vector2, sill: float, base_y: float, level_height: float, awnings: bool, showcase_share: float) -> void:
	# Regroupe les travées en boutiques d'une ou deux travées.
	var shops: Array[PackedFloat32Array] = []
	var index: int = 0
	while index < bay_centers.size():
		var wanted: int = random.randi_range(1, 2)
		var shop: PackedFloat32Array = PackedFloat32Array([bay_centers[index]])
		while shop.size() < wanted and index + 1 < bay_centers.size() and absf(bay_centers[index + 1] - bay_centers[index] - bay_width) < 0.01:
			index += 1
			shop.append(bay_centers[index])
		index += 1
		shops.append(shop)

	# Les noms sont tirés sans remise : pas deux fois la même enseigne sur un immeuble.
	var names: Array[String] = []
	names.assign(Palette.SHOP_NAMES)
	_shuffle(names, random)

	# Vitrines pleine surface : la part demandée est un minimum dès qu'il y a deux boutiques.
	var order: Array[int] = []
	order.assign(range(shops.size()))
	_shuffle(order, random)
	var showcase_count: int = ceili(showcase_share * float(shops.size()) - 0.001)
	if shops.size() == 1:
		showcase_count = 1 if random.randf() < showcase_share else 0
	var showcases: Array[int] = order.slice(0, showcase_count)

	for shop_index: int in range(shops.size()):
		var shop_name: String = names[shop_index % names.size()]
		if showcases.has(shop_index):
			_build_showcase(mesh, materials, random, shop_name, shops[shop_index], opening, sill, base_y, level_height)
		else:
			_build_wooden_front(mesh, materials, random, shop_name, shops[shop_index], bay_width, opening, sill, base_y, level_height, awnings)


# --- Devanture de bois en applique ------------------------------------------

static func _build_wooden_front(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, shop_name: String, bays: PackedFloat32Array,
		bay_width: float, opening: Vector2, sill: float, base_y: float, level_height: float, awnings: bool) -> void:
	var color: Color = Palette.SHOP_WOOD_COLORS[random.randi_range(0, Palette.SHOP_WOOD_COLORS.size() - 1)]
	var wood: ShaderMaterial = materials.painted_wood(color)
	var left: float = bays[0] - 0.5 * bay_width + 0.03
	var right: float = bays[bays.size() - 1] + 0.5 * bay_width - 0.03
	var center_x: float = 0.5 * (left + right)
	var shop_width: float = right - left
	var bottom: float = base_y + sill
	var opening_top: float = bottom + opening.y
	var fascia: float = clampf(level_height - (sill + opening.y) - 0.2, 0.3, 0.6)

	# Bandeau d'enseigne et sa petite corniche.
	mesh.box(Vector3(shop_width, fascia, 0.12), Vector3(center_x, opening_top + 0.5 * fascia, 0.06), wood)
#@ 13+
	# La corniche du bandeau : de près seulement.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	mesh.extrude(Profiles.string_course(0.08, 0.08), MeshBuilder.along_x(Vector3(center_x, opening_top + fascia, 0.12)), shop_width + 0.06, wood)
	var ink: Color = Palette.SIGN_GILT if color.get_luminance() < 0.25 else Palette.SIGN_DARK_INK
#@ 13+
	# L'enseigne : de loin, ses lettres ne se lisent plus.
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	mesh.node(_sign(shop_name, ink, Vector3(center_x, opening_top + 0.5 * fascia, 0.125), 0.5 * fascia, shop_width - 0.5))
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# Pilastres de bois devant les trumeaux de pierre.
	var pier: float = bay_width - opening.x
	var pilaster_height: float = opening_top - base_y
	for edge: int in range(bays.size() + 1):
		var x: float = bays[0] - 0.5 * bay_width + float(edge) * bay_width
		var pilaster_width: float = pier - 0.02
		if edge == 0 or edge == bays.size():
			# Demi-trumeau en bout de boutique.
			pilaster_width = 0.5 * pier - 0.04
			x += (0.25 * pier + 0.01) * (1.0 if edge == 0 else -1.0)
		mesh.box(Vector3(pilaster_width, pilaster_height, 0.07), Vector3(x, base_y + 0.5 * pilaster_height, 0.035), wood)
#@ 13+
		# Le fût du pilastre se voit de partout ; sa base et son chapiteau, de près seulement.
		mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
		mesh.box(Vector3(pilaster_width + 0.03, 0.32, 0.09), Vector3(x, base_y + 0.16, 0.045), wood)
		mesh.box(Vector3(pilaster_width + 0.03, 0.07, 0.09), Vector3(x, opening_top - 0.035, 0.045), wood)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# Une travée reçoit la porte vitrée, les autres une vitrine sur soubassement.
	var entrance: int = random.randi_range(0, bays.size() - 1)
	for bay: int in range(bays.size()):
		var x: float = bays[bay]
		var glass_bottom: float = bottom
		if bay != entrance or bays.size() == 1:
			glass_bottom += RISER_HEIGHT
			mesh.box(Vector3(opening.x, RISER_HEIGHT, 0.1), Vector3(x, bottom + 0.5 * RISER_HEIGHT, -RECESS + 0.08), wood)
#@ 13+
			# Le panneau en relief du soubassement : de près seulement.
			mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
			mesh.box(Vector3(opening.x - 0.3, RISER_HEIGHT - 0.2, 0.02), Vector3(x, bottom + 0.5 * RISER_HEIGHT, -RECESS + 0.14), wood)
		var glass: Vector2 = Vector2(opening.x, opening_top - glass_bottom)
#@ 13+
		# La vitrine : à toute distance, sans ombre portée.
		mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
		mesh.panel(glass, Transform3D(Basis.IDENTITY, Vector3(x, glass_bottom + 0.5 * glass.y, -RECESS)), materials.shop_window, Color(0.0, 0.0, 0.0, 0.0), color)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	if awnings and random.randf() < 0.6:
		_awning(mesh, materials, Palette.AWNING_COLORS[random.randi_range(0, Palette.AWNING_COLORS.size() - 1)], center_x, opening_top - 0.03, shop_width - 0.3)


# --- Vitrine pleine surface -------------------------------------------------

static func _build_showcase(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, shop_name: String, bays: PackedFloat32Array,
		opening: Vector2, sill: float, base_y: float, level_height: float) -> void:
	var metal_color: Color = Palette.SHOP_METAL_COLORS[random.randi_range(0, Palette.SHOP_METAL_COLORS.size() - 1)]
	var metal: StandardMaterial3D = materials.lacquer(metal_color)
	var bottom: float = base_y + sill
	var opening_top: float = bottom + opening.y
	var left: float = bays[0] - 0.5 * opening.x
	var right: float = bays[bays.size() - 1] + 0.5 * opening.x
	var center_x: float = 0.5 * (left + right)

	# Une glace par baie de pierre, du seuil au linteau.
	var entrance: int = random.randi_range(0, bays.size() - 1)
	for bay: int in range(bays.size()):
		var x: float = bays[bay]
#@ 13+
		# La glace : à toute distance, sans ombre portée.
		mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ all
		mesh.panel(opening, Transform3D(Basis.IDENTITY, Vector3(x, bottom + 0.5 * opening.y, -RECESS)), materials.showcase_window, Color(0.0, 0.0, 0.0, 0.0), metal_color)
#@ 13+
		# Le cadre de la porte de verre et sa poignée : de près seulement.
		mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
		if bay == entrance:
			# Porte de verre : un cadre fin et une poignée tubulaire devant la glace.
			var door_height: float = minf(2.25, opening.y - 0.3)
			var face: float = -RECESS + 0.02
			for side: float in [-1.0, 1.0]:
				mesh.box(Vector3(0.035, door_height, 0.03), Vector3(x + side * 0.48, bottom + 0.5 * door_height, face), metal)
			mesh.box(Vector3(0.995, 0.035, 0.03), Vector3(x, bottom + door_height, face), metal)
			mesh.box(Vector3(0.03, 0.6, 0.03), Vector3(x + 0.38, bottom + 1.1, face + 0.05), materials.brass)
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all

	# Enseigne : un bandeau plat de couleur, ou des lettres posées sur la pierre.
	var lintel: float = level_height - (sill + opening.y)
	var letter: float = clampf(0.42 * lintel, 0.16, 0.3)
	var sign_y: float = opening_top + 0.5 * lintel - 0.06
	if random.randf() < 0.55:
		var band_color: Color = Palette.SHOP_BAND_COLORS[random.randi_range(0, Palette.SHOP_BAND_COLORS.size() - 1)]
		var band_height: float = clampf(lintel - 0.32, 0.26, 0.5)
		mesh.box(Vector3(right - left, band_height, 0.04), Vector3(center_x, sign_y, 0.02), materials.lacquer(band_color))
		var ink: Color = Palette.SIGN_PALE_INK if band_color.get_luminance() < 0.4 else Palette.SIGN_DARK_INK
#@ 13+
		# L'enseigne : de près et à mi-distance.
		mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
		mesh.node(_sign(shop_name, ink, Vector3(center_x, sign_y, 0.045), minf(letter, 0.6 * band_height), right - left - 0.3))
	else:
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
		# Sur la pierre blonde, seules des lettres sombres restent lisibles.
		mesh.node(_sign(shop_name, Palette.SIGN_DARK_INK, Vector3(center_x, sign_y, 0.012), letter, right - left - 0.2))
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


# --- Parties communes -------------------------------------------------------

## Lettres d'enseigne de hauteur « letter », réduites si le nom dépasse « max_width ».
static func _sign(text: String, ink: Color, position: Vector3, letter: float, max_width: float) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = FONT_SIZE
	label.outline_size = 0
	# Une capitale de la police par défaut est à peu près aussi large que haute, espacement compris.
	var height: float = minf(letter, max_width / (0.95 * float(text.length())))
	label.pixel_size = height / (0.7 * float(FONT_SIZE))
	label.modulate = ink
	label.shaded = true
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.position = position
	return label


## Store banne : une toile en pente, son lambrequin et deux bras.
static func _awning(mesh: MeshBuilder, materials: Materials, color: Color, center_x: float, top_y: float, width: float) -> void:
	var fabric: ShaderMaterial = materials.awning(color)
	var reach: float = 1.25
	var drop: float = 0.5
	var length: float = sqrt(reach * reach + drop * drop)
	var tilt: Basis = Basis(Vector3.RIGHT, atan2(drop, reach))
	var middle: Vector3 = Vector3(center_x, top_y - 0.5 * drop, 0.13 + 0.5 * reach)
	mesh.box(Vector3(width, 0.012, length), middle, fabric, tilt)
	mesh.box(Vector3(width, 0.2, 0.012), Vector3(center_x, top_y - drop - 0.1, 0.13 + reach), fabric)
#@ 13+
	# Les bras du store : de près seulement.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	for side: float in [-1.0, 1.0]:
		mesh.box(Vector3(0.025, 0.025, length), middle + Vector3(side * 0.5 * width, -0.02, 0.0), materials.iron, tilt)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Mélange un tableau sur place avec le générateur de l'immeuble (Fisher-Yates).
static func _shuffle(items: Array[Variant], random: RandomNumberGenerator) -> void:
	for last: int in range(items.size() - 1, 0, -1):
		var other: int = random.randi_range(0, last)
		var swapped: Variant = items[last]
		items[last] = items[other]
		items[other] = swapped
