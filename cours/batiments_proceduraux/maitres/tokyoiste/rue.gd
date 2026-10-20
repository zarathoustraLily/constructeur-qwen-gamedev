@tool
extends Node3D
## Rue tokyoïte : une ou deux faces de petits immeubles tirés au sort, sous le gabarit oblique
## de la voie, avec ses poteaux et ses fils.
## {STATUS}
##
## Ce script ne fabrique aucun triangle d'immeuble. Il fait quatre choses :
##   1. il découpe la longueur de la rue en parcelles étroites, séparées par un interstice ;
##   2. pour chaque parcelle, il crée un immeuble (le script de l'étape précédente) et règle
##      ses variables par des tirages ;
##   3. il pose la chaussée, avec ses lignes blanches ou ses trottoirs ;
##   4. il plante les poteaux électriques et tend les fils.
## C'est la leçon de l'étape : un générateur bien paramétré devient la brique d'un générateur
## plus grand. La rue ne sait rien des fenêtres ; elle ne connaît que des variables.
##
## Deux règles donnent son air à une rue de Tokyo, et ce sont l'inverse de celles de Paris :
##   - des hauteurs libres : aucun alignement des corniches, chacun bâtit ce qu'il veut tant
##     qu'il reste sous le gabarit oblique. La rue donne sa largeur à chaque immeuble, et c'est
##     l'immeuble qui recule ses étages (voir la palette dans 5_data) ;
##   - pas de murs mitoyens : chaque immeuble garde une distance avec la limite de sa
##     parcelle. D'où un interstice entre voisins, tantôt presque nul, tantôt d'un mètre.
##
## Repère de la rue : elle court le long de X, centrée sur l'origine ; l'axe de la chaussée
## est en z = 0 ; le pied des immeubles est à y = 0. Unité : le mètre.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Building := preload("{MESH}.gd")
const Palette := preload("{DATA}_palette.gd")

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Largeur d'une travée : la plus étroite et la plus large qu'on tire.
const BAY_WIDTH_MIN: float = 1.9
const BAY_WIDTH_MAX: float = 2.7
## Hauteur de la bordure d'un trottoir au-dessus de la chaussée, et sa largeur.
const CURB_HEIGHT: float = 0.14
const CURB_WIDTH: float = 0.2
## Largeur du caniveau de béton qui longe les façades, et largeur d'une ligne blanche.
const GUTTER_WIDTH: float = 0.5
const LINE_WIDTH: float = 0.15
## Poteaux électriques : hauteur hors sol, entraxe approximatif.
const POLE_HEIGHT: float = 11.0
const POLE_SPACING: float = 30.0
## Nombre de segments droits dont est fait un fil entre deux poteaux.
const WIRE_SEGMENTS: int = 8

@export_group("Voie")
## Longueur de la rue.
@export_range(30.0, 300.0, 1.0, "suffix:m") var street_length: float = 80.0
## Largeur de la voie, de façade à façade. Elle fixe le gabarit oblique : plus la rue est
## étroite, plus tôt les étages reculent. Son minimum est la largeur que la loi demande à une
## voie ; il vient de la palette.
@export_range(Palette.MIN_ROAD_WIDTH, 25.0, 0.5, "suffix:m") var street_width: float = 6.0
## Pente du gabarit oblique. Elle dépend de la zone d'urbanisme.
@export_enum("Zone d'habitation (1.25)", "Autres zones (1.5)") var slope_zone: int = 1
## Largeur de chaque trottoir. 0 : pas de trottoir, une simple ligne blanche de chaque côté,
## comme dans la plupart des petites rues.
@export_range(0.0, 4.0, 0.1, "suffix:m") var sidewalk_width: float = 0.0
## Bâtir les deux côtés de la rue ; sinon, un seul.
@export var two_sides: bool = true
## Poteaux électriques et fils aériens.
@export var poles: bool = true

@export_group("Parcelles")
## Nombre de travées de l'immeuble le plus étroit, puis du plus large.
@export_range(1, 4, 1) var min_bays: int = 1
@export_range(1, 6, 1) var max_bays: int = 3
## Nombre d'étages au-dessus du rez-de-chaussée : le moins et le plus qu'on tire. Les étages
## que le gabarit ne permet pas ne sont pas construits.
@export_range(1, 12, 1) var min_floors: int = 1
@export_range(1, 12, 1) var max_floors: int = 5
## Interstice entre deux voisins : le plus étroit et le plus large qu'on tire. Le plus large,
## par défaut : deux immeubles qui gardent chacun, avec la limite de leur parcelle, la distance
## que demande le code civil (voir la palette).
@export_range(0.0, 1.0, 0.01, "suffix:m") var min_gap: float = 0.05
@export_range(0.0, 2.0, 0.01, "suffix:m") var max_gap: float = 2.0 * Palette.BOUNDARY_DISTANCE

@export_group("Aspect")
## Part des immeubles à boutique au rez-de-chaussée.
@export_range(0.0, 1.0, 0.05) var shop_share: float = 0.75
## Part des immeubles qui portent une enseigne en drapeau.
@export_range(0.0, 1.0, 0.05) var sign_share: float = 0.65
## Vrai : enseignes en japonais. Faux : en lettres latines.
@export var japanese_signs: bool = true
## Change tous les tirages de la rue.
@export var variation_seed: int = 1
#@ 13+

@export_group("Niveaux de détail")
## Jusqu'à cette distance, un immeuble est dessiné en entier. La rue donne ces deux distances
## à chacun de ses immeubles et à chacun de ses poteaux. 0 pour les deux : pas de niveaux de
## détail.
@export_range(0.0, 150.0, 1.0, "suffix:m") var near_distance: float = 30.0
## Au-delà de cette distance, il ne reste d'un immeuble que les murs, les fenêtres, les balcons
## et les caissons d'enseigne.
@export_range(0.0, 400.0, 1.0, "suffix:m") var far_distance: float = 90.0
#@ all


## Empreinte des variables au moment de la dernière construction.
var _signature: int = 0
## 0 : jour, 1 : nuit. Gardé pour le redonner aux immeubles après une reconstruction.
var _night: float = 0.0
#@ 13+
## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Gardée de la même façon.
var _quality: int = 2
#@ all
var _root: Node3D
var _buildings: Array[Building] = []
## Les lampes des poteaux, et le matériau de leur globe : on les allume la nuit.
var _lamps: Array[OmniLight3D] = []
var _lamp_glass: StandardMaterial3D


func _ready() -> void:
	# Dans le jeu, la rue est montée une fois ; inutile de surveiller ses variables.
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(_delta: float) -> void:
	# Dans l'éditeur, à chaque image : une variable a-t-elle changé dans l'inspecteur ?
	if _current_signature() != _signature:
		rebuild()


## 0 : jour, 1 : nuit, pour tous les immeubles de la rue et pour ses lampes.
func set_night(value: float) -> void:
	_night = value
	for building: Building in _buildings:
		building.set_night(value)
	for lamp: OmniLight3D in _lamps:
		lamp.visible = value > 0.5
	if _lamp_glass != null:
		_lamp_glass.emission_energy_multiplier = 3.0 * value


#@ 13+
## Finesse de calcul des shaders, pour tous les immeubles de la rue : 0 basse, 1 moyenne, 2 haute.
func set_quality(level: int) -> void:
	_quality = level
	for building: Building in _buildings:
		building.set_quality(level)


#@ all
## Démonte la rue et la remonte d'après les variables courantes.
func rebuild() -> void:
	_signature = _current_signature()

	# 1. On jette l'ancien résultat.
	for child: Node in get_children(true):
		if child.name == GENERATED_NAME:
			remove_child(child)
			child.queue_free()
	_buildings.clear()
	_lamps.clear()

	# 2. Un nœud « interne », qui n'est pas enregistré avec la scène : celle-ci ne garde que
	#    les variables de la rue.
	_root = Node3D.new()
	_root.name = GENERATED_NAME
	add_child(_root, false, Node.INTERNAL_MODE_BACK)

	# 3. Les immeubles, un côté puis l'autre. Le côté -1 est en z négatif et regarde vers +Z.
	var sides: Array[float] = [-1.0]
	if two_sides:
		sides.append(1.0)
	for side: float in sides:
		_build_side(side)

	# 4. Le sol, puis les poteaux et leurs fils.
	_build_ground()
	if poles:
		_build_poles()
	set_night(_night)


# --- Variables --------------------------------------------------------------

## Empreinte de toutes les variables exportées : si elle change, il faut reconstruire.
func _current_signature() -> int:
	var values: Array[Variant] = []
	var properties: Array[Dictionary] = (get_script() as Script).get_script_property_list()
	for index: int in range(properties.size()):
		var usage: int = properties[index]["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_EDITOR:
			values.append(get(properties[index]["name"]))
	return hash(values)


# --- Parcelles --------------------------------------------------------------

## Découpe la longueur de la rue en parcelles. Pour chacune : x, le nombre de travées ; y, la
## largeur d'une travée ; z, l'interstice qui la sépare de la suivante. La somme des largeurs
## et des interstices vaut exactement la longueur de la rue.
func _draw_lots(random: RandomNumberGenerator) -> Array[Vector3]:
	var lots: Array[Vector3] = []
	var remaining: float = street_length
	# En dessous de cette largeur, il n'y a pas la place d'un immeuble et de son interstice.
	var narrowest: float = float(min_bays) * BAY_WIDTH_MIN + max_gap
	while remaining > 0.01:
		var bays: int = random.randi_range(min_bays, maxi(min_bays, max_bays))
		var bay_width: float = snappedf(random.randf_range(BAY_WIDTH_MIN, BAY_WIDTH_MAX), 0.05)
		var gap: float = random.randf_range(minf(min_gap, max_gap), max_gap)
		var width: float = float(bays) * bay_width
		if remaining - width - gap < narrowest:
			# Dernière parcelle : elle prend tout ce qui reste, sans interstice après elle. On
			# choisit le nombre de travées qui donne une travée de largeur ordinaire.
			bays = clampi(roundi(remaining / 2.3), 1, 8)
			bay_width = remaining / float(bays)
			width = remaining
			gap = 0.0
		lots.append(Vector3(float(bays), bay_width, gap))
		remaining -= width + gap
	return lots


## Monte une face de la rue. « side » : -1 pour le côté des z négatifs, 1 pour l'autre.
func _build_side(side: float) -> void:
	var lot_random: RandomNumberGenerator = RandomNumberGenerator.new()
	lot_random.seed = hash([variation_seed, "parcelles", side])
	var lots: Array[Vector3] = _draw_lots(lot_random)

	var x: float = -0.5 * street_length
	for index: int in range(lots.size()):
		var bays: int = roundi(lots[index].x)
		var bay_width: float = lots[index].y
		var width: float = float(bays) * bay_width

		# Un dé par immeuble, dont la graine dépend du côté et du rang : allonger la rue
		# n'aura pas changé l'allure des immeubles déjà tirés.
		var random: RandomNumberGenerator = RandomNumberGenerator.new()
		random.seed = hash([variation_seed, "immeuble", side, index])

		var building: Building = Building.new()
		building.name = "Building_%s_%02d" % ["A" if side < 0.0 else "B", index]
		building.bay_count = bays
		building.bay_width = bay_width
		# Le gabarit : la rue ne calcule rien. Elle dit sa largeur et sa zone à l'immeuble, qui
		# sait reculer ses étages tout seul.
		building.road_width = street_width
		building.slope_zone = slope_zone
		_apply_storeys(building, random)
		_apply_aspect(building, random)
#@ 13+
		building.near_distance = near_distance
		building.far_distance = far_distance
#@ all

		# L'immeuble est centré sur sa parcelle, sa façade sur l'alignement. De l'autre côté de
		# la rue, il fait demi-tour pour regarder la chaussée.
		building.position = Vector3(x + 0.5 * width, 0.0, side * 0.5 * street_width)
		if side > 0.0:
			building.rotation.y = PI
		building.set_night(_night)
#@ 13+
		building.set_quality(_quality)
#@ all
		# add_child() déclenche le _ready() de l'immeuble, donc sa construction : toutes ses
		# variables doivent être réglées avant.
		_root.add_child(building)
		_buildings.append(building)
		x += width + lots[index].z


# --- Tirages d'un immeuble --------------------------------------------------

## Tire les étages d'un immeuble : combien, de quelle hauteur, bureaux ou logements. Aucune
## hauteur n'est imposée par la rue : c'est ce qui donne à une rue de Tokyo sa ligne de toits
## en dents de scie.
func _apply_storeys(building: Building, random: RandomNumberGenerator) -> void:
	building.ground_height = snappedf(random.randf_range(3.3, 3.9), 0.05)
	building.floor_height = snappedf(random.randf_range(2.8, 3.3), 0.05)
	building.floor_count = random.randi_range(min_floors, maxi(min_floors, max_floors))
	building.parapet_height = snappedf(random.randf_range(0.4, 1.1), 0.05)
	# Un tiers d'immeubles de bureaux, un tiers d'immeubles de logements, un tiers de mixtes.
	# La part de bureaux d'un immeuble mixte est tirée même si elle ne sert pas : comme à
	# l'étape 011, le nombre de tirages ne doit pas dépendre du résultat d'un tirage.
	var use: float = random.randf()
	var office_share: float = random.randf_range(0.25, 0.75)
	if use < 0.34:
		building.office_floors = building.floor_count
	elif use < 0.67:
		building.office_floors = 0
	else:
		building.office_floors = clampi(roundi(office_share * float(building.floor_count)), 1, maxi(1, building.floor_count - 1))
	building.office_window_height = snappedf(random.randf_range(1.2, 1.8), 0.05)
	building.depth = snappedf(random.randf_range(9.0, 15.0), 0.5)


## Tire tout ce qui distingue un immeuble de son voisin : revêtement, balcons, toit, boutique,
## enseignes.
func _apply_aspect(building: Building, random: RandomNumberGenerator) -> void:
	# Revêtement : la graine de l'immeuble choisit entre carrelage, béton et enduit, et le
	# format des carreaux. La rue tire la teinte, dans une liste qui convient au carrelage
	# comme à l'enduit ; le béton brut garde son gris.
	building.cladding = 0
	building.tile_format = 0
	var tiles: Array[Color] = Palette.TILE_COLORS
	building.tile_color = tiles[random.randi_range(0, tiles.size() - 1)]
	building.grime = random.randf_range(0.15, 0.6)
	building.frame_color = Palette.FRAME_COLORS[random.randi_range(0, Palette.FRAME_COLORS.size() - 1)]

	# Balcons, auvent, descentes d'eau. Chaque cote est tirée avant de savoir si elle servira.
	var balcony: float = snappedf(random.randf_range(0.9, 1.3), 0.05)
	building.balcony_depth = balcony if random.randf() < 0.85 else 0.0
	building.railing_style = 0
	building.ac_units = random.randf() < 0.85
	var canopy: float = snappedf(random.randf_range(0.5, 1.0), 0.05)
	building.canopy_depth = canopy if random.randf() < 0.6 else 0.0
	building.downpipes = random.randf() < 0.8

	# Toit : un édicule si l'immeuble a au moins deux étages, souvent un réservoir. Le dé est
	# lancé avant de regarder le nombre d'étages : « and » n'évalue pas ce qui suit un faux.
	building.penthouse = random.randf() < 0.8 and building.floor_count >= 2
	building.water_tank = random.randf() < 0.5
	building.roof_units = random.randi_range(0, 4)

	# Rez-de-chaussée et enseignes.
	building.shop = random.randf() < shop_share
	building.shutter = 0
	building.vending_machine = random.randf() < 0.5
	building.fascia_sign = true
	building.projecting_sign = random.randf() < sign_share
	building.roof_sign = random.randf() < 0.2 and building.floor_count >= 4
	building.japanese_signs = japanese_signs

	# Les formes laissées « Selon la graine » (escalier, garde-corps, rideau, revêtement) et la
	# boutique se tirent dans l'immeuble lui-même : il suffit de lui donner sa graine.
	building.core_side = 0
	building.variation_seed = random.randi_range(0, 1000000)


# --- Sol --------------------------------------------------------------------

## Chaussée, caniveaux, lignes blanches ou trottoirs. Le pied des immeubles est à y = 0.
func _build_ground() -> void:
	var mesh: MeshBuilder = MeshBuilder.new()
	var asphalt: StandardMaterial3D = _plain(Color(0.13, 0.13, 0.14), 0.85)
	var concrete: StandardMaterial3D = _plain(Color(0.46, 0.46, 0.45), 0.9)
	var paint: StandardMaterial3D = _plain(Color(0.82, 0.82, 0.80), 0.7)
	var half_width: float = 0.5 * street_width
	var ground_length: float = street_length + 80.0
	var walk: float = minf(sidewalk_width, half_width - 1.5)

	if walk > 0.3:
		# Avec trottoirs : la chaussée est en contrebas, comme à Paris.
		mesh.box(Vector3(ground_length, 0.3, street_width), Vector3(0.0, -CURB_HEIGHT - 0.15, 0.0), asphalt)
		for side: float in [-1.0, 1.0]:
			mesh.box(Vector3(ground_length, 0.3, walk - CURB_WIDTH), Vector3(0.0, -0.15, side * (half_width - 0.5 * (walk - CURB_WIDTH))), concrete)
			mesh.box(Vector3(ground_length, 0.3, CURB_WIDTH), Vector3(0.0, -0.15, side * (half_width - walk + 0.5 * CURB_WIDTH)), _plain(Color(0.58, 0.58, 0.56), 0.8))
	else:
		# Sans trottoir : la chaussée va de façade à façade. De chaque côté, un caniveau de
		# béton au pied des immeubles, puis une ligne blanche qui réserve une bande aux piétons.
		# Ce sont des bandes posées côte à côte, pas des bandes peintes sur une chaussée : deux
		# faces l'une sur l'autre se disputeraient les mêmes pixels.
		var line_inner: float = half_width - GUTTER_WIDTH - 0.45 - LINE_WIDTH
		mesh.box(Vector3(ground_length, 0.3, 2.0 * line_inner), Vector3(0.0, -0.15, 0.0), asphalt)
		for side: float in [-1.0, 1.0]:
			mesh.box(Vector3(ground_length, 0.3, GUTTER_WIDTH), Vector3(0.0, -0.15, side * (half_width - 0.5 * GUTTER_WIDTH)), concrete)
			mesh.box(Vector3(ground_length, 0.3, 0.45), Vector3(0.0, -0.15, side * (half_width - GUTTER_WIDTH - 0.225)), asphalt)
			mesh.box(Vector3(ground_length, 0.3, LINE_WIDTH), Vector3(0.0, -0.15, side * (line_inner + 0.5 * LINE_WIDTH)), paint)
	# Un grand socle sombre, en contrebas, pour que la rue ne flotte pas dans le vide.
	mesh.box(Vector3(street_length + 600.0, 0.3, 600.0), Vector3(0.0, -CURB_HEIGHT - 0.17, 0.0), asphalt)
	mesh.commit(_root)


# --- Poteaux et fils --------------------------------------------------------

## Plante les poteaux le long d'un côté de la rue et tend les fils de l'un au suivant. Chaque
## poteau est un petit objet à part, avec son propre outil de maillage.
func _build_poles() -> void:
	var count: int = maxi(roundi(street_length / POLE_SPACING), 2)
	var spacing: float = street_length / float(count)
	var steel: StandardMaterial3D = _plain(Color(0.42, 0.43, 0.43), 0.6)
	var concrete: StandardMaterial3D = _plain(Color(0.52, 0.52, 0.50), 0.9)
	var cable: StandardMaterial3D = _plain(Color(0.04, 0.04, 0.045), 0.6)
	_lamp_glass = _plain(Color(0.85, 0.85, 0.80), 0.4)
	_lamp_glass.emission_enabled = true
	_lamp_glass.emission = Color(1.0, 0.93, 0.80)
	_lamp_glass.emission_energy_multiplier = 0.0
	# Les poteaux sont au pied des façades du côté des z négatifs, dans le caniveau.
	var pole_z: float = -0.5 * street_width + 0.3

	for index: int in range(count):
		var mesh: MeshBuilder = MeshBuilder.new()
#@ 13+
		mesh.near_distance = near_distance
		mesh.far_distance = far_distance
#@ all
		var holder: Node3D = Node3D.new()
		holder.name = "Pole_%02d" % index
		holder.position = Vector3(-0.5 * street_length + (float(index) + 0.5) * spacing, 0.0, pole_z)
		_root.add_child(holder)

		# Le poteau : un tronc de cône de béton, plus mince en haut.
		mesh.cone(Vector3(0.0, 0.5 * POLE_HEIGHT, 0.0), 0.17, 0.11, POLE_HEIGHT, concrete, Basis.IDENTITY, 10)
#@ 13+
		# Ses ferrures : de près et à mi-distance, sans ombre portée.
		mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ all
		# Deux traverses en haut, avec trois isolateurs chacune : elles portent la haute tension.
		for arm_y: float in [POLE_HEIGHT - 0.3, POLE_HEIGHT - 1.2]:
			mesh.box(Vector3(0.07, 0.07, 1.5), Vector3(0.0, arm_y, 0.25), steel)
			for insulator: float in [-0.4, 0.25, 0.9]:
				mesh.cone(Vector3(0.0, arm_y + 0.1, insulator), 0.05, 0.035, 0.13, concrete, Basis.IDENTITY, 6)
		# Un poteau sur deux porte un transformateur : un cylindre gris, côté rue.
		if index % 2 == 0:
			mesh.cone(Vector3(0.0, POLE_HEIGHT - 2.4, 0.42), 0.24, 0.24, 0.75, steel, Basis.IDENTITY, 12)
			mesh.box(Vector3(0.08, 0.08, 0.5), Vector3(0.0, POLE_HEIGHT - 2.75, 0.25), steel)
		# La lampe de rue : un bras au-dessus de la chaussée, et son globe.
		mesh.box(Vector3(0.05, 0.05, 1.3), Vector3(0.0, 6.6, 0.65), steel)
		mesh.box(Vector3(0.45, 0.09, 0.2), Vector3(0.0, 6.52, 1.25), _lamp_glass)
		var lamp: OmniLight3D = OmniLight3D.new()
		lamp.position = Vector3(0.0, 6.3, 1.25)
		lamp.light_color = Color(1.0, 0.93, 0.80)
		lamp.light_energy = 2.2
		lamp.omni_range = 16.0
		lamp.shadow_enabled = false
		lamp.visible = false
		holder.add_child(lamp)
		_lamps.append(lamp)

		# Les fils, de ce poteau au suivant. Après le dernier poteau, ils filent jusqu'au bout
		# de la rue. Trois fils par traverse, trois fils de basse tension, deux câbles de
		# téléphone plus gros et plus bas. Chaque ligne : hauteur, écart vers la rue, grosseur,
		# flèche (de combien le fil pend au milieu).
		var span: float = spacing if index < count - 1 else 0.5 * spacing + 20.0
		var wires: Array[Vector4] = [
			Vector4(POLE_HEIGHT - 0.12, -0.15, 0.022, 0.35), Vector4(POLE_HEIGHT - 0.12, 0.5, 0.022, 0.35), Vector4(POLE_HEIGHT - 0.12, 1.15, 0.022, 0.35),
			Vector4(POLE_HEIGHT - 1.02, -0.15, 0.022, 0.4), Vector4(POLE_HEIGHT - 1.02, 0.5, 0.022, 0.4), Vector4(POLE_HEIGHT - 1.02, 1.15, 0.022, 0.4),
			Vector4(POLE_HEIGHT - 3.3, 0.2, 0.03, 0.5), Vector4(POLE_HEIGHT - 3.6, 0.2, 0.03, 0.5), Vector4(POLE_HEIGHT - 3.9, 0.2, 0.03, 0.5),
			Vector4(5.9, 0.22, 0.055, 0.6), Vector4(5.5, 0.22, 0.045, 0.7),
		]
#@ 12
		for wire: Vector4 in wires:
			_add_wire(mesh, cable, Vector3(0.0, wire.x, wire.y), span, wire.z, wire.w)
			if index == 0:
				# Avant le premier poteau, les fils arrivent du bout de la rue.
				_add_wire(mesh, cable, Vector3(-0.5 * spacing - 20.0, wire.x, wire.y), 0.5 * spacing + 20.0, wire.z, wire.w)
#@ 13+
		# De près, les fils ont leur vraie grosseur. À mi-distance, ils seraient plus fins qu'un
		# pixel et se liraient en pointillés : on les dessine deux fois plus gros. De loin, on ne
		# les dessine plus.
		for zone: int in [MeshBuilder.ZONE_NEAR, MeshBuilder.ZONE_MID]:
			mesh.set_zones(zone, false)
			var swell: float = 1.0 if zone == MeshBuilder.ZONE_NEAR else 2.0
			for wire: Vector4 in wires:
				_add_wire(mesh, cable, Vector3(0.0, wire.x, wire.y), span, swell * wire.z, wire.w)
				if index == 0:
					# Avant le premier poteau, les fils arrivent du bout de la rue.
					_add_wire(mesh, cable, Vector3(-0.5 * spacing - 20.0, wire.x, wire.y), 0.5 * spacing + 20.0, swell * wire.z, wire.w)
#@ all
		mesh.commit(holder)


## Un fil tendu le long de X, de « from » sur la longueur « span ». Un fil qui pend dessine
## une courbe : on l'approche par quelques segments droits, chacun une boîte fine tournée
## dans la pente de la courbe.
func _add_wire(mesh: MeshBuilder, material: Material, from: Vector3, span: float, thickness: float, sag: float) -> void:
	var previous: Vector3 = from
	for step: int in range(1, WIRE_SEGMENTS + 1):
		var t: float = float(step) / float(WIRE_SEGMENTS)
		# Une parabole : nulle aux deux bouts, « sag » au milieu.
		var point: Vector3 = from + Vector3(t * span, -4.0 * sag * t * (1.0 - t), 0.0)
		var segment: Vector3 = point - previous
		var tilt: Basis = Basis(Vector3.BACK, atan2(segment.y, segment.x))
		mesh.box(Vector3(segment.length() + 0.01, thickness, thickness), 0.5 * (previous + point), material, tilt)
		previous = point


## Matériau uni ordinaire.
func _plain(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
