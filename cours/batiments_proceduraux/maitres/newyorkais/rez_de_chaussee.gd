@tool
extends RefCounted
## Le rez-de-chaussée de la tour : son entrée, avec ses portes tambour, et ses boutiques.
## {STATUS}
##
## C'est la partie de la tour qu'on voit de plus près : celle qu'on touche. Elle a donc son
## propre script, comme le toit a le sien.
##
## Sur une façade de la tour de brique, le rez-de-chaussée est découpé en morceaux de deux ou
## trois travées : au milieu de la façade de devant, l'entrée de la tour ; partout ailleurs,
## des boutiques. Entre deux morceaux, un pilastre de pierre ; au-dessus de tous, un linteau de
## pierre qui porte les piliers des étages. Chaque boutique a son soubassement, sa vitrine, sa
## porte vitrée et son bandeau d'enseigne, où son nom est écrit par un Label3D, le nœud de
## Godot qui écrit du vrai texte dans la scène.
##
## Les tours de verre n'ont pas de boutiques : leur hall vitré occupe tout le rez-de-chaussée.
## On y pose seulement les portes tambour.
##
## Une porte tambour (« revolving door ») : quatre vantaux qui tournent autour d'un axe, dans
## un tambour de verre. Elle laisse passer les gens sans laisser passer l'air : dans une tour,
## l'air chaud monte comme dans une cheminée, et une porte ordinaire claquerait.
##
## Tout est « static » : le script de la tour appelle GroundBuilder.masonry_face(...) sans
## créer d'objet. Les cotes sont plausibles ; elles ne sont pas relevées sur une tour réelle.
#@ 13+ quiet
##
## Niveaux de détail : le rez-de-chaussée est dessiné de près et à mi-distance ; de loin, le
## rectangle de la façade lointaine le remplace. Les enseignes (un nœud et un appel de dessin
## chacune) et les portes tambour ne sont posées que de près.
#@ all

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")
const Palette := preload("{DATA}_palette.gd")

## Ce qu'il y a derrière une vitre du rez-de-chaussée : les mêmes nombres que dans le shader de
## la fenêtre.
const KIND_LOBBY: float = 1.0
const KIND_SHOP: float = 2.0
const KIND_SHOP_DOOR: float = 3.0
const KIND_DOOR_GLASS: float = 4.0
## Hauteur du linteau de pierre en haut du rez-de-chaussée, du bandeau d'enseigne, du
## soubassement des vitrines ; retrait des vitrines derrière le nu de la façade.
const LINTEL: float = 1.0
const FASCIA: float = 0.6
const BULKHEAD: float = 0.45
const SHOP_RECESS: float = 0.25
## Porte vitrée d'une boutique : largeur, hauteur.
const DOOR_SIZE: Vector2 = Vector2(1.0, 2.4)
## Porte tambour : rayon du tambour, hauteur de passage, nombre de facettes de verre de chaque
## côté.
const DRUM_RADIUS: float = 0.95
const DRUM_HEIGHT: float = 2.4
const DRUM_FACETS: int = 5
## Taille de police des Label3D. Plus elle est grande, plus les lettres sont nettes de près.
const FONT_SIZE: int = 64


## Rez-de-chaussée d'une façade de la tour de brique, dans le repère « frame » de la façade.
## « width » : sa largeur ; « pier » : la largeur d'un pilier des étages ; « height » : la
## hauteur du rez-de-chaussée ; « face » et « first_column » : de quoi donner à chaque vitrine
## sa clé de tirage ; « entrance » : vrai pour la façade de devant, qui porte l'entrée.
static func masonry_face(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, frame: Transform3D,
		width: float, bay_width: float, pier: float, wall_depth: float, projection: float, height: float,
		face: int, first_column: int, entrance: bool) -> void:
	var bays: int = floori(width / bay_width + 0.001)
	var left: float = -0.5 * width + 0.5 * (width - float(bays) * bay_width)
	var opening_top: float = height - LINTEL
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ all
	# Le linteau, sur toute la largeur : il porte les piliers des étages.
	_box(mesh, frame, Vector3(width + 0.006, LINTEL, wall_depth), Vector3(0.0, height - 0.5 * LINTEL, -0.5 * wall_depth), materials.stone)
	# Les deux pilastres des bouts de la façade : de son bord à la première ouverture, et un peu
	# au-delà du bord, pour couvrir l'angle avec la façade voisine.
	for end: float in [-1.0, 1.0]:
		var reach: float = (left + 0.5 * pier) - (-0.5 * width) + projection
		_box(mesh, frame, Vector3(reach, opening_top, wall_depth + projection),
				Vector3(end * (0.5 * width + projection - 0.5 * reach), 0.5 * opening_top, 0.5 * (projection - wall_depth)), materials.stone)

	# Le découpage : l'entrée, trois travées au milieu de la façade de devant ; des boutiques
	# de deux ou trois travées ailleurs. Le dé est lancé à chaque morceau, même quand la place
	# manque : le nombre de tirages ne dépend que de la largeur de la façade.
	var entrance_first: int = floori(float(bays - 3) * 0.5) if entrance and bays >= 5 else -1
	var bay: int = 0
	while bay < bays:
		if bay == entrance_first:
			_entrance(mesh, materials, frame, left + float(bay) * bay_width + 0.5 * pier, left + float(bay + 3) * bay_width - 0.5 * pier, opening_top, face, first_column + bay)
			bay += 3
		else:
			var drawn: int = random.randi_range(2, 3)
			var limit: int = (entrance_first if bay < entrance_first else bays) - bay
			var size: int = mini(drawn, limit)
			_shop(mesh, materials, random, frame, left + float(bay) * bay_width + 0.5 * pier, left + float(bay + size) * bay_width - 0.5 * pier,
					opening_top, face, first_column + bay)
			bay += size
		# Un pilastre de pierre entre deux morceaux.
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ all
		if bay < bays:
			_box(mesh, frame, Vector3(pier, opening_top, wall_depth + projection),
					Vector3(left + float(bay) * bay_width, 0.5 * opening_top, 0.5 * (projection - wall_depth)), materials.stone)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Entrée d'une tour de verre : deux portes tambour sous la marquise, dans le plan du verre du
## hall, au milieu de la façade de devant.
static func glass_entrance(mesh: MeshBuilder, materials: Materials, frame: Transform3D) -> void:
	for side: float in [-1.0, 1.0]:
		revolving_door(mesh, materials, frame, Vector3(side * 1.6, 0.0, 0.0))
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Une boutique entre les abscisses « x0 » et « x1 » : soubassement, vitrine, porte, bandeau
## d'enseigne et son nom. Sa sorte, son nom et sa teinte sont tirés au sort.
static func _shop(mesh: MeshBuilder, materials: Materials, random: RandomNumberGenerator, frame: Transform3D,
		x0: float, x1: float, opening_top: float, face: int, column: int) -> void:
	# Les tirages, toujours dans le même ordre et toujours tous : la sorte, le nom, la teinte du
	# bandeau, le côté de la porte.
	var shop_type: int = random.randi_range(0, Palette.SHOP_NAMES.size() - 1)
	var names: PackedStringArray = PackedStringArray(Palette.SHOP_NAMES[shop_type])
	var shop_name: String = names[random.randi_range(0, names.size() - 1)]
	var fascia_color: Color = Palette.FASCIA_COLORS[random.randi_range(0, Palette.FASCIA_COLORS.size() - 1)]
	var door_left: bool = random.randf() < 0.5
	var width: float = x1 - x0
	var middle: float = 0.5 * (x0 + x1)
	var window_top: float = opening_top - FASCIA
	# La donnée de chaque vitre : la sorte de vitre, la sorte de boutique, la colonne, la façade.
	var custom_shop: Color = Color(KIND_SHOP, float(shop_type), float(column), float(face))
	var custom_door: Color = Color(KIND_SHOP_DOOR, float(shop_type), float(column), float(face))

	# Le bandeau d'enseigne, au-dessus de la vitrine, et le nom de la boutique, en lettres
	# claires sur un fond peint.
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ all
	_box(mesh, frame, Vector3(width, FASCIA, 0.14), Vector3(middle, opening_top - 0.5 * FASCIA, 0.07), materials.lacquer(fascia_color))
#@ 13+
	# Le texte : de près seulement.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	var label: Label3D = _label(shop_name, Color(0.95, 0.90, 0.78), Vector2(width - 0.4, 0.62 * FASCIA))
	label.transform = frame * Transform3D(Basis.IDENTITY, Vector3(middle, opening_top - 0.5 * FASCIA, 0.145))
	mesh.node(label)
#@ 13+
	# Les vitres ne portent pas d'ombre.
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all

	# La porte, d'un côté ; la vitrine, sur tout le reste, au-dessus de son soubassement. Au-dessus
	# de la porte, une imposte vitrée monte jusqu'au bandeau.
	var door_x: float = x0 + 0.5 * DOOR_SIZE.x if door_left else x1 - 0.5 * DOOR_SIZE.x
	var glass_x0: float = x0 + DOOR_SIZE.x if door_left else x0
	var glass_x1: float = x1 if door_left else x1 - DOOR_SIZE.x
	_panel(mesh, frame, Vector2(DOOR_SIZE.x, DOOR_SIZE.y), Vector3(door_x, 0.5 * DOOR_SIZE.y, -SHOP_RECESS), materials.shop_window, custom_door)
	_panel(mesh, frame, Vector2(DOOR_SIZE.x, window_top - DOOR_SIZE.y), Vector3(door_x, 0.5 * (DOOR_SIZE.y + window_top), -SHOP_RECESS), materials.shop_window, custom_shop)
	_panel(mesh, frame, Vector2(glass_x1 - glass_x0, window_top - BULKHEAD), Vector3(0.5 * (glass_x0 + glass_x1), 0.5 * (BULKHEAD + window_top), -SHOP_RECESS),
			materials.shop_window, custom_shop)
	_box(mesh, frame, Vector3(glass_x1 - glass_x0, BULKHEAD, 0.3), Vector3(0.5 * (glass_x0 + glass_x1), 0.5 * BULKHEAD, -SHOP_RECESS - 0.1), materials.stone)


## L'entrée de la tour de brique, entre « x0 » et « x1 » : un encadrement de bronze, deux portes
## tambour, une porte vitrée à deux vantaux entre elles, et une imposte vitrée au-dessus, qui
## laisse voir le hall.
static func _entrance(mesh: MeshBuilder, materials: Materials, frame: Transform3D, x0: float, x1: float, opening_top: float, face: int, column: int) -> void:
	var middle: float = 0.5 * (x0 + x1)
	var lobby: Color = Color(KIND_LOBBY, 0.0, float(column), float(face))
	var transom_y: float = DRUM_HEIGHT + 0.3
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	# L'imposte : du haut des portes au linteau, sur toute la largeur.
	_panel(mesh, frame, Vector2(x1 - x0, opening_top - transom_y), Vector3(middle, 0.5 * (transom_y + opening_top), -SHOP_RECESS), materials.shop_window, lobby)
	# La traverse de bronze sous l'imposte, et les deux montants.
	_box(mesh, frame, Vector3(x1 - x0, 0.3, 0.3), Vector3(middle, DRUM_HEIGHT + 0.15, -SHOP_RECESS + 0.05), materials.bronze)
	for x: float in [x0 + 0.1, x1 - 0.1]:
		_box(mesh, frame, Vector3(0.2, transom_y, 0.3), Vector3(x, 0.5 * transom_y, -SHOP_RECESS + 0.05), materials.bronze)
	# La porte à deux vantaux, au milieu.
	var door: Color = Color(KIND_SHOP_DOOR, 0.0, float(column), float(face))
	for side: float in [-1.0, 1.0]:
		_panel(mesh, frame, Vector2(0.8, DRUM_HEIGHT), Vector3(middle + side * 0.4, 0.5 * DRUM_HEIGHT, -SHOP_RECESS), materials.shop_window, door)
	# Les deux portes tambour, de part et d'autre.
	var offset: float = 0.5 * (x1 - x0) - DRUM_RADIUS - 0.25
	for side: float in [-1.0, 1.0]:
		revolving_door(mesh, materials, frame, Vector3(middle + side * offset, 0.0, -SHOP_RECESS))


## Une porte tambour, dont l'axe est au point « center » du repère de la façade : un toit et un
## socle de bronze, l'axe, quatre vantaux de verre bordés de bronze, et deux parois de verre
## courbes sur les côtés. Les côtés ouverts regardent la rue et le hall.
static func revolving_door(mesh: MeshBuilder, materials: Materials, frame: Transform3D, center: Vector3) -> void:
	var axis: Vector3 = frame * center
	var up: Vector3 = Vector3.UP
#@ 13+
	# Une porte tambour se voit de près seulement : une cinquantaine de pièces, deux mètres de
	# haut. Celui qui l'appelle revient ensuite à ses propres zones.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	# Le toit du tambour, son socle, l'axe : des cylindres, c'est-à-dire des cônes à deux rayons
	# égaux.
	mesh.cone(axis + up * (DRUM_HEIGHT + 0.175), DRUM_RADIUS + 0.08, DRUM_RADIUS + 0.08, 0.35, materials.bronze, frame.basis, 24)
	mesh.cone(axis + up * 0.02, DRUM_RADIUS + 0.08, DRUM_RADIUS + 0.08, 0.04, materials.bronze, frame.basis, 24)
	mesh.cone(axis + up * (0.5 * DRUM_HEIGHT), 0.06, 0.06, DRUM_HEIGHT, materials.bronze, frame.basis, 8)
	var glass: Color = Color(KIND_DOOR_GLASS, 0.0, 0.0, 0.0)
	# Les quatre vantaux, en croix, tournés d'un huitième de tour : un rectangle de verre de
	# chaque côté (un rectangle instancié n'a qu'une face), et un montant de bronze au bout.
	for index: int in range(4):
		var angle: float = 0.25 * PI + 0.5 * PI * float(index)
		var along: Vector3 = frame.basis * Vector3(cos(angle), 0.0, sin(angle))
		var wing: Basis = Basis(along, up, along.cross(up))
		var wing_center: Vector3 = axis + along * (0.5 * DRUM_RADIUS) + up * (0.5 * DRUM_HEIGHT)
		for flip: float in [0.0, PI]:
			mesh.panel(Vector2(DRUM_RADIUS - 0.1, DRUM_HEIGHT - 0.1), Transform3D(wing * Basis(Vector3.UP, flip), wing_center), materials.shop_window, glass)
		mesh.box(Vector3(0.05, DRUM_HEIGHT, 0.05), axis + along * (DRUM_RADIUS - 0.03) + up * (0.5 * DRUM_HEIGHT), materials.bronze)
	# Les deux parois courbes, à gauche et à droite : des facettes de verre sur un arc de cercle.
	# Une facette regarde vers le dehors : son axe x suit l'arc à rebours, son axe z est le rayon.
	for side: float in [0.0, PI]:
		for index: int in range(DRUM_FACETS):
			var a0: float = side - 0.7 + 1.4 * float(index) / float(DRUM_FACETS)
			var a1: float = side - 0.7 + 1.4 * float(index + 1) / float(DRUM_FACETS)
			var p0: Vector3 = Vector3(cos(a0), 0.0, sin(a0)) * DRUM_RADIUS
			var p1: Vector3 = Vector3(cos(a1), 0.0, sin(a1)) * DRUM_RADIUS
			var along: Vector3 = frame.basis * (p0 - p1).normalized()
			var facet: Basis = Basis(along, up, along.cross(up))
			mesh.panel(Vector2(p0.distance_to(p1), DRUM_HEIGHT), Transform3D(facet, axis + frame.basis * (0.5 * (p0 + p1)) + up * (0.5 * DRUM_HEIGHT)),
					materials.shop_window, glass)


# --- Formes -----------------------------------------------------------------------

## Boîte décrite dans le repère de la façade.
static func _box(mesh: MeshBuilder, frame: Transform3D, size: Vector3, center: Vector3, material: Material) -> void:
	mesh.box(size, frame * center, material, frame.basis)


## Rectangle instancié décrit dans le repère de la façade, tourné vers la rue.
static func _panel(mesh: MeshBuilder, frame: Transform3D, size: Vector2, center: Vector3, material: Material, custom: Color) -> void:
	mesh.panel(size, frame * Transform3D(Basis.IDENTITY, center), material, custom)


## Texte d'enseigne : un Label3D qui tient dans « size » (largeur, hauteur), en mètres.
static func _label(text: String, ink: Color, size: Vector2) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = FONT_SIZE
	label.outline_size = 0
	label.modulate = ink
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	# Une lettre latine fait à peu près les deux tiers de sa hauteur en largeur : le texte tient
	# dans la hauteur du bandeau, et dans sa largeur s'il est long.
	var height: float = minf(size.y, size.x / maxf(0.68 * float(text.length()), 1.0))
	# « pixel_size » règle la taille du texte dans la scène : un caractère de FONT_SIZE pixels
	# doit mesurer « height » mètres.
	label.pixel_size = height / float(FONT_SIZE)
	return label
