@tool
extends RefCounted
## Porte d'entrée : vantaux à panneaux moulurés, imposte grillée, encadrement de pierre.
## Trois formes : rectangulaire à imposte, plein cintre, anse de panier.
## {STATUS}
##
## Comme le toit, la porte est un objet à part : un script « static » qui reçoit l'outil de
## maillage, les matériaux et les cotes de la baie, et qui y pose ses pièces.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Materials := preload("{MESH}_materiaux.gd")
const Profiles := preload("{MESH}_profils.gd")

enum Style { RECTANGULAR = 1, ROUND_ARCH = 2, BASKET_ARCH = 3 }

## Retrait de la menuiserie par rapport au nu du mur.
const RECESS: float = 0.22
const LEAF_DEPTH: float = 0.07
const KICK_HEIGHT: float = 0.24


## Flèche de l'arc d'une porte de ce style et de cette largeur. 0 pour une porte rectangulaire.
static func arch_rise(style: int, width: float) -> float:
	if style == Style.ROUND_ARCH:
		return 0.5 * width
	if style == Style.BASKET_ARCH:
		return 0.3 * width
	return 0.0


## Monte une porte dans une baie de « width » sur « height », posée en « base_y » et centrée
## sur « center_x ». « ornament » : 0 nu, 1 mouluré, 2 riche.
static func build(mesh: MeshBuilder, materials: Materials, style: int, center_x: float, base_y: float,
		width: float, height: float, wall_depth: float, wall_material: Material, ornament: int) -> void:
	var rise: float = arch_rise(style, width)
	var top_y: float = base_y + height
	var spring_y: float = top_y - rise
	if rise > 0.0:
		# Le mur redescend jusqu'à l'arc.
		mesh.arch_wall(Vector3(center_x, spring_y, 0.0), 0.5 * width, rise, top_y, wall_depth, wall_material)

	var transom: float = rise if rise > 0.0 else clampf(height - 2.9, 0.0, 0.75)
	var leaf_height: float = height - transom
	_build_leaves(mesh, materials, center_x, base_y, width, leaf_height)
	if rise > 0.0:
		_build_fanlight(mesh, materials, center_x, spring_y, width, rise)
	elif transom > 0.25:
		_build_transom(mesh, materials, center_x, base_y + leaf_height, width, transom)
#@ 10-12
	# Seuil de pierre.
	mesh.box(Vector3(width + 0.1, 0.05, 0.3), Vector3(center_x, base_y + 0.025, -0.1), materials.stone)
	if ornament > 0:
		_build_surround(mesh, materials, center_x, base_y, width, spring_y, rise, ornament)
#@ 13+
	# Seuil de pierre, puis encadrement : des ornements, dessinés de près seulement.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
	mesh.box(Vector3(width + 0.1, 0.05, 0.3), Vector3(center_x, base_y + 0.025, -0.1), materials.stone)
	if ornament > 0:
		_build_surround(mesh, materials, center_x, base_y, width, spring_y, rise, ornament)
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


# --- Menuiserie -------------------------------------------------------------

static func _build_leaves(mesh: MeshBuilder, materials: Materials, center_x: float, base_y: float, width: float, leaf_height: float) -> void:
	var wood: ShaderMaterial = materials.door_wood
	var face: float = -RECESS + 0.5 * LEAF_DEPTH
	var leaf_width: float = 0.5 * width - 0.008
	for side: float in [-1.0, 1.0]:
		var leaf_x: float = center_x + side * 0.25 * width
		mesh.box(Vector3(leaf_width, leaf_height, LEAF_DEPTH), Vector3(leaf_x, base_y + 0.5 * leaf_height, -RECESS), wood)
#@ 13+
		# Le vantail lui-même vient d'être posé : il se voit de partout. Sa plinthe, ses
		# panneaux moulurés et son bouton ne se voient que de près.
		mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
		# Plinthe.
		mesh.box(Vector3(leaf_width - 0.03, KICK_HEIGHT, 0.02), Vector3(leaf_x, base_y + 0.5 * KICK_HEIGHT + 0.02, face + 0.01), wood)
		# Trois panneaux, du bas vers le haut : moyen, grand, petit.
		var usable: float = leaf_height - KICK_HEIGHT - 0.14
		var bottom: float = base_y + KICK_HEIGHT + 0.09
		for share: float in [0.30, 0.46, 0.24]:
			var panel_height: float = usable * share - 0.08
			_panel(mesh, wood, Vector2(leaf_width - 0.2, panel_height), Vector3(leaf_x, bottom + 0.5 * panel_height, face))
			bottom += usable * share
		# Bouton de laiton.
		mesh.cone(Vector3(center_x + side * 0.09, base_y + 1.05, face + 0.035), 0.03, 0.022, 0.05, materials.brass, Basis(Vector3.RIGHT, 0.5 * PI))
#@ 13+
		mesh.set_zones(MeshBuilder.ZONE_ALL)
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	# Battement central.
	mesh.box(Vector3(0.05, leaf_height, 0.03), Vector3(center_x, base_y + 0.5 * leaf_height, face + 0.015), wood)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Panneau mouluré : un cadre en relief et une table saillante au centre.
static func _panel(mesh: MeshBuilder, material: Material, size: Vector2, center: Vector3) -> void:
	var rim: float = 0.035
	var proud: float = 0.022
	for side: float in [-1.0, 1.0]:
		mesh.box(Vector3(size.x, rim, proud), center + Vector3(0.0, side * 0.5 * (size.y - rim), 0.5 * proud), material)
		mesh.box(Vector3(rim, size.y, proud), center + Vector3(side * 0.5 * (size.x - rim), 0.0, 0.5 * proud), material)
	mesh.box(Vector3(size.x - 0.16, size.y - 0.16, 0.014), center + Vector3(0.0, 0.0, 0.007), material)


## Imposte rectangulaire : traverse, vitrage sombre et grille à croisillons.
static func _build_transom(mesh: MeshBuilder, materials: Materials, center_x: float, bottom_y: float, width: float, transom: float) -> void:
	var wood: ShaderMaterial = materials.door_wood
	var bar: float = 0.09
	mesh.box(Vector3(width, bar, LEAF_DEPTH + 0.03), Vector3(center_x, bottom_y + 0.5 * bar, -RECESS + 0.015), wood)
	var glass_height: float = transom - bar
	var middle: float = bottom_y + bar + 0.5 * glass_height
	mesh.box(Vector3(width, glass_height, 0.02), Vector3(center_x, middle, -RECESS - 0.03), materials.dark_glass)
	var grille: Vector2 = Vector2(width - 0.04, glass_height - 0.04)
#@ 13+
	# La grille : de près et à mi-distance, sans ombre portée.
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	mesh.panel(grille, Transform3D(Basis.IDENTITY, Vector3(center_x, middle, -RECESS + 0.01)), materials.grille)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


## Imposte en demi-cercle : traverse, vitrage sombre et grille en éventail.
static func _build_fanlight(mesh: MeshBuilder, materials: Materials, center_x: float, spring_y: float, width: float, rise: float) -> void:
	var wood: ShaderMaterial = materials.door_wood
	var bar: float = 0.1
	mesh.box(Vector3(width, bar, LEAF_DEPTH + 0.03), Vector3(center_x, spring_y - 0.5 * bar, -RECESS + 0.015), wood)
	var glass: PackedVector2Array = Profiles.arched_outline(0.5 * width, rise, rise)
	mesh.polygon(glass, Transform3D(Basis.IDENTITY, Vector3(center_x, spring_y, -RECESS - 0.03)), materials.dark_glass)
	var grille: Vector2 = Vector2(width - 0.06, rise - 0.03)
#@ 13+
	# La grille en éventail : de près et à mi-distance, sans ombre portée.
	mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
	mesh.panel(grille, Transform3D(Basis.IDENTITY, Vector3(center_x, spring_y + 0.5 * grille.y, -RECESS + 0.01)), materials.fan_grille)
#@ 13+
	# Le cintre de bois : de près seulement.
	mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ all
	# Cintre de bois contre la pierre.
	mesh.sweep(Profiles.rectangle(0.06, 0.06), Transform3D(Basis.IDENTITY, Vector3(center_x, spring_y, -RECESS)),
			Vector2(0.5 * width - 0.03, rise - 0.03), 0.0, PI, wood)
#@ 13+
	mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ all


# --- Encadrement de pierre --------------------------------------------------

static func _build_surround(mesh: MeshBuilder, materials: Materials, center_x: float, base_y: float, width: float,
		spring_y: float, rise: float, ornament: int) -> void:
	var stone: ShaderMaterial = materials.stone
	var band: PackedVector2Array = Profiles.architrave(0.2, 0.07)
	var half: float = 0.5 * width
	var top_y: float = spring_y + rise
	var jamb_height: float = spring_y - base_y
	for side: float in [-1.0, 1.0]:
		mesh.extrude(band, MeshBuilder.jamb(Vector3(center_x + side * half, base_y + 0.5 * jamb_height, 0.0), side), jamb_height, stone)

	if rise > 0.0:
		# Archivolte et clef.
		mesh.sweep(band, Transform3D(Basis.IDENTITY, Vector3(center_x, spring_y, 0.0)), Vector2(half, rise), 0.0, PI, stone)
		mesh.extrude(Profiles.keystone(0.2, 0.3, 0.42), MeshBuilder.facing_street(Vector3(center_x, top_y - 0.14, 0.05)), 0.16, stone)
		if ornament > 1:
			# Impostes : un tailloir à la naissance de l'arc, de chaque côté.
			for side: float in [-1.0, 1.0]:
				mesh.extrude(Profiles.string_course(0.1, 0.06), MeshBuilder.along_x(Vector3(center_x + side * (half + 0.1), spring_y - 0.05, 0.07)), 0.3, stone)
	else:
		mesh.extrude(band, MeshBuilder.head(Vector3(center_x, top_y, 0.0)), width + 0.4, stone)
		# Corniche au-dessus de la porte, portée par deux consoles.
		var shelf_y: float = top_y + 0.26
		mesh.extrude(Profiles.cornice(0.2, 0.28), MeshBuilder.along_x(Vector3(center_x, shelf_y, 0.0)), width + 0.8, stone)
		if ornament > 1:
			for side: float in [-1.0, 1.0]:
				mesh.extrude(Profiles.console(0.42, 0.22), MeshBuilder.along_x(Vector3(center_x + side * (half + 0.2), shelf_y - 0.42, 0.0)), 0.16, stone)
