@tool
extends Node3D
## Immeuble parisien, monté par le code à partir des variables ci-dessous.
## {STATUS}
##
## Dans l'éditeur, changer une variable dans l'inspecteur reconstruit l'immeuble aussitôt.
## En jeu, changer des variables par le code puis appeler « rebuild() ».
##
## Ce que le script produit :
##   - un mur de façade percé de baies et un volume arrière nu ;
#@ 2-3 quiet
##   - rien d'autre pour l'instant : les étapes suivantes ajoutent une ligne à cette liste.
#@ all
#@ 4+ quiet
##   - une fenêtre dans chaque baie : un rectangle, dont le shader dessine tout le reste ;
#@ 6+ quiet
##   - des niveaux différents : soubassement, étage noble, étages courants, dernier étage ;
#@ 7+ quiet
##   - des balcons filants et leurs garde-corps de fer ;
#@ 8+ quiet
##   - des moulures : bandeaux, chambranles, corniche, selon le niveau d'ornement ;
#@ 9+ quiet
##   - un comble brisé en zinc, avec lucarnes et souches de cheminée ;
#@ 10+ quiet
##   - une porte d'entrée et des boutiques.
#@ 13+ quiet
## Chaque pièce n'est dessinée qu'aux distances où elle se voit : les ornements de près, leur
## version simplifiée au-delà. Voir « Niveaux de détail » dans les variables, et set_zones().
#@ all
##
## Comment il est organisé :
##   - ce script décide de la composition : combien de niveaux, quelle baie où ;
##   - « _materiaux » fabrique les matériaux ;
#@ 8+ quiet
##   - « _profils » dessine la section des moulures ;
#@ 9+ quiet
##   - « _toit » pose le comble ;
#@ 10+ quiet
##   - « _porte » et « _boutique » posent chacun leur objet ;
#@ all
##   - MeshBuilder (dans 1_core) transforme le tout en maillages, un par matériau.
##
## Repère de l'immeuble : la façade est dans le plan z = 0 et regarde vers +Z (la rue), elle
## est centrée sur x = 0, le sol est à y = 0, l'immeuble s'enfonce vers -Z. Unité : le mètre.
#@ 10+ quiet
##
## Limites : pas d'angle de rue, pas de façade sur cour, pas de sculpture figurée. Les cotes
## sont plausibles, elles ne sont pas relevées sur un immeuble réel.
#@ all

## L'outil commun de maillage : les fonctions _add_quad et _add_box de l'étape 001 y sont rangées.
const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
## Les matériaux de l'immeuble. « preload » charge le script une fois, à la lecture de celui-ci.
const Materials := preload("{MESH}_materiaux.gd")
#@ 8+
const Profiles := preload("{MESH}_profils.gd")
#@ 10+
const DoorBuilder := preload("{MESH}_porte.gd")
const ShopBuilder := preload("{MESH}_boutique.gd")
#@ 9+
const RoofBuilder := preload("{MESH}_toit.gd")
#@ all

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Épaisseur du mur de façade.
const WALL_DEPTH: float = 0.45
#@ 4+
## Retrait des fenêtres par rapport au nu du mur.
const WINDOW_RECESS: float = 0.22
#@ all
## Les morceaux de mur voisins se recouvrent de quelques millimètres : posés bord à bord, ils
## laisseraient passer un liseré de lumière à leur jonction.
const WALL_OVERLAP: float = 0.006
#@ 6+
## Hauteur de la corniche de couronnement.
const CORNICE_HEIGHT: float = 0.5
#@ 8+
## Saillie de la corniche de couronnement.
const CORNICE_DEPTH: float = 0.6
#@ 11+
## Écart de luminosité du zinc que la graine ajoute, en plus ou en moins.
const ZINC_SPREAD: float = 0.12
#@ 8+
## Niveaux d'ornement.
const ORNAMENT_PLAIN: int = 0
const ORNAMENT_MOULDED: int = 1
const ORNAMENT_RICH: int = 2
#@ all

@export_group("Plan")
## Nombre de travées : une fenêtre par travée et par niveau.
@export_range(1, 12, 1) var bay_count: int = 5
## Largeur d'une travée.
@export_range(1.8, 4.0, 0.05, "suffix:m") var bay_width: float = 2.6
## Profondeur de l'immeuble, de la façade au mur du fond.
@export_range(5.0, 20.0, 0.5, "suffix:m") var depth: float = 9.5

@export_group("Niveaux")
#@ 2-5
## Nombre de niveaux, rez-de-chaussée compris. Ils sont tous pareils jusqu'à l'étape 006.
@export_range(1, 8, 1) var floor_count: int = 5
## Hauteur d'un niveau, de plancher à plancher.
@export_range(2.6, 4.5, 0.05, "suffix:m") var floor_height: float = 3.2

@export_group("Baies")
## Largeur et hauteur du trou laissé dans le mur. Elles sont rabotées si la case est trop petite.
@export_range(0.8, 2.5, 0.05, "suffix:m") var window_width: float = 1.3
@export_range(0.8, 3.5, 0.05, "suffix:m") var window_height: float = 2.3
## Hauteur de l'allège : le morceau de mur sous la fenêtre. 0 : porte-fenêtre.
@export_range(0.0, 1.5, 0.05, "suffix:m") var sill_height: float = 0.4
#@ 6+
## Hauteur du rez-de-chaussée, de plancher à plancher.
@export_range(3.0, 5.5, 0.05, "suffix:m") var ground_height: float = 4.1
## Entresol au-dessus du rez-de-chaussée.
@export var entresol: bool = true
@export_range(2.2, 3.2, 0.05, "suffix:m") var entresol_height: float = 2.7
## Étage noble : le plus haut sous plafond, celui du grand balcon.
@export_range(2.8, 4.2, 0.05, "suffix:m") var noble_height: float = 3.7
## Nombre d'étages courants entre l'étage noble et le dernier étage.
@export_range(0, 6, 1) var floor_count: int = 2
@export_range(2.6, 3.6, 0.05, "suffix:m") var floor_height: float = 3.15
## Dernier étage sous la corniche.
@export var top_floor: bool = true
@export_range(2.5, 3.4, 0.05, "suffix:m") var top_floor_height: float = 2.95
#@ 10+

@export_group("Rez-de-chaussée")
## Travée de la porte d'entrée, comptée à partir de zéro. -1 : pas de porte.
@export_range(-1, 11, 1) var door_bay: int = 2
#@ 10
@export_enum("Rectangulaire à imposte", "Plein cintre", "Anse de panier") var door_style: int = 0
#@ 11+
@export_enum("Selon la graine", "Rectangulaire à imposte", "Plein cintre", "Anse de panier") var door_style: int = 0
#@ 10+
@export_range(1.2, 2.6, 0.05, "suffix:m") var door_width: float = 2.3
## Boutiques dans les autres travées ; sinon, des fenêtres.
@export var shops: bool = true
## Part des boutiques à vitrine pleine surface : une glace du seuil au linteau, sans menuiserie
## de bois. C'est un minimum dès que l'immeuble compte deux boutiques.
@export_range(0.0, 1.0, 0.05) var showcase_share: float = 0.35
## Stores au-dessus de certaines devantures de bois.
@export var awnings: bool = true
#@ 6+

@export_group("Façade")
## Largeur des baies des étages.
@export_range(0.9, 1.8, 0.05, "suffix:m") var window_width: float = 1.3
#@ 7+
## Profondeur du balcon filant de l'étage noble. 0 : pas de balcon, garde-corps dans les baies.
@export_range(0.0, 1.5, 0.05, "suffix:m") var noble_balcony: float = 0.85
## Profondeur du balcon filant du dernier étage. 0 : pas de balcon.
@export_range(0.0, 1.5, 0.05, "suffix:m") var top_balcony: float = 0.7
## Surhauteur des baies aux étages à balcon, par rapport aux autres étages.
@export_range(0.0, 0.6, 0.05, "suffix:m") var balcony_window_bonus: float = 0.3
#@ 8+
## Nu : baies sans encadrement. Mouluré : chambranles, bandeaux, corniche profilée.
## Riche : en plus, clefs, consoles, corniches de baie, chaînes d'angle.
@export_enum("Nu", "Mouluré", "Riche") var ornament: int = 2
#@ 7-10
## Motif des garde-corps de fer.
@export_enum("Barreaux", "Volutes", "Croisillons") var railing_motif: int = 1
#@ 11+
@export_enum("Selon la graine", "Barreaux", "Volutes", "Croisillons") var railing_motif: int = 0
#@ 6+
## Soubassement à refends (rainures horizontales).
@export var rusticated_base: bool = true
## Hauteur d'une assise de pierre.
@export_range(0.25, 0.6, 0.01, "suffix:m") var course_height: float = 0.38
#@ 9+

@export_group("Comble")
## Pente du brisis, la partie raide du comble. 45° donne le toit du règlement de 1859 ; au-delà,
## un comble à la Mansart.
@export_range(45.0, 85.0, 1.0, "degrees") var brisis_angle: float = 72.0
@export_range(1.5, 4.5, 0.05, "suffix:m") var brisis_length: float = 3.1
@export var dormers: bool = true
#@ 9-10
@export_enum("Rectangulaire", "Cintrée", "À fronton", "Œil-de-bœuf") var dormer_style: int = 1
#@ 11+
@export_enum("Selon la graine", "Rectangulaire", "Cintrée", "À fronton", "Œil-de-bœuf", "Alternée") var dormer_style: int = 0
#@ 9+
@export var chimneys: bool = true
#@ all

@export_group("Aspect")
#@ 2
## Teinte de la pierre. Le script la donne aux matériaux, qui la donnent au shader.
@export var stone_color: Color = Color(0.85, 0.76, 0.62)
#@ 3+
## Teinte de la pierre, du blanc crème d'une façade ravalée au gris d'une façade encrassée.
@export var stone_color: Color = Color(0.85, 0.76, 0.62)
## Encrassement de la pierre, de 0 (ravalée) à 1 (noire de suie).
@export_range(0.0, 1.0, 0.01) var soot: float = 0.25
#@ 9-10
## Luminosité du zinc du toit. Sous 1 : vieux zinc sombre. Au-dessus : zinc récent, clair.
@export_range(0.6, 1.4, 0.01) var zinc_brightness: float = 1.0
#@ 11+
## Luminosité du zinc du toit. Sous 1 : vieux zinc sombre. Au-dessus : zinc récent, clair.
## La graine y ajoute un petit écart, pour que deux toits voisins ne soient pas identiques.
@export_range(0.6, 1.4, 0.01) var zinc_brightness: float = 1.0
#@ 10+
## Teinte de la porte d'entrée.
@export var door_color: Color = Color(0.05, 0.16, 0.24)
#@ 4+
## Teinte des menuiseries de fenêtre.
@export var frame_color: Color = Color(0.86, 0.86, 0.83)
#@ 11+
## Change tous les tirages : pièces, assises, formes laissées « Selon la graine », boutiques.
@export var variation_seed: int = 0
#@ 13+

@export_group("Niveaux de détail")
## Jusqu'à cette distance, l'immeuble est dessiné en entier. Au-delà, les moulures redeviennent
## des boîtes et les petits ornements disparaissent. La distance est comptée de la caméra au
## centre de l'immeuble. 0 pour les deux distances : pas de niveaux de détail.
@export_range(0.0, 150.0, 1.0, "suffix:m") var near_distance: float = 30.0
## Au-delà de cette distance, il ne reste que les murs, les fenêtres, les balcons et le toit.
@export_range(0.0, 400.0, 1.0, "suffix:m") var far_distance: float = 90.0
#@ 6+


## Un niveau de la façade, tel que le décrivent les variables. « _make_levels() » en fait la
## liste, du rez-de-chaussée au dernier étage ; « _build_level() » les monte un par un.
class Level:
	var height: float = 3.0
	## Largeur et hauteur de la baie.
	var opening: Vector2 = Vector2(1.3, 2.3)
	## Hauteur de l'allège sous la baie.
	var sill: float = 0.1
#@ 7+
	## Profondeur du balcon filant, 0 s'il n'y en a pas.
	var balcony: float = 0.0
#@ 6+
	## Niveau de soubassement : pierre à refends.
	var base: bool = false
#@ 8+
	## Étage noble : une corniche au-dessus de chaque baie.
	var noble: bool = false
#@ all


## Empreinte des variables au moment de la dernière construction.
var _signature: int = 0
#@ 5+
## 0 : jour, 1 : nuit. Gardé pour le redonner aux matériaux après une reconstruction.
var _night: float = 0.0
#@ 13+
## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Gardée de la même façon.
var _quality: int = 2
#@ all
## Le nœud interne qui porte tout ce qu'on fabrique, l'outil de maillage, les matériaux.
var _root: Node3D
var _mesh: MeshBuilder
var _materials: Materials
#@ 10+
## Le dé de l'immeuble. Sa graine est fixée au début de chaque construction.
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
#@ all


func _ready() -> void:
	# Dans le jeu, l'immeuble est monté une fois ; inutile de surveiller ses variables.
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(_delta: float) -> void:
	# Dans l'éditeur, à chaque image : une variable a-t-elle changé dans l'inspecteur ?
	if _current_signature() != _signature:
		rebuild()


## Largeur de la façade sur rue.
func get_facade_width() -> float:
	return float(bay_count) * bay_width
#@ 12+


## Hauteur de la façade, du sol au haut de la corniche. Le test de la rue s'en sert pour
## vérifier qu'aucun immeuble ne dépasse le gabarit.
func get_facade_height() -> float:
	var height: float = CORNICE_HEIGHT
	for level: Level in _make_levels():
		height += level.height
	return height
#@ 5+


## 0 : jour, 1 : nuit. Allume ou éteint les pièces derrière les fenêtres.
func set_night(value: float) -> void:
	_night = value
	if _materials != null:
		_materials.set_night(_night)
#@ 13+


## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Ce n'est pas une variable de
## l'immeuble mais un réglage de la machine : il se change sans rien reconstruire.
func set_quality(level: int) -> void:
	_quality = level
	if _materials != null:
		_materials.set_quality(_quality)
#@ all


## Démonte l'immeuble et le remonte d'après les variables courantes.
func rebuild() -> void:
	_signature = _current_signature()

	# On jette l'ancien résultat.
	for child: Node in get_children(true):
		if child.name == GENERATED_NAME:
			remove_child(child)
			child.queue_free()

	# On prépare un nœud « interne » : il n'apparaît pas dans l'arbre de la scène et n'est pas
	# enregistré avec elle. La scène ne garde que les variables, jamais la géométrie.
	_root = Node3D.new()
	_root.name = GENERATED_NAME
	add_child(_root, false, Node.INTERNAL_MODE_BACK)

#@ 10
	# Les boutiques tirent au sort leurs noms et leurs teintes. Le dé repart toujours de la
	# même graine : l'immeuble est le même à chaque construction. L'étape 011 rendra cette
	# graine réglable.
	_random.seed = 0
	# Dans la liste de l'inspecteur, les formes de porte sont numérotées à partir de 0 ; le
	# script de la porte les numérote à partir de 1.
	var door_choice: int = door_style + 1

#@ 11+
	# Les tirages. Ils se font toujours dans le même ordre, à partir de la même graine : une
	# graine donne donc toujours le même immeuble.
	_random.seed = hash(variation_seed)
	var door_choice: int = _pick(door_style, 3)
	var railing_choice: int = _pick(railing_motif, 3)
	var dormer_choice: int = _pick(dormer_style, 5)
	var dormer_styles: PackedInt32Array = PackedInt32Array()
	if dormers and dormer_choice == 5:
		# Alternée : deux formes différentes, une travée sur deux.
		var first: int = _random.randi_range(1, 4)
		dormer_styles = PackedInt32Array([first, 1 + (first + _random.randi_range(0, 2)) % 4])
	elif dormers:
		dormer_styles = PackedInt32Array([dormer_choice])
	# Un dé à part pour le zinc : ce tirage ne décale pas tous les autres.
	var zinc_random: RandomNumberGenerator = RandomNumberGenerator.new()
	zinc_random.seed = hash([variation_seed, "zinc"])
	var zinc_tone: float = zinc_brightness * zinc_random.randf_range(1.0 - ZINC_SPREAD, 1.0 + ZINC_SPREAD)

#@ all
	# Les matériaux d'abord : chaque forme donnée à l'outil de maillage est rangée d'après son
	# matériau. On règle, puis on fabrique.
	_materials = Materials.new()
	_materials.stone_color = stone_color
#@ 3+
	_materials.soot = soot
#@ 4+
	_materials.frame_color = frame_color
#@ 6+
	_materials.course_height = course_height
	_materials.rusticated = rusticated_base
#@ 7-10
	_materials.railing_motif = railing_motif
#@ 11+
	# Les motifs sont numérotés à partir de 0 dans le shader, à partir de 1 dans le tirage.
	_materials.railing_motif = railing_choice - 1
#@ 9-10
	_materials.zinc_brightness = zinc_brightness
#@ 11+
	_materials.zinc_brightness = zinc_tone
#@ 10+
	_materials.door_color = door_color
#@ 11+
	_materials.variation_seed = variation_seed
#@ 13+
	_materials.quality = _quality
#@ all
	_materials.build()
#@ 5+
	_materials.set_night(_night)
#@ all
	_mesh = MeshBuilder.new()
#@ 13+
	# Les distances des niveaux de détail. L'outil de maillage s'en sert pour ranger chaque
	# pièce dans sa zone : voir set_zones().
	_mesh.near_distance = near_distance
	_mesh.far_distance = far_distance
#@ all

#@ 2-5
	# La façade, niveau par niveau.
	for level: int in range(floor_count):
		_build_level(level)

	# Le volume arrière : une boîte nue derrière la façade.
	var height: float = float(floor_count) * floor_height
	_mesh.box(Vector3(get_facade_width(), height, depth - WALL_DEPTH),
			Vector3(0.0, 0.5 * height, -0.5 * (depth + WALL_DEPTH)), _materials.plaster)
#@ 6+
	# La façade, niveau par niveau. « base_y » monte d'un niveau à chaque tour.
	var levels: Array[Level] = _make_levels()
	var base_y: float = 0.0
#@ 8+
	# Hauteur où finit le soubassement : les chaînes d'angle partent de là.
	var first_plain_y: float = 0.0
#@ 6+
	for index: int in range(levels.size()):
#@ 8+
		if levels[index].base:
			first_plain_y = base_y + levels[index].height
#@ 6-9
		base_y = _build_level(levels[index], index, base_y)
#@ 10+
		base_y = _build_level(levels[index], index, base_y, door_choice)
#@ 8+
	if ornament >= ORNAMENT_RICH:
		_build_quoins(first_plain_y, base_y)
#@ 6+
	_build_cornice(base_y)

#@ 9+
	# Le comble, posé sur la corniche. Il reçoit l'abscisse de chaque travée, pour y aligner
	# ses lucarnes.
	var bay_centers: PackedFloat32Array = PackedFloat32Array()
	for bay: int in range(bay_count):
		bay_centers.append(_bay_center(bay))
#@ 9-10
	# Forme des lucarnes : numérotée à partir de 0 dans l'inspecteur, de 1 dans le script du toit.
	var dormer_styles: PackedInt32Array = PackedInt32Array()
	if dormers:
		dormer_styles = PackedInt32Array([dormer_style + 1])
#@ 9+
	RoofBuilder.build(_mesh, _materials, get_facade_width(), depth, base_y + CORNICE_HEIGHT, bay_centers, bay_width,
			brisis_angle, brisis_length, dormer_styles, chimneys)

#@ 6+
	# Le volume arrière : une boîte nue derrière la façade.
	_mesh.box(Vector3(get_facade_width(), base_y + CORNICE_HEIGHT, depth - WALL_DEPTH),
			Vector3(0.0, 0.5 * (base_y + CORNICE_HEIGHT), -0.5 * (depth + WALL_DEPTH)), _materials.plaster)
#@ all

	# commit() fait un maillage par matériau et les accroche sous le nœud interne.
	_mesh.commit(_root)


# --- Variables --------------------------------------------------------------

## Empreinte de toutes les variables exportées : si elle change, il faut reconstruire.
## On demande au script la liste de ses propres variables, on garde celles que l'inspecteur
## montre, et on hache leurs valeurs en un seul nombre.
func _current_signature() -> int:
	var values: Array[Variant] = []
	var properties: Array[Dictionary] = (get_script() as Script).get_script_property_list()
	for index: int in range(properties.size()):
		# « usage » est un champ de bits : on ne garde que les variables du script (pas les
		# groupes) que l'inspecteur affiche, c'est-à-dire les @export.
		var usage: int = properties[index]["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_EDITOR:
			values.append(get(properties[index]["name"]))
	# hash() d'un tableau dépend de toutes ses valeurs : une seule change, le nombre change.
	return hash(values)
#@ 11+


## Choix d'une liste dont la première ligne est « Selon la graine ». 0 : on tire au sort
## entre 1 et « count ». Sinon : on garde le choix. Le dé est lancé dans les deux cas, pour
## que fixer un choix à la main ne décale pas tous les tirages suivants.
func _pick(choice: int, count: int) -> int:
	var drawn: int = _random.randi_range(1, count)
	return choice if choice > 0 else drawn
#@ 6+


## Traduit les variables en une liste de niveaux, du rez-de-chaussée au dernier étage.
func _make_levels() -> Array[Level]:
	var levels: Array[Level] = []

#@ 6-9
	# Rez-de-chaussée : des fenêtres placées haut, à l'abri des regards.
	var ground: Level = Level.new()
	ground.height = ground_height
	ground.base = true
	ground.sill = 1.0
	ground.opening = Vector2(window_width, ground_height - 1.75)
	levels.append(ground)
#@ 10+
	# Rez-de-chaussée : de grandes baies de boutique, ou des fenêtres placées haut.
	var ground: Level = Level.new()
	ground.height = ground_height
	ground.base = true
	if shops:
		ground.sill = 0.15
		ground.opening = Vector2(bay_width - 0.7, ground_height - 0.9)
	else:
		ground.sill = 1.0
		ground.opening = Vector2(window_width, ground_height - 1.75)
	levels.append(ground)
#@ 6+

	# Entresol : un étage bas, qui fait encore partie du soubassement.
	if entresol:
		var low: Level = Level.new()
		low.height = entresol_height
		low.base = true
		low.sill = 0.55
		low.opening = Vector2(window_width, entresol_height - 0.95)
		levels.append(low)

#@ 6
	# Étage noble : le plus haut sous plafond.
	var noble: Level = Level.new()
	noble.height = noble_height
#@ 7+
	# Étage noble : le plus haut, avec le grand balcon.
	var noble: Level = Level.new()
	noble.height = noble_height
#@ 8+
	noble.noble = true
#@ 7+
	noble.balcony = noble_balcony
#@ 6+
	noble.opening = Vector2(window_width, noble_height - 1.05)
	levels.append(noble)

	# Étages courants : tous pareils, des baies un peu plus étroites.
	for _index: int in range(floor_count):
		var standard: Level = Level.new()
		standard.height = floor_height
		standard.opening = Vector2(window_width - 0.05, floor_height - 0.8)
		levels.append(standard)

#@ 6
	# Dernier étage : plus bas que les autres.
	if top_floor:
		var top: Level = Level.new()
		top.height = top_floor_height
#@ 7+
	# Dernier étage : plus bas, avec le second balcon.
	if top_floor:
		var top: Level = Level.new()
		top.height = top_floor_height
		top.balcony = top_balcony
#@ 6+
		top.opening = Vector2(window_width - 0.1, top_floor_height - 0.8)
		levels.append(top)
#@ 7+

	# Aux étages à balcon, les portes-fenêtres montent plus haut que les autres baies.
	for level: Level in levels:
		if level.balcony > 0.0:
			level.opening.y = minf(level.opening.y + balcony_window_bonus, level.height - level.sill - 0.42)
#@ 6+
	return levels
#@ all


# --- Façade -----------------------------------------------------------------

## Abscisse du milieu d'une travée, la façade étant centrée sur x = 0.
func _bay_center(bay: int) -> float:
	return (float(bay) - 0.5 * float(bay_count - 1)) * bay_width


## Morceau de mur : une boîte, élargie du recouvrement.
func _wall(size: Vector3, center: Vector3, material: Material) -> void:
	_mesh.box(size + Vector3(WALL_OVERLAP, WALL_OVERLAP, 0.0), center, material)


#@ 2-5
## Monte un niveau : pour chaque travée, du mur tout autour de la baie.
func _build_level(level: int) -> void:
	var base_y: float = float(level) * floor_height
	# Le mur est derrière le plan z = 0 : son milieu est à une demi-épaisseur en arrière.
	var wall_z: float = -0.5 * WALL_DEPTH
	# La baie ne peut pas être plus grande que sa case.
	var opening: Vector2 = Vector2(
			minf(window_width, bay_width - 0.3),
			minf(window_height, floor_height - sill_height - 0.2))
	var pier: float = 0.5 * (bay_width - opening.x)
	var lintel: float = floor_height - sill_height - opening.y

	for bay: int in range(bay_count):
		var x: float = _bay_center(bay)
		# On ne perce pas un mur : on pose du mur autour du trou.
		# Trumeaux : le mur plein à gauche et à droite de la baie, sur toute la hauteur du niveau.
		_wall(Vector3(pier, floor_height, WALL_DEPTH),
				Vector3(x - 0.5 * bay_width + 0.5 * pier, base_y + 0.5 * floor_height, wall_z), _materials.stone)
		_wall(Vector3(pier, floor_height, WALL_DEPTH),
				Vector3(x + 0.5 * bay_width - 0.5 * pier, base_y + 0.5 * floor_height, wall_z), _materials.stone)
		# Allège : le mur sous la baie.
		if sill_height > 0.001:
			_wall(Vector3(opening.x, sill_height, WALL_DEPTH),
					Vector3(x, base_y + 0.5 * sill_height, wall_z), _materials.stone)
		# Linteau : le mur au-dessus de la baie.
		_wall(Vector3(opening.x, lintel, WALL_DEPTH),
				Vector3(x, base_y + floor_height - 0.5 * lintel, wall_z), _materials.stone)
#@ 4-5
		# La fenêtre : un rectangle instancié, de la taille de la baie, en retrait du mur. Le
		# script ne pose que ce rectangle ; tout le reste (menuiserie, vitrage) est dessiné par
		# son shader. Le repère dit où est son centre et vers où il regarde : ici +Z, la rue.
		var center: Vector3 = Vector3(x, base_y + sill_height + 0.5 * opening.y, -WINDOW_RECESS)
		_mesh.panel(opening, Transform3D(Basis.IDENTITY, center), _materials.window)
#@ 6-9
## Monte un niveau posé à la hauteur « base_y » et renvoie la hauteur de son plancher haut.
func _build_level(level: Level, index: int, base_y: float) -> float:
#@ 10+
## Monte un niveau posé à la hauteur « base_y » et renvoie la hauteur de son plancher haut.
func _build_level(level: Level, index: int, base_y: float, door_choice: int) -> float:
#@ 6+
	var width: float = get_facade_width()
	var top_y: float = base_y + level.height
	# Le mur est derrière le plan z = 0 : son milieu est à une demi-épaisseur en arrière.
	var wall_z: float = -0.5 * WALL_DEPTH
	# Le soubassement a sa pierre, à refends ; les étages ont la leur, lisse.
	var wall_material: ShaderMaterial = _materials.stone_base if level.base else _materials.stone
#@ 7+
	# Sans balcon, une porte-fenêtre reçoit un garde-corps dans sa baie.
	var guard: bool = not level.base and level.balcony <= 0.0 and level.sill < 0.3
#@ 10+
	# Abscisses des travées de boutique : elles sont habillées ensemble, après la boucle.
	var shop_bays: PackedFloat32Array = PackedFloat32Array()
#@ 6+

	for bay: int in range(bay_count):
		var x: float = _bay_center(bay)
#@ 6-9
		# La baie ne peut pas être plus large que sa travée.
		var size: Vector2 = level.opening
		size.x = minf(size.x, bay_width - 0.3)
		var bottom: float = base_y + level.sill
#@ 10+
		var is_door: bool = index == 0 and bay == door_bay
		var is_shop: bool = index == 0 and shops and not is_door
		# La porte a sa propre taille, et pas d'allège. Aucune baie ne peut être plus large que
		# sa travée.
		var size: Vector2 = Vector2(door_width, level.height - 0.55) if is_door else level.opening
		size.x = minf(size.x, bay_width - 0.3)
		var bottom: float = base_y + (0.0 if is_door else level.sill)
#@ 6+
		var pier: float = 0.5 * (bay_width - size.x)

		# On ne perce pas un mur : on pose du mur autour du trou. Trumeaux de part et d'autre
		# de la baie, allège dessous, linteau dessus.
		_wall(Vector3(pier, level.height, WALL_DEPTH), Vector3(x - 0.5 * bay_width + 0.5 * pier, base_y + 0.5 * level.height, wall_z), wall_material)
		_wall(Vector3(pier, level.height, WALL_DEPTH), Vector3(x + 0.5 * bay_width - 0.5 * pier, base_y + 0.5 * level.height, wall_z), wall_material)
		if bottom - base_y > 0.001:
			_wall(Vector3(size.x, bottom - base_y, WALL_DEPTH), Vector3(x, 0.5 * (base_y + bottom), wall_z), wall_material)
		var lintel: float = top_y - (bottom + size.y)
		_wall(Vector3(size.x, lintel, WALL_DEPTH), Vector3(x, top_y - 0.5 * lintel, wall_z), wall_material)

#@ 6-9
		# Une fenêtre est un rectangle instancié, en retrait du mur ; son shader fait le reste.
		_mesh.panel(size, Transform3D(Basis.IDENTITY, Vector3(x, bottom + 0.5 * size.y, -WINDOW_RECESS)), _materials.window)
#@ 8-9
		_build_surround(level, x, bottom, size)
#@ 7-9
		if guard:
			# Garde-corps de baie : un rectangle instancié de plus, presque au nu du mur.
			var rail: Vector2 = Vector2(size.x, 0.95)
			_mesh.panel(rail, Transform3D(Basis.IDENTITY, Vector3(x, bottom + 0.5 * rail.y, -0.05)), _materials.railing)
#@ 10-12
		# Ce qui remplit le trou : une porte, une boutique ou une fenêtre.
		if is_door:
			DoorBuilder.build(_mesh, _materials, door_choice, x, base_y, size.x, size.y, WALL_DEPTH, wall_material, ornament)
		elif is_shop:
			shop_bays.append(x)
		else:
			# Une fenêtre est un rectangle instancié, en retrait du mur ; son shader fait le reste.
			_mesh.panel(size, Transform3D(Basis.IDENTITY, Vector3(x, bottom + 0.5 * size.y, -WINDOW_RECESS)), _materials.window)
			_build_surround(level, x, bottom, size)
			if guard:
				# Garde-corps de baie : un rectangle instancié de plus, presque au nu du mur.
				var rail: Vector2 = Vector2(size.x, 0.95)
				_mesh.panel(rail, Transform3D(Basis.IDENTITY, Vector3(x, bottom + 0.5 * rail.y, -0.05)), _materials.railing)
#@ 13+
		# Ce qui remplit le trou : une porte, une boutique ou une fenêtre.
		if is_door:
			DoorBuilder.build(_mesh, _materials, door_choice, x, base_y, size.x, size.y, WALL_DEPTH, wall_material, ornament)
		elif is_shop:
			shop_bays.append(x)
		else:
			# Une fenêtre est un rectangle instancié, en retrait du mur ; son shader fait le reste.
			# Elle est dessinée à toute distance, mais ne porte pas d'ombre : elle est au fond de
			# sa baie, son ombre ne tomberait sur rien.
			_mesh.set_zones(MeshBuilder.ZONE_ALL, false)
			_mesh.panel(size, Transform3D(Basis.IDENTITY, Vector3(x, bottom + 0.5 * size.y, -WINDOW_RECESS)), _materials.window)
			# L'encadrement est un ornement fin : de près seulement, et sans ombre portée.
			_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
			_build_surround(level, x, bottom, size)
			if guard:
				# Garde-corps de baie : un rectangle instancié de plus, presque au nu du mur. De
				# loin, ses fers sont plus fins qu'un pixel : il n'est plus dessiné.
				_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
				var rail: Vector2 = Vector2(size.x, 0.95)
				_mesh.panel(rail, Transform3D(Basis.IDENTITY, Vector3(x, bottom + 0.5 * rail.y, -0.05)), _materials.railing)
			# On revient toujours à la normale : la suite ne doit pas hériter d'une zone.
			_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 10+

	if not shop_bays.is_empty():
		ShopBuilder.build(_mesh, _materials, _random, shop_bays, bay_width, level.opening, level.sill, base_y, level.height, awnings, showcase_share)
#@ 6

	if index > 0:
		# Bandeau filant entre deux niveaux : une simple boîte, qui déborde un peu du mur.
		_mesh.box(Vector3(width, 0.2, 0.1), Vector3(0.0, base_y, 0.05), _materials.stone)
#@ 7

	if level.balcony > 0.0:
		_build_balcony(base_y, level.balcony)
	elif index > 0:
		# Bandeau filant entre deux niveaux : une simple boîte, qui déborde un peu du mur.
		_mesh.box(Vector3(width, 0.2, 0.1), Vector3(0.0, base_y, 0.05), _materials.stone)
#@ 8-12

	if level.balcony > 0.0:
		_build_balcony(base_y, level.balcony)
	elif index > 0:
		# Bandeau filant entre deux niveaux : un profil extrudé, ou une simple boîte.
		if ornament >= ORNAMENT_MOULDED:
			_mesh.extrude(Profiles.string_course(0.22, 0.11), MeshBuilder.along_x(Vector3(0.0, base_y - 0.11, 0.0)), width, _materials.stone)
		else:
			_mesh.box(Vector3(width, 0.2, 0.1), Vector3(0.0, base_y, 0.05), _materials.stone)
#@ 13+

	if level.balcony > 0.0:
		_build_balcony(base_y, level.balcony)
	elif index > 0:
		# Bandeau filant entre deux niveaux. Mouluré : le profil de près, et la simple boîte de
		# l'immeuble nu au-delà. De loin, un immeuble riche redevient un immeuble nu.
		if ornament >= ORNAMENT_MOULDED:
			_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
			_mesh.extrude(Profiles.string_course(0.22, 0.11), MeshBuilder.along_x(Vector3(0.0, base_y - 0.11, 0.0)), width, _materials.stone)
			_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
			_mesh.box(Vector3(width, 0.2, 0.1), Vector3(0.0, base_y, 0.05), _materials.stone)
			_mesh.set_zones(MeshBuilder.ZONE_ALL)
		else:
			_mesh.box(Vector3(width, 0.2, 0.1), Vector3(0.0, base_y, 0.05), _materials.stone)
#@ 6+
	return top_y
#@ 8+


## Encadrement d'une baie : chambranle, appui, clef, corniche de baie selon le niveau d'ornement.
func _build_surround(level: Level, x: float, bottom: float, size: Vector2) -> void:
	var stone: ShaderMaterial = _materials.stone
	if level.sill > 0.3:
		# Appui de fenêtre.
		if ornament >= ORNAMENT_MOULDED:
			_mesh.extrude(Profiles.sill(0.09, 0.16), MeshBuilder.along_x(Vector3(x, bottom - 0.09, 0.0)), size.x + 0.3, stone)
		else:
			_mesh.box(Vector3(size.x + 0.2, 0.08, 0.14), Vector3(x, bottom - 0.04, 0.02), stone)
	if level.base or ornament < ORNAMENT_MOULDED:
		return

	# Chambranle : deux montants et une traverse. Le même profil, extrudé dans trois repères.
	var band_width: float = 0.16
	var band: PackedVector2Array = Profiles.architrave(band_width, 0.06)
	var head_y: float = bottom + size.y
	for side: float in [-1.0, 1.0]:
		_mesh.extrude(band, MeshBuilder.jamb(Vector3(x + side * 0.5 * size.x, bottom + 0.5 * size.y, 0.0), side), size.y, stone)
	_mesh.extrude(band, MeshBuilder.head(Vector3(x, head_y, 0.0)), size.x + 2.0 * band_width, stone)

	if level.noble:
		# Étage noble : une corniche au-dessus de chaque baie, sur consoles si l'ornement est riche.
		var shelf_y: float = head_y + band_width + 0.03
		_mesh.extrude(Profiles.cornice(0.15, 0.2), MeshBuilder.along_x(Vector3(x, shelf_y, 0.0)), size.x + 0.62, stone)
		if ornament >= ORNAMENT_RICH:
			for side: float in [-1.0, 1.0]:
				_mesh.extrude(Profiles.console(0.3, 0.15), MeshBuilder.along_x(Vector3(x + side * (0.5 * size.x + 0.21), shelf_y - 0.3, 0.0)), 0.1, stone)
	elif ornament >= ORNAMENT_RICH:
		# Clef au milieu de la traverse.
		_mesh.extrude(Profiles.keystone(0.15, 0.21, 0.24), MeshBuilder.facing_street(Vector3(x, head_y - 0.03, 0.04)), 0.1, stone)
#@ 7


## Balcon filant : une dalle, des consoles sous chaque trumeau, un garde-corps de fer.
func _build_balcony(base_y: float, reach: float) -> void:
	var width: float = get_facade_width()
	var stone: ShaderMaterial = _materials.stone
	# La dalle.
	_mesh.box(Vector3(width, 0.18, reach), Vector3(0.0, base_y - 0.09, 0.5 * reach), stone)
	# Une console à chaque limite de travée, ramenée vers l'intérieur aux deux bouts. Deux
	# boîtes en escalier suffisent à la faire lire.
	for edge: int in range(bay_count + 1):
		var console_x: float = clampf((float(edge) - 0.5 * float(bay_count)) * bay_width, -0.5 * width + 0.16, 0.5 * width - 0.16)
		_mesh.box(Vector3(0.28, 0.22, reach * 0.85), Vector3(console_x, base_y - 0.27, 0.5 * reach * 0.85), stone)
		_mesh.box(Vector3(0.24, 0.26, reach * 0.5), Vector3(console_x, base_y - 0.51, 0.5 * reach * 0.5), stone)
#@ 8-12


## Balcon filant : dalle au nez mouluré, consoles sous chaque trumeau, garde-corps de fer.
func _build_balcony(base_y: float, reach: float) -> void:
	var width: float = get_facade_width()
	var stone: ShaderMaterial = _materials.stone
	# La dalle, puis sa moulure de nez.
	_mesh.box(Vector3(width, 0.18, reach), Vector3(0.0, base_y - 0.09, 0.5 * reach), stone)
	if ornament >= ORNAMENT_MOULDED:
		_mesh.extrude(Profiles.string_course(0.2, 0.07), MeshBuilder.along_x(Vector3(0.0, base_y - 0.2, reach)), width, stone)
	# Une console à chaque limite de travée, ramenée vers l'intérieur aux deux bouts : un profil
	# en S extrudé, ou deux boîtes en escalier.
	for edge: int in range(bay_count + 1):
		var console_x: float = clampf((float(edge) - 0.5 * float(bay_count)) * bay_width, -0.5 * width + 0.16, 0.5 * width - 0.16)
		if ornament >= ORNAMENT_MOULDED:
			_mesh.extrude(Profiles.console(0.58, 0.82 * reach), MeshBuilder.along_x(Vector3(console_x, base_y - 0.18 - 0.58, 0.0)), 0.24, stone)
		else:
			_mesh.box(Vector3(0.28, 0.22, reach * 0.85), Vector3(console_x, base_y - 0.27, 0.5 * reach * 0.85), stone)
			_mesh.box(Vector3(0.24, 0.26, reach * 0.5), Vector3(console_x, base_y - 0.51, 0.5 * reach * 0.5), stone)
#@ 13+


## Balcon filant : dalle au nez mouluré, consoles sous chaque trumeau, garde-corps de fer.
func _build_balcony(base_y: float, reach: float) -> void:
	var width: float = get_facade_width()
	var stone: ShaderMaterial = _materials.stone
	var moulded: bool = ornament >= ORNAMENT_MOULDED
	# La dalle se voit de partout et porte une grande ombre : elle vit dans toutes les zones.
	_mesh.box(Vector3(width, 0.18, reach), Vector3(0.0, base_y - 0.09, 0.5 * reach), stone)
	# Sa moulure de nez : de près seulement.
	if moulded:
		_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
		_mesh.extrude(Profiles.string_course(0.2, 0.07), MeshBuilder.along_x(Vector3(0.0, base_y - 0.2, reach)), width, stone)
	# Une console à chaque limite de travée, ramenée vers l'intérieur aux deux bouts : un profil
	# en S extrudé, ou deux boîtes en escalier. Elles sont sous la dalle, dans son ombre : on
	# ne les dessine que de près, et elles ne portent pas d'ombre.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
	for edge: int in range(bay_count + 1):
		var console_x: float = clampf((float(edge) - 0.5 * float(bay_count)) * bay_width, -0.5 * width + 0.16, 0.5 * width - 0.16)
		if moulded:
			_mesh.extrude(Profiles.console(0.58, 0.82 * reach), MeshBuilder.along_x(Vector3(console_x, base_y - 0.18 - 0.58, 0.0)), 0.24, stone)
		else:
			_mesh.box(Vector3(0.28, 0.22, reach * 0.85), Vector3(console_x, base_y - 0.27, 0.5 * reach * 0.85), stone)
			_mesh.box(Vector3(0.24, 0.26, reach * 0.5), Vector3(console_x, base_y - 0.51, 0.5 * reach * 0.5), stone)

	# Garde-corps : un panneau de face et deux retours. Ce sont des rectangles instanciés ; le
	# shader de ferronnerie y dessine le fer et découpe le vide. De près, il porte son ombre de
	# dentelle ; à mi-distance, il n'en porte plus ; de loin, il n'est plus dessiné.
	var height: float = 1.0
	var front: Vector2 = Vector2(width - 0.12, height)
	var front_z: float = reach - 0.05
	var back: Vector2 = Vector2(front_z - 0.02, height)
	for zone: int in [MeshBuilder.ZONE_NEAR, MeshBuilder.ZONE_MID]:
		_mesh.set_zones(zone, zone == MeshBuilder.ZONE_NEAR)
		_mesh.panel(front, Transform3D(Basis.IDENTITY, Vector3(0.0, base_y + 0.5 * height, front_z)), _materials.railing)
		# Les retours sont tournés d'un quart de tour : leur repère regarde vers le côté.
		for side: float in [-1.0, 1.0]:
			var frame: Transform3D = Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(side * 0.5 * front.x, base_y + 0.5 * height, 0.02 + 0.5 * back.x))
			_mesh.panel(back, frame, _materials.railing)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 7-12

	# Garde-corps : un panneau de face et deux retours. Ce sont des rectangles instanciés ; le
	# shader de ferronnerie y dessine le fer et découpe le vide.
	var height: float = 1.0
	var front: Vector2 = Vector2(width - 0.12, height)
	var front_z: float = reach - 0.05
	_mesh.panel(front, Transform3D(Basis.IDENTITY, Vector3(0.0, base_y + 0.5 * height, front_z)), _materials.railing)
	# Les retours sont tournés d'un quart de tour : leur repère regarde vers le côté.
	var back: Vector2 = Vector2(front_z - 0.02, height)
	for side: float in [-1.0, 1.0]:
		var frame: Transform3D = Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(side * 0.5 * front.x, base_y + 0.5 * height, 0.02 + 0.5 * back.x))
		_mesh.panel(back, frame, _materials.railing)
#@ 8+


## Chaînes d'angle : une bande de pierre à refends à chaque bout de la façade.
func _build_quoins(from_y: float, to_y: float) -> void:
	var strip: float = minf(0.44, 0.5 * (bay_width - window_width) - 0.2)
	if strip < 0.2 or to_y - from_y < 1.0:
		return
	for side: float in [-1.0, 1.0]:
		_mesh.box(Vector3(strip, to_y - from_y, 0.04), Vector3(side * 0.5 * (get_facade_width() - strip), 0.5 * (from_y + to_y), 0.02), _materials.stone_base)
#@ 6+


## Corniche de couronnement, en haut de la façade.
func _build_cornice(base_y: float) -> void:
	var width: float = get_facade_width()
	var stone: ShaderMaterial = _materials.stone
	# Le mur monte derrière la corniche, jusqu'en haut de la façade.
	_wall(Vector3(width, CORNICE_HEIGHT, WALL_DEPTH), Vector3(0.0, base_y + 0.5 * CORNICE_HEIGHT, -0.5 * WALL_DEPTH), stone)
#@ 6-7
	# Deux boîtes en encorbellement : la seconde avance plus que la première.
	_mesh.box(Vector3(width, 0.24, 0.28), Vector3(0.0, base_y + 0.12, 0.14), stone)
	_mesh.box(Vector3(width + 0.1, 0.26, 0.55), Vector3(0.0, base_y + 0.37, 0.275), stone)
#@ 8-12
	if ornament < ORNAMENT_MOULDED:
		# Sans moulure : deux boîtes en encorbellement.
		_mesh.box(Vector3(width, 0.24, 0.28), Vector3(0.0, base_y + 0.12, 0.14), stone)
		_mesh.box(Vector3(width + 0.1, 0.26, 0.55), Vector3(0.0, base_y + 0.37, 0.275), stone)
		return

	# Avec moulure : le profil de corniche, extrudé sur toute la largeur.
	_mesh.extrude(Profiles.cornice(CORNICE_HEIGHT, CORNICE_DEPTH), MeshBuilder.along_x(Vector3(0.0, base_y, 0.0)), width + 0.1, stone)
	# Denticules : de petits cubes régulièrement espacés sur la bande plate du profil.
	var band_z: float = 0.26 * CORNICE_DEPTH
	var dentils: int = maxi(int(width / 0.17), 1)
	for index: int in range(dentils):
		var x: float = (float(index) + 0.5) * (width / float(dentils)) - 0.5 * width
		_mesh.box(Vector3(0.085, 0.1, 0.06), Vector3(x, base_y + 0.32 * CORNICE_HEIGHT, band_z + 0.03), stone)
	if ornament >= ORNAMENT_RICH:
		# Modillons : de petites consoles sous le larmier.
		var count: int = maxi(int(width / 0.62), 1)
		for index: int in range(count):
			var x: float = (float(index) + 0.5) * (width / float(count)) - 0.5 * width
			_mesh.extrude(Profiles.console(0.19, 0.24), MeshBuilder.along_x(Vector3(x, base_y + 0.03, band_z - 0.02)), 0.14, stone)
#@ 13+
	if ornament < ORNAMENT_MOULDED:
		# Sans moulure : deux boîtes en encorbellement, à toute distance.
		_mesh.box(Vector3(width, 0.24, 0.28), Vector3(0.0, base_y + 0.12, 0.14), stone)
		_mesh.box(Vector3(width + 0.1, 0.26, 0.55), Vector3(0.0, base_y + 0.37, 0.275), stone)
		return

	# De près : le profil de corniche, extrudé sur toute la largeur. Il porte une ombre.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR)
	_mesh.extrude(Profiles.cornice(CORNICE_HEIGHT, CORNICE_DEPTH), MeshBuilder.along_x(Vector3(0.0, base_y, 0.0)), width + 0.1, stone)
	# Denticules et modillons : des centaines de petites pièces. De près seulement, et sans
	# ombre portée : c'est là que les niveaux de détail font gagner le plus de triangles.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
	var band_z: float = 0.26 * CORNICE_DEPTH
	var dentils: int = maxi(int(width / 0.17), 1)
	for index: int in range(dentils):
		var x: float = (float(index) + 0.5) * (width / float(dentils)) - 0.5 * width
		_mesh.box(Vector3(0.085, 0.1, 0.06), Vector3(x, base_y + 0.32 * CORNICE_HEIGHT, band_z + 0.03), stone)
	if ornament >= ORNAMENT_RICH:
		# Modillons : de petites consoles sous le larmier.
		var count: int = maxi(int(width / 0.62), 1)
		for index: int in range(count):
			var x: float = (float(index) + 0.5) * (width / float(count)) - 0.5 * width
			_mesh.extrude(Profiles.console(0.19, 0.24), MeshBuilder.along_x(Vector3(x, base_y + 0.03, band_z - 0.02)), 0.14, stone)
	# Au-delà : les deux boîtes de la corniche nue. Même silhouette, même ombre, 24 triangles.
	_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
	_mesh.box(Vector3(width, 0.24, 0.28), Vector3(0.0, base_y + 0.12, 0.14), stone)
	_mesh.box(Vector3(width + 0.1, 0.26, 0.55), Vector3(0.0, base_y + 0.37, 0.275), stone)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
