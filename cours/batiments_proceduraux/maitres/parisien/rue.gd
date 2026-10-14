@tool
extends Node3D
## Rue parisienne : une ou deux faces d'immeubles tirés au sort, sous le gabarit de la voie.
## {STATUS}
##
## Ce script ne fabrique aucun triangle d'immeuble. Il fait trois choses :
##   1. il découpe la longueur de la rue en parcelles ;
##   2. pour chaque parcelle, il crée un immeuble (le script de l'étape précédente) et règle
##      ses variables par des tirages ;
##   3. il pose la chaussée et les trottoirs.
## C'est la leçon de l'étape : un générateur bien paramétré devient la brique d'un générateur
## plus grand. La rue ne sait rien des fenêtres ; elle ne connaît que des variables.
##
## Deux règles donnent son air à une rue parisienne :
##   - le gabarit : la hauteur des façades dépend de la largeur de la voie (règlements de
##     1783-1784 et de 1859, voir la palette dans 5_data) ;
##   - la régularité : dans un îlot haussmannien, balcons et corniches filent d'un immeuble à
##     l'autre. La variable « regularity » va de ce cas (1) à une rue où chacun a ses hauteurs (0).
##
## Repère de la rue : elle court le long de X, centrée sur l'origine ; l'axe de la chaussée
## est en z = 0 ; le dessus des trottoirs est à y = 0. Unité : le mètre.

const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
const Building := preload("{MESH}.gd")
const Palette := preload("{DATA}_palette.gd")

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Largeur d'une travée : la plus étroite et la plus large qu'on tire.
const BAY_WIDTH_MIN: float = 2.3
const BAY_WIDTH_MAX: float = 2.9
## Hauteur de la corniche d'un immeuble : elle compte dans la hauteur de la façade.
const CORNICE_HEIGHT: float = 0.5
## Hauteur de la bordure du trottoir au-dessus de la chaussée.
const CURB_HEIGHT: float = 0.14
const CURB_WIDTH: float = 0.3
## Deux voisins ne sont pas posés exactement dans le même plan : quelques millimètres d'écart
## évitent que leurs faces qui se recouvrent se disputent les mêmes pixels.
const FACADE_STAGGER: float = 0.004

@export_group("Voie")
## Longueur de la rue.
@export_range(30.0, 300.0, 1.0, "suffix:m") var street_length: float = 110.0
## Largeur de la voie, de façade à façade, trottoirs compris. Elle fixe la hauteur des façades.
@export_range(6.0, 40.0, 0.5, "suffix:m") var street_width: float = 20.0
## Largeur de chaque trottoir.
@export_range(1.0, 8.0, 0.1, "suffix:m") var sidewalk_width: float = 3.5
## Bâtir les deux côtés de la rue ; sinon, un seul.
@export var two_sides: bool = true

@export_group("Parcelles")
## Nombre de travées de l'immeuble le plus étroit, puis du plus large.
@export_range(2, 8, 1) var min_bays: int = 3
@export_range(2, 12, 1) var max_bays: int = 7
## 1 : tous les immeubles ont les mêmes hauteurs d'étage, balcons et corniches filent d'un bout
## à l'autre de la rue. 0 : chaque immeuble a les siennes, et certains sont plus bas.
@export_range(0.0, 1.0, 0.05) var regularity: float = 0.8

@export_group("Aspect")
## Part des immeubles à boutiques au rez-de-chaussée.
@export_range(0.0, 1.0, 0.05) var shop_share: float = 0.7
## Part des façades ravalées : pierre claire, peu de suie.
@export_range(0.0, 1.0, 0.05) var clean_share: float = 0.4
## Change tous les tirages de la rue.
@export var variation_seed: int = 1
#@ 13+

@export_group("Niveaux de détail")
## Jusqu'à cette distance, un immeuble est dessiné en entier. Au-delà, ses moulures
## redeviennent des boîtes. La rue donne ces deux distances à chacun de ses immeubles.
## 0 pour les deux : pas de niveaux de détail.
@export_range(0.0, 150.0, 1.0, "suffix:m") var near_distance: float = 30.0
## Au-delà de cette distance, il ne reste d'un immeuble que les murs, les fenêtres, les balcons
## et le toit.
@export_range(0.0, 400.0, 1.0, "suffix:m") var far_distance: float = 90.0
#@ all


## Hauteurs d'étage d'un immeuble : ce que la rue décide pour lui.
class Storeys:
	var ground_height: float = 4.1
	var entresol: bool = true
	var entresol_height: float = 2.7
	var noble_height: float = 3.7
	var floor_count: int = 2
	var floor_height: float = 3.15
	var top_floor: bool = true
	var top_floor_height: float = 2.95

	## Hauteur de la façade, corniche comprise.
	func total(cornice: float) -> float:
		var sum: float = ground_height + noble_height + float(floor_count) * floor_height + cornice
		if entresol:
			sum += entresol_height
		if top_floor:
			sum += top_floor_height
		return sum


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


func _ready() -> void:
	# Dans le jeu, la rue est montée une fois ; inutile de surveiller ses variables.
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(_delta: float) -> void:
	# Dans l'éditeur, à chaque image : une variable a-t-elle changé dans l'inspecteur ?
	if _current_signature() != _signature:
		rebuild()


## 0 : jour, 1 : nuit, pour tous les immeubles de la rue.
func set_night(value: float) -> void:
	_night = value
	for building: Building in _buildings:
		building.set_night(value)


#@ 13+
## Finesse de calcul des shaders, pour tous les immeubles de la rue : 0 basse, 1 moyenne, 2 haute.
func set_quality(level: int) -> void:
	_quality = level
	for building: Building in _buildings:
		building.set_quality(level)


#@ all
## Hauteur maximale d'une façade sur une voie de cette largeur, d'après la table de la palette.
static func facade_height_limit(width: float) -> float:
	for step: Vector2 in Palette.FACADE_HEIGHT_LIMITS:
		if width < step.x:
			return step.y
	return Palette.FACADE_HEIGHT_WIDE_STREET


## Démonte la rue et la remonte d'après les variables courantes.
func rebuild() -> void:
	_signature = _current_signature()

	# 1. On jette l'ancien résultat.
	for child: Node in get_children(true):
		if child.name == GENERATED_NAME:
			remove_child(child)
			child.queue_free()
	_buildings.clear()

	# 2. Un nœud « interne », qui n'est pas enregistré avec la scène : celle-ci ne garde que
	#    les variables de la rue.
	_root = Node3D.new()
	_root.name = GENERATED_NAME
	add_child(_root, false, Node.INTERNAL_MODE_BACK)

	# 3. Le gabarit de la voie, puis les hauteurs d'étage communes à la rue.
	var limit: float = facade_height_limit(street_width)
	var street_random: RandomNumberGenerator = RandomNumberGenerator.new()
	street_random.seed = hash([variation_seed, "gabarit"])
	var common: Storeys = _draw_storeys(street_random, limit)

	# 4. Les immeubles, un côté puis l'autre. Le côté -1 est en z négatif et regarde vers +Z.
	var sides: Array[float] = [-1.0]
	if two_sides:
		sides.append(1.0)
	for side: float in sides:
		_build_side(side, limit, common)

	# 5. Le sol.
	_build_ground()


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
## largeur d'une travée. La somme des largeurs vaut exactement la longueur de la rue.
func _draw_lots(random: RandomNumberGenerator) -> Array[Vector2]:
	var lots: Array[Vector2] = []
	var remaining: float = street_length
	# En dessous de cette largeur, il n'y a pas la place d'un immeuble.
	var narrowest: float = float(min_bays) * BAY_WIDTH_MIN
	while remaining > 0.01:
		var bays: int = random.randi_range(min_bays, maxi(min_bays, max_bays))
		var bay_width: float = snappedf(random.randf_range(BAY_WIDTH_MIN, BAY_WIDTH_MAX), 0.05)
		var width: float = float(bays) * bay_width
		if remaining - width < narrowest:
			# Dernière parcelle : elle prend tout ce qui reste. On choisit le nombre de travées
			# qui donne une travée de largeur ordinaire.
			bays = clampi(roundi(remaining / 2.6), 1, 12)
			bay_width = remaining / float(bays)
			width = remaining
		lots.append(Vector2(float(bays), bay_width))
		remaining -= width
	return lots


## Monte une face de la rue. « side » : -1 pour le côté des z négatifs, 1 pour l'autre.
func _build_side(side: float, limit: float, common: Storeys) -> void:
	var lot_random: RandomNumberGenerator = RandomNumberGenerator.new()
	lot_random.seed = hash([variation_seed, "parcelles", side])
	var lots: Array[Vector2] = _draw_lots(lot_random)

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
		_apply_storeys(building, _mix_storeys(random, limit, common))
		_apply_aspect(building, random)
#@ 13+
		building.near_distance = near_distance
		building.far_distance = far_distance
#@ all

		# L'immeuble est centré sur sa parcelle, sa façade sur l'alignement. De l'autre côté de
		# la rue, il fait demi-tour pour regarder la chaussée.
		var stagger: float = float(index % 3) * FACADE_STAGGER
		building.position = Vector3(x + 0.5 * width, 0.0, side * (0.5 * street_width - stagger))
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
		x += width


# --- Hauteurs d'étage -------------------------------------------------------

## Tire des hauteurs d'étage qui remplissent le gabarit « limit » sans le dépasser.
func _draw_storeys(random: RandomNumberGenerator, limit: float) -> Storeys:
	var storeys: Storeys = Storeys.new()
	storeys.ground_height = random.randf_range(3.8, 4.3)
	storeys.entresol_height = random.randf_range(2.5, 2.8)
	storeys.noble_height = random.randf_range(3.4, 3.8)
	storeys.floor_height = random.randf_range(3.0, 3.2)
	storeys.top_floor_height = random.randf_range(2.8, 3.0)
	# L'entresol est le signe des immeubles hauts : on ne le tire que sous un gabarit généreux.
	storeys.entresol = limit >= 17.0 and random.randf() < 0.7
	storeys.top_floor = true
	_fit_storeys(storeys, limit)
	return storeys


## Règle le nombre d'étages courants, puis étire ou tasse les hauteurs pour que la façade
## arrive juste sous le gabarit : c'est ce que faisaient les constructeurs.
func _fit_storeys(storeys: Storeys, limit: float) -> void:
	storeys.floor_count = 0
	# Un gabarit trop bas pour la composition complète : on retire l'entresol, puis le dernier étage.
	if storeys.total(CORNICE_HEIGHT) > limit:
		storeys.entresol = false
	if storeys.total(CORNICE_HEIGHT) > limit:
		storeys.top_floor = false
	# Le nombre d'étages courants le plus proche de ce que le gabarit permet.
	var spare: float = limit - storeys.total(CORNICE_HEIGHT)
	storeys.floor_count = clampi(roundi(spare / storeys.floor_height), 0, 6)
	# Tasser un étage sous la hauteur minimale n'est pas permis : on en retire plutôt un.
	var factor: float = (limit - CORNICE_HEIGHT) / (storeys.total(CORNICE_HEIGHT) - CORNICE_HEIGHT)
	var lowest: float = minf(storeys.floor_height, storeys.top_floor_height) if storeys.top_floor else storeys.floor_height
	if storeys.floor_count > 0 and lowest * factor < Palette.MIN_FLOOR_HEIGHT:
		storeys.floor_count -= 1
		factor = (limit - CORNICE_HEIGHT) / (storeys.total(CORNICE_HEIGHT) - CORNICE_HEIGHT)
	# On n'étire pas au-delà de 6 % : un immeuble peut rester un peu sous le gabarit.
	factor = minf(factor, 1.06)
	storeys.ground_height *= factor
	storeys.entresol_height *= factor
	storeys.noble_height *= factor
	storeys.floor_height *= factor
	storeys.top_floor_height *= factor


## Hauteurs d'étage d'un immeuble : celles de la rue, ou les siennes, selon la régularité.
func _mix_storeys(random: RandomNumberGenerator, limit: float, common: Storeys) -> Storeys:
	# Le dé est lancé dans tous les cas : la régularité ne décale pas les tirages suivants.
	var own_limit: float = limit * random.randf_range(0.72, 1.0)
	var own: Storeys = _draw_storeys(random, own_limit)
	if random.randf() < regularity:
		return common
	# Un immeuble qui suit ses propres hauteurs s'en écarte d'autant plus que la rue est libre.
	var storeys: Storeys = Storeys.new()
	storeys.ground_height = lerpf(own.ground_height, common.ground_height, regularity)
	storeys.entresol_height = lerpf(own.entresol_height, common.entresol_height, regularity)
	storeys.noble_height = lerpf(own.noble_height, common.noble_height, regularity)
	storeys.floor_height = lerpf(own.floor_height, common.floor_height, regularity)
	storeys.top_floor_height = lerpf(own.top_floor_height, common.top_floor_height, regularity)
	storeys.entresol = own.entresol
	storeys.top_floor = own.top_floor
	_fit_storeys(storeys, lerpf(own_limit, limit, regularity))
	return storeys


## Recopie les hauteurs d'étage dans les variables de l'immeuble.
func _apply_storeys(building: Building, storeys: Storeys) -> void:
	building.ground_height = storeys.ground_height
	building.entresol = storeys.entresol
	building.entresol_height = storeys.entresol_height
	building.noble_height = storeys.noble_height
	building.floor_count = storeys.floor_count
	building.floor_height = storeys.floor_height
	building.top_floor = storeys.top_floor
	building.top_floor_height = storeys.top_floor_height


# --- Aspect -----------------------------------------------------------------

## Tire tout ce qui distingue un immeuble de son voisin : pierre, portes, balcons, comble.
func _apply_aspect(building: Building, random: RandomNumberGenerator) -> void:
	var bays: int = building.bay_count

	# Pierre : une façade ravalée est claire et propre ; les autres vont du blond au gris. Les
	# teintes de la palette sont rangées de la plus claire à la plus sombre.
	var stones: Array[Color] = Palette.STONE_COLORS
	if random.randf() < clean_share:
		building.stone_color = stones[random.randi_range(0, 2)]
		building.soot = random.randf_range(0.03, 0.12)
		building.zinc_brightness = random.randf_range(0.95, 1.25)
	else:
		building.stone_color = stones[random.randi_range(3, stones.size() - 1)]
		building.soot = random.randf_range(0.2, 0.55)
		building.zinc_brightness = random.randf_range(0.75, 1.1)
	building.door_color = Palette.DOOR_COLORS[random.randi_range(0, Palette.DOOR_COLORS.size() - 1)]
	building.frame_color = Palette.FRAME_COLORS[random.randi_range(0, Palette.FRAME_COLORS.size() - 1)]
	building.course_height = random.randf_range(0.33, 0.40)
	building.rusticated_base = random.randf() < 0.8

	# Ornement : rarement nu, le plus souvent mouluré ou riche.
	var ornament_draw: float = random.randf()
	building.ornament = 0 if ornament_draw < 0.12 else (1 if ornament_draw < 0.55 else 2)

	# Baies et balcons.
	building.window_width = snappedf(random.randf_range(1.2, 1.4), 0.05)
	building.noble_balcony = snappedf(random.randf_range(0.75, 1.0), 0.05) if random.randf() < 0.85 else 0.0
	building.top_balcony = snappedf(random.randf_range(0.6, 0.8), 0.05) if random.randf() < 0.8 else 0.0

	# Rez-de-chaussée : une porte cochère sur les grandes parcelles, une porte piétonne sinon.
	building.shops = random.randf() < shop_share
	if bays >= 5:
		building.door_bay = clampi(floori(0.5 * float(bays)) + random.randi_range(-1, 1), 0, bays - 1)
		building.door_width = snappedf(random.randf_range(2.0, 2.3), 0.05)
	else:
		building.door_bay = 0 if random.randf() < 0.5 else bays - 1
		building.door_width = snappedf(random.randf_range(1.4, 1.7), 0.05)

	# Comble : le plus souvent raide, à la Mansart ; parfois à 45°, le profil du règlement.
	if random.randf() < 0.3:
		building.brisis_angle = random.randf_range(45.0, 55.0)
		building.brisis_length = random.randf_range(3.2, 3.8)
	else:
		building.brisis_angle = random.randf_range(62.0, 76.0)
		building.brisis_length = random.randf_range(2.6, 3.3)
	building.dormers = random.randf() < 0.92
	building.depth = snappedf(random.randf_range(9.0, 12.0), 0.5)

	# Les formes laissées « Selon la graine » (porte, garde-corps, lucarnes) et les boutiques
	# se tirent dans l'immeuble lui-même : il suffit de lui donner sa graine.
	building.variation_seed = random.randi_range(0, 1000000)


# --- Sol --------------------------------------------------------------------

## Chaussée, bordures et trottoirs. Le dessus des trottoirs est à y = 0 : c'est le sol des
## immeubles.
func _build_ground() -> void:
	var mesh: MeshBuilder = MeshBuilder.new()
	var asphalt: StandardMaterial3D = _plain(Color(0.11, 0.11, 0.12), 0.85)
	var paving: StandardMaterial3D = _plain(Color(0.36, 0.35, 0.34), 0.9)
	var granite: StandardMaterial3D = _plain(Color(0.50, 0.49, 0.47), 0.8)
	var half_width: float = 0.5 * street_width
	var walk: float = minf(sidewalk_width, half_width - 1.5)

	# Chaussée : elle déborde aux deux bouts de la rue et sous les trottoirs.
	mesh.box(Vector3(street_length + 80.0, 0.3, street_width), Vector3(0.0, -CURB_HEIGHT - 0.15, 0.0), asphalt)
	for side: float in [-1.0, 1.0]:
		# Trottoir, de la façade à la bordure.
		var inner: float = half_width - walk
		mesh.box(Vector3(street_length, 0.3, walk - CURB_WIDTH), Vector3(0.0, -0.15, side * (half_width - 0.5 * (walk - CURB_WIDTH))), paving)
		# Bordure de granit.
		mesh.box(Vector3(street_length, 0.3, CURB_WIDTH), Vector3(0.0, -0.15, side * (inner + 0.5 * CURB_WIDTH)), granite)
	# Un grand socle sombre, pour que la rue ne flotte pas dans le vide.
	mesh.box(Vector3(street_length + 600.0, 0.3, 600.0), Vector3(0.0, -CURB_HEIGHT - 0.17, 0.0), asphalt)
	mesh.commit(_root)


## Matériau uni ordinaire.
func _plain(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
