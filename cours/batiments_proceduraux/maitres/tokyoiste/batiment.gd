@tool
extends Node3D
## Immeuble tokyoïte, monté par le code à partir des variables ci-dessous.
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
##   - des niveaux différents : un rez-de-chaussée haut, des bureaux, des logements, une
##     travée d'escalier, un acrotère ;
#@ 7+ quiet
##   - des balcons en creux aux étages de logements, leurs garde-corps, leurs climatiseurs ;
#@ 8+ quiet
##   - des pièces de métal plié : auvent, couvertine, appuis ; et des descentes d'eau ;
#@ 9+ quiet
##   - un toit-terrasse équipé, et des étages qui reculent pour rester sous le gabarit oblique ;
#@ 10+ quiet
##   - une devanture, son rideau métallique, des enseignes, un distributeur de boissons.
#@ 13+ quiet
## Chaque pièce n'est dessinée qu'aux distances où elle se voit : les détails de près, leur
## version simplifiée au-delà. Voir « Niveaux de détail » dans les variables, et set_zones().
#@ all
##
## Comment il est organisé :
##   - ce script décide de la composition : combien de niveaux, quelle baie où ;
##   - « _materiaux » fabrique les matériaux ;
#@ 8+ quiet
##   - « _profils » dessine la section des pièces de métal ;
#@ 9+ quiet
##   - « _toit » pose ce qu'il y a sur le toit ;
#@ 10+ quiet
##   - « _devanture » et « _enseignes » posent chacun leurs objets ;
#@ all
##   - MeshBuilder (dans 1_core) transforme le tout en maillages, un par matériau.
##
## Repère de l'immeuble : la façade est dans le plan z = 0 et regarde vers +Z (la rue), elle
## est centrée sur x = 0, le sol est à y = 0, l'immeuble s'enfonce vers -Z. Unité : le mètre.
#@ 10+ quiet
##
## Limites : pas d'angle de rue, pas de façade arrière, un seul gabarit (celui de la voie).
## Les cotes sont plausibles, elles ne sont pas relevées sur un immeuble réel.
#@ all

## L'outil commun de maillage : les fonctions _add_quad et _add_box de l'étape 001 y sont rangées.
const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
## Les matériaux de l'immeuble. « preload » charge le script une fois, à la lecture de celui-ci.
const Materials := preload("{MESH}_materiaux.gd")
#@ 8+
const Profiles := preload("{MESH}_profils.gd")
#@ 9+
const RoofBuilder := preload("{MESH}_toit.gd")
## Les nombres des règlements sont des données : ils vivent dans « 5_data ».
const Palette := preload("{DATA}_palette.gd")
#@ 10+
const ShopBuilder := preload("{MESH}_devanture.gd")
const SignBuilder := preload("{MESH}_enseignes.gd")
#@ all

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Épaisseur du mur de façade : un voile de béton, bien plus mince qu'un mur de pierre.
const WALL_DEPTH: float = 0.25
#@ 4+
## Retrait des fenêtres par rapport au nu du mur.
const WINDOW_RECESS: float = 0.1
#@ all
## Les morceaux de mur voisins se recouvrent de quelques millimètres : posés bord à bord, ils
## laisseraient passer un liseré de lumière à leur jonction.
const WALL_OVERLAP: float = 0.006
#@ 6+
## Ce qu'il y a derrière les fenêtres d'un niveau. Le shader de fenêtre connaît les mêmes nombres.
const KIND_OFFICE: int = 0
const KIND_DWELLING: int = 1
const KIND_CORE: int = 2
## Baie de la travée d'escalier : petite et haut placée.
const CORE_OPENING: Vector2 = Vector2(0.7, 1.0)
const CORE_SILL: float = 1.3
## Épaisseur de l'acrotère, le muret qui borde le toit.
const PARAPET_DEPTH: float = 0.2
#@ 7+
## Hauteur des garde-corps. Le règlement d'application de la loi japonaise sur les normes de
## construction (art. 126) demande 1,10 m au moins autour d'un toit-terrasse d'évacuation ;
## le cours prend la même hauteur pour les balcons.
const GUARD_HEIGHT: float = 1.1
## Épaisseur de la dalle d'un balcon, hauteur de la poutre qui le ferme en haut, largeur des
## murs d'aile qui le ferment sur les côtés.
const SLAB_THICKNESS: float = 0.12
const BEAM_HEIGHT: float = 0.25
const WING_WIDTH: float = 0.18
## Motifs du shader de garde-corps.
const MOTIF_BARS: float = 0.0
const MOTIF_PANELS: float = 1.0
const MOTIF_FAN_GRILLE: float = 2.0
## Formes de garde-corps de balcon.
const RAILING_BARS: int = 1
const RAILING_WALL: int = 2
const RAILING_PANELS: int = 3
#@ 8+
## Hauteur du bandeau de mur au-dessus des ouvertures du rez-de-chaussée : l'auvent s'y accroche.
const LINTEL_HEIGHT: float = 0.8
#@ all

@export_group("Plan")
## Nombre de travées : une fenêtre par travée et par niveau.
@export_range(1, 8, 1) var bay_count: int = 3
## Largeur d'une travée.
@export_range(1.6, 4.0, 0.05, "suffix:m") var bay_width: float = 2.2
## Profondeur de l'immeuble, de la façade au mur du fond.
@export_range(6.0, 25.0, 0.5, "suffix:m") var depth: float = 12.0

@export_group("Niveaux")
#@ 2-5
## Nombre de niveaux, rez-de-chaussée compris. Ils sont tous pareils jusqu'à l'étape 006.
@export_range(1, 12, 1) var floor_count: int = 6
## Hauteur d'un niveau, de plancher à plancher.
@export_range(2.6, 4.5, 0.05, "suffix:m") var floor_height: float = 3.1

@export_group("Baies")
## Largeur et hauteur du trou laissé dans le mur. Elles sont rabotées si la case est trop petite.
@export_range(0.8, 3.5, 0.05, "suffix:m") var window_width: float = 1.8
@export_range(0.6, 3.5, 0.05, "suffix:m") var window_height: float = 1.3
## Hauteur de l'allège : le morceau de mur sous la fenêtre. 0 : porte-fenêtre.
@export_range(0.0, 1.5, 0.05, "suffix:m") var sill_height: float = 0.9
#@ 6+
## Hauteur du rez-de-chaussée, de plancher à plancher.
@export_range(3.3, 5.0, 0.05, "suffix:m") var ground_height: float = 3.6
## Nombre d'étages au-dessus du rez-de-chaussée.
@export_range(1, 12, 1) var floor_count: int = 5
@export_range(2.6, 4.0, 0.05, "suffix:m") var floor_height: float = 3.0
## Nombre d'étages de bureaux, comptés à partir du premier. Les étages au-dessus sont des
## logements. 0 : que des logements ; autant que d'étages : que des bureaux.
@export_range(0, 12, 1) var office_floors: int = 2
#@ 6-10
## Travée de l'escalier : petites fenêtres dépolies, et la porte de l'immeuble en bas.
@export_enum("Aucune", "À gauche", "À droite") var core_side: int = 1
#@ 11+
## Travée de l'escalier : petites fenêtres dépolies, et la porte de l'immeuble en bas.
@export_enum("Selon la graine", "Aucune", "À gauche", "À droite") var core_side: int = 0
#@ 6+
## Hauteur de l'acrotère, le muret qui borde le toit.
@export_range(0.3, 1.2, 0.05, "suffix:m") var parapet_height: float = 0.6

@export_group("Façade")
## Hauteur des fenêtres de bureau : elles forment un bandeau presque continu.
@export_range(0.9, 2.2, 0.05, "suffix:m") var office_window_height: float = 1.5
#@ 7+
## Profondeur des balcons des logements. Ils sont en creux : le mur des fenêtres recule, le
## garde-corps reste au nu de la façade. 0 : pas de balcon, de simples fenêtres.
@export_range(0.0, 1.8, 0.05, "suffix:m") var balcony_depth: float = 1.0
#@ 7-10
## Garde-corps des balcons.
@export_enum("Barreaux", "Muret plein", "Panneaux translucides") var railing_style: int = 0
#@ 11+
## Garde-corps des balcons.
@export_enum("Selon la graine", "Barreaux", "Muret plein", "Panneaux translucides") var railing_style: int = 0
#@ 7+
## Un climatiseur sur chaque balcon.
@export var ac_units: bool = true
#@ 8+
## Avancée de l'auvent au-dessus du rez-de-chaussée. 0 : pas d'auvent. Un mètre au plus : c'est
## la saillie permise au-dessus d'une route nationale à Tokyo.
@export_range(0.0, 1.0, 0.05, "suffix:m") var canopy_depth: float = 0.9
## Descentes d'eau de pluie sur la façade.
@export var downpipes: bool = true
#@ 9+

@export_group("Toit")
## Édicule de l'escalier, qui dépasse du toit.
@export var penthouse: bool = true
## Réservoir d'eau.
@export var water_tank: bool = true
## Nombre de climatiseurs sur le toit : ceux des bureaux.
@export_range(0, 6, 1) var roof_units: int = 3

@export_group("Gabarit")
## Largeur de la voie devant l'immeuble. Une ligne part de son bord opposé et monte en
## oblique : les étages qui la dépasseraient reculent. 0 : pas de gabarit.
@export_range(0.0, 40.0, 0.5, "suffix:m") var road_width: float = 11.0
## Pente de cette ligne. Elle dépend de la zone d'urbanisme.
@export_enum("Zone d'habitation (1.25)", "Autres zones (1.5)") var slope_zone: int = 1
#@ 10+

@export_group("Rez-de-chaussée")
## Une boutique ; sinon, un rez-de-chaussée de bureaux.
@export var shop: bool = true
#@ 10
## Rideau métallique de la boutique.
@export_enum("Levé", "À moitié baissé", "Baissé") var shutter: int = 0
#@ 11+
## Rideau métallique de la boutique.
@export_enum("Selon la graine", "Levé", "À moitié baissé", "Baissé") var shutter: int = 1
#@ 10+
## Distributeur de boissons près de l'entrée.
@export var vending_machine: bool = true

@export_group("Enseignes")
## Enseigne au-dessus de la boutique.
@export var fascia_sign: bool = true
## Enseigne en drapeau, avec une plaque par étage.
@export var projecting_sign: bool = true
## Panneau publicitaire sur le toit.
@export var roof_sign: bool = false
## Vrai : enseignes en japonais. Faux : en lettres latines, pour une machine qui n'a aucune
## police japonaise (les enseignes y afficheraient des carrés).
@export var japanese_signs: bool = true
#@ all

@export_group("Aspect")
#@ 2
## Teinte du carrelage. Le script la donne aux matériaux, qui la donnent au shader.
@export var tile_color: Color = Color(0.80, 0.78, 0.72)
#@ 3-10
## Teinte du carrelage, du blanc au brun.
@export var tile_color: Color = Color(0.80, 0.78, 0.72)
#@ 11+
## Revêtement de la façade sur rue.
@export_enum("Selon la graine", "Carrelage", "Béton brut", "Enduit peint") var cladding: int = 1
## Format des carreaux : long à joints croisés, court à joints croisés, petit à joints alignés,
## mosaïque carrée.
@export_enum("Selon la graine", "Long (227 × 60)", "Court (108 × 60)", "Petit (95 × 45)", "Mosaïque (45 × 45)") var tile_format: int = 1
## Teinte du revêtement : carrelage ou peinture. Le béton brut garde son gris.
@export var tile_color: Color = Color(0.80, 0.78, 0.72)
#@ 3+
## Encrassement des murs, de 0 (lavés) à 1 (très sales).
@export_range(0.0, 1.0, 0.01) var grime: float = 0.3
#@ 4+
## Teinte de l'aluminium des menuiseries.
@export var frame_color: Color = Color(0.62, 0.63, 0.64)
#@ 11+
## Change tous les tirages : pièces, taches, formes laissées « Selon la graine », boutique.
@export var variation_seed: int = 0
#@ 13+

@export_group("Niveaux de détail")
## Jusqu'à cette distance, l'immeuble est dessiné en entier. Au-delà, les pièces de métal
## redeviennent des boîtes et les petits objets disparaissent. La distance est comptée de la
## caméra au centre de l'immeuble. 0 pour les deux distances : pas de niveaux de détail.
@export_range(0.0, 150.0, 1.0, "suffix:m") var near_distance: float = 30.0
## Au-delà de cette distance, il ne reste que les murs, les fenêtres, les balcons et les
## caissons d'enseigne.
@export_range(0.0, 400.0, 1.0, "suffix:m") var far_distance: float = 90.0
#@ 6+


## Un niveau de la façade, tel que le décrivent les variables. « _make_levels() » en fait la
## liste, du rez-de-chaussée au dernier étage ; « _build_level() » les monte un par un.
class Level:
	var height: float = 3.0
	## Ce qu'il y a derrière ses fenêtres : KIND_OFFICE ou KIND_DWELLING.
	var kind: int = 0
	## Largeur et hauteur de la baie.
	var opening: Vector2 = Vector2(1.6, 1.5)
	## Hauteur de l'allège sous la baie.
	var sill: float = 0.85
#@ 7+
	## Profondeur du balcon en creux : le mur des fenêtres recule d'autant. 0 : pas de balcon.
	var recess: float = 0.0
#@ 9+
	## Recul de tout le niveau par rapport à l'alignement, pour rester sous le gabarit oblique.
	var setback: float = 0.0
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
#@ 9+
## Recul du niveau qu'on est en train de monter : _wall(), _box() et _panel() l'appliquent.
var _setback: float = 0.0
#@ 10+
## Le dé de l'immeuble. Sa graine est fixée au début de chaque construction.
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
#@ 11+
## Les choix laissés « Selon la graine », une fois tirés.
var _core_choice: int = 2
var _railing_choice: int = RAILING_BARS
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
#@ 9+


## Marge sous le gabarit oblique, en mètres : la plus petite distance verticale entre un mur
## plein de l'immeuble et la ligne du gabarit. Négative : l'immeuble la perce. Le test de
## l'étape et celui de la rue s'en servent. Sans gabarit (road_width à 0), elle est infinie.
func get_slope_margin() -> float:
	if road_width <= 0.0:
		return INF
	var slope: float = Palette.ROAD_SLOPES[slope_zone]
	var levels: Array[Level] = _make_levels()
	var margin: float = INF
	var top_y: float = 0.0
	for index: int in range(levels.size()):
		top_y += levels[index].height
		# L'acrotère est un mur plein : il compte dans la hauteur du dernier niveau.
		var solid_top: float = top_y + (parapet_height if index == levels.size() - 1 else 0.0)
		margin = minf(margin, slope * (road_width + levels[index].setback) - solid_top)
	return margin


## Nombre de niveaux réellement montés, rez-de-chaussée compris : sous un gabarit serré, les
## derniers étages demandés n'ont plus la place et ne sont pas construits.
func get_built_level_count() -> int:
	return _make_levels().size()
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
	# La boutique tire au sort son nom et ses teintes. Le dé repart toujours de la même
	# graine : l'immeuble est le même à chaque construction. L'étape 011 rendra cette graine
	# réglable.
	_random.seed = 0
	# Dans la liste de l'inspecteur, les états du rideau sont numérotés à partir de 0 ; le
	# script de la devanture les numérote à partir de 1.
	var shutter_choice: int = shutter + 1

#@ 11+
	# Les tirages. Ils se font toujours dans le même ordre, à partir de la même graine : une
	# graine donne donc toujours le même immeuble.
	_random.seed = hash(variation_seed)
	_core_choice = _pick(core_side, 3)
	_railing_choice = _pick(railing_style, 3)
	var shutter_choice: int = _pick(shutter, 3)
	var cladding_choice: int = _pick(cladding, 3)
	var format_choice: int = _pick(tile_format, Palette.TILE_FORMATS.size())
	# Deux façades sur trois sont carrelées : quand la graine choisit, on penche le dé. Le dé
	# est lancé même si le revêtement est imposé, pour ne pas décaler les tirages suivants.
	var favour_tile: bool = _random.randf() < 0.5
	if cladding == 0 and favour_tile:
		cladding_choice = 1

#@ all
	# Les matériaux d'abord : chaque forme donnée à l'outil de maillage est rangée d'après son
	# matériau. On règle, puis on fabrique.
	_materials = Materials.new()
	_materials.tile_color = tile_color
#@ 3+
	_materials.grime = grime
#@ 4+
	_materials.frame_color = frame_color
#@ 5
	_materials.sill_height = sill_height
#@ 11+
	# Dans le script des matériaux, les revêtements sont numérotés à partir de 0.
	_materials.cladding = cladding_choice - 1
	_materials.tile_size = Palette.TILE_FORMATS[format_choice - 1][0]
	_materials.tile_stagger = Palette.TILE_FORMATS[format_choice - 1][1]
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
			Vector3(0.0, 0.5 * height, -0.5 * (depth + WALL_DEPTH)), _materials.side)
#@ 6+
	# La façade, niveau par niveau. « base_y » monte d'un niveau à chaque tour.
	var levels: Array[Level] = _make_levels()
	var base_y: float = 0.0
#@ 9+
	# Recul du niveau du dessous, et hauteur où finit la partie de la façade restée à
	# l'alignement : les descentes d'eau s'arrêtent là.
	var previous_setback: float = 0.0
	var flush_top: float = 0.0
#@ 6+
	for index: int in range(levels.size()):
#@ 9+
		# Un niveau qui recule plus que celui du dessous laisse une terrasse devant lui.
		if levels[index].setback > previous_setback:
			_build_terrace(base_y, previous_setback, levels[index].setback)
		previous_setback = levels[index].setback
#@ 6-9
		base_y = _build_level(levels[index], index, base_y)
#@ 10+
		if index == 0 and shop:
			base_y = _build_shop_level(levels[index], shutter_choice)
		else:
			base_y = _build_level(levels[index], index, base_y)
#@ 9+
		if levels[index].setback <= 0.0:
			flush_top = base_y
#@ 6+
	_build_parapet(base_y)
#@ 8
	_build_canopy()
	if downpipes:
		_build_downpipes(base_y)
#@ 9+
	_build_canopy()
	if downpipes:
		_build_downpipes(flush_top)

	# Le toit, posé sur le dernier niveau. Il reçoit l'abscisse de la travée d'escalier, pour y
	# dresser l'édicule.
	var top_setback: float = levels[levels.size() - 1].setback
	var core: int = _core_bay()
	var core_x: float = _bay_center(core) if core >= 0 else _bay_center(bay_count - 1)
#@ 9-10
	RoofBuilder.build(_mesh, _materials, get_facade_width(), depth, base_y, top_setback, parapet_height,
			core_x, minf(bay_width, 2.6), penthouse, water_tank, roof_units, 0)
#@ 11+
	# La graine choisit la forme du réservoir : cylindre ou cuve à panneaux.
	RoofBuilder.build(_mesh, _materials, get_facade_width(), depth, base_y, top_setback, parapet_height,
			core_x, minf(bay_width, 2.6), penthouse, water_tank, roof_units, _random.randi_range(0, 1))
#@ 10+

	# Les enseignes qui tiennent à l'immeuble entier : le drapeau, puis le panneau du toit.
	if projecting_sign and levels.size() >= 2:
		var side: float = -1.0 if core == bay_count - 1 else 1.0
		SignBuilder.projecting(_mesh, _materials, _random, side * 0.5 * get_facade_width(), levels[0].height + 0.4,
				_floor_tops(levels, 1), japanese_signs)
	if roof_sign:
		SignBuilder.rooftop(_mesh, _materials, _random, get_facade_width(), base_y + parapet_height, top_setback, japanese_signs)
#@ 6

	# Le volume arrière : une boîte nue derrière la façade, jusqu'en haut de l'acrotère.
	_mesh.box(Vector3(get_facade_width(), base_y + parapet_height, depth - WALL_DEPTH),
			Vector3(0.0, 0.5 * (base_y + parapet_height), -0.5 * (depth + WALL_DEPTH)), _materials.side)
#@ 7-8

	# Le toit, en attendant l'étape 009 : un bloc plein derrière l'acrotère.
	_mesh.box(Vector3(get_facade_width(), parapet_height, depth - PARAPET_DEPTH),
			Vector3(0.0, base_y + 0.5 * parapet_height, -0.5 * (depth + PARAPET_DEPTH)), _materials.side)
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


## Numéro de la travée d'escalier, compté à partir de zéro. -1 : il n'y en a pas. Un immeuble
## d'une seule travée n'en a pas : sa porte est dans la boutique.
func _core_bay() -> int:
#@ 6-10
	if bay_count < 2 or core_side == 0:
		return -1
	return 0 if core_side == 1 else bay_count - 1
#@ 11+
	# _core_choice : 1 aucune, 2 à gauche, 3 à droite.
	if bay_count < 2 or _core_choice == 1:
		return -1
	return 0 if _core_choice == 2 else bay_count - 1
#@ 6+


## Traduit les variables en une liste de niveaux, du rez-de-chaussée au dernier étage.
func _make_levels() -> Array[Level]:
	var levels: Array[Level] = []

	# Rez-de-chaussée : de grandes baies vitrées, presque de plain-pied.
	var ground: Level = Level.new()
	ground.height = ground_height
	ground.kind = KIND_OFFICE
	ground.sill = 0.3
	ground.opening = Vector2(bay_width - 0.4, ground_height - 1.2)
	levels.append(ground)

	for index: int in range(floor_count):
		var level: Level = Level.new()
		level.height = floor_height
		if index < office_floors:
			# Bureaux : des fenêtres larges au-dessus d'une allège, qui forment un bandeau.
			level.kind = KIND_OFFICE
			level.sill = 0.85
			level.opening = Vector2(bay_width - 0.4, office_window_height)
		else:
			# Logements : des fenêtres plus étroites.
			level.kind = KIND_DWELLING
			level.sill = 0.9
			level.opening = Vector2(bay_width - 0.7, 1.2)
#@ 7+
			if balcony_depth > 0.0:
				# Avec un balcon : une porte-fenêtre, et le mur recule de la profondeur du balcon.
				level.recess = balcony_depth
				level.sill = SLAB_THICKNESS
				level.opening = Vector2(bay_width - 0.5, 2.0)
#@ 6+
		levels.append(level)
#@ 9+

	# Le gabarit oblique. On essaie de garder tous les niveaux ; si le dernier n'a plus assez
	# de profondeur une fois reculé, on l'enlève et on recommence.
	var count: int = levels.size()
	while count > 1 and not _fit_setbacks(levels, count):
		count -= 1
	levels.resize(count)
#@ 6+
	return levels
#@ 9+


## Donne son recul à chacun des « count » premiers niveaux, pour que son arête haute reste
## sous le gabarit oblique. Renvoie faux si l'un d'eux n'a plus la profondeur minimale.
func _fit_setbacks(levels: Array[Level], count: int) -> bool:
	var slope: float = Palette.ROAD_SLOPES[slope_zone]
	var top_y: float = 0.0
	var setback: float = 0.0
	for index: int in range(count):
		top_y += levels[index].height
		# L'acrotère est un mur plein : il compte dans la hauteur du dernier niveau.
		var solid_top: float = top_y + (parapet_height if index == count - 1 else 0.0)
		# La ligne du gabarit part du bord opposé de la voie : à la distance « d » de ce bord,
		# elle est à la hauteur slope × d. Il faut donc reculer de solid_top / slope, moins la
		# largeur de la voie.
		var needed: float = solid_top / slope - road_width if road_width > 0.0 else 0.0
		if needed > 0.0 and index > 0:
			# On recule par demi-mètres, et jamais de moins d'un mètre. Un niveau ne peut pas
			# avancer au-dessus de celui du dessous.
			setback = maxf(setback, maxf(ceilf(needed / 0.5) * 0.5, Palette.MIN_SETBACK))
		levels[index].setback = setback
#@ 9+
		# Un niveau en retrait a sa terrasse : il n'a pas besoin d'un balcon en creux.
		if setback > 0.0 and levels[index].recess > 0.0 and (index == 0 or levels[index - 1].setback < setback):
			levels[index].recess = 0.0
			levels[index].sill = 0.05
		if depth - setback - levels[index].recess < Palette.MIN_FLOOR_DEPTH:
			return false
	return true
#@ 10+


## Hauteur du plancher haut de chaque niveau à partir du niveau « first ».
func _floor_tops(levels: Array[Level], first: int) -> PackedFloat32Array:
	var tops: PackedFloat32Array = PackedFloat32Array()
	var top_y: float = 0.0
	for index: int in range(levels.size()):
		top_y += levels[index].height
		# L'enseigne en drapeau ne monte pas sur les étages en retrait.
		if index >= first and levels[index].setback <= 0.0:
			tops.append(top_y)
	return tops
#@ all


# --- Façade -----------------------------------------------------------------

## Abscisse du milieu d'une travée, la façade étant centrée sur x = 0.
func _bay_center(bay: int) -> float:
	return (float(bay) - 0.5 * float(bay_count - 1)) * bay_width


## Morceau de mur : une boîte, élargie du recouvrement.
func _wall(size: Vector3, center: Vector3, material: Material) -> void:
#@ 2-8
	_mesh.box(size + Vector3(WALL_OVERLAP, WALL_OVERLAP, 0.0), center, material)
#@ 9+
	_mesh.box(size + Vector3(WALL_OVERLAP, WALL_OVERLAP, 0.0), _at(center), material)
#@ 7+


## Boîte ordinaire, sans recouvrement : dalle, poutre, climatiseur.
func _box(size: Vector3, center: Vector3, material: Material) -> void:
#@ 7-8
	_mesh.box(size, center, material)
#@ 9+
	_mesh.box(size, _at(center), material)
#@ 6+


## Rectangle instancié, tourné vers la rue. « custom » arrive au shader par INSTANCE_CUSTOM.
func _panel(size: Vector2, center: Vector3, material: Material, custom: Color = Color(0.0, 0.0, 0.0, 0.0)) -> void:
#@ 6-8
	_mesh.panel(size, Transform3D(Basis.IDENTITY, center), material, custom)
#@ 9+
	_mesh.panel(size, Transform3D(Basis.IDENTITY, _at(center)), material, custom)


## Un point du niveau qu'on est en train de monter, une fois ce niveau reculé de son retrait.
func _at(point: Vector3) -> Vector3:
	return point + Vector3(0.0, 0.0, -_setback)
#@ all


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
				Vector3(x - 0.5 * bay_width + 0.5 * pier, base_y + 0.5 * floor_height, wall_z), _materials.facade)
		_wall(Vector3(pier, floor_height, WALL_DEPTH),
				Vector3(x + 0.5 * bay_width - 0.5 * pier, base_y + 0.5 * floor_height, wall_z), _materials.facade)
		# Allège : le mur sous la baie.
		if sill_height > 0.001:
			_wall(Vector3(opening.x, sill_height, WALL_DEPTH),
					Vector3(x, base_y + 0.5 * sill_height, wall_z), _materials.facade)
		# Linteau : le mur au-dessus de la baie.
		_wall(Vector3(opening.x, lintel, WALL_DEPTH),
				Vector3(x, base_y + floor_height - 0.5 * lintel, wall_z), _materials.facade)
#@ 4-5
		# La fenêtre : un rectangle instancié, de la taille de la baie, en retrait du mur. Le
		# script ne pose que ce rectangle ; tout le reste (menuiserie, vitrage) est dessiné par
		# son shader. Le repère dit où est son centre et vers où il regarde : ici +Z, la rue.
		var center: Vector3 = Vector3(x, base_y + sill_height + 0.5 * opening.y, -WINDOW_RECESS)
		_mesh.panel(opening, Transform3D(Basis.IDENTITY, center), _materials.window)
#@ 6+
## Monte un niveau posé à la hauteur « base_y » et renvoie la hauteur de son plancher haut.
func _build_level(level: Level, index: int, base_y: float) -> float:
	var top_y: float = base_y + level.height
	var core: int = _core_bay()
#@ 9+
	# Tout ce que ce niveau va poser recule de son retrait : voir _at().
	_setback = level.setback
#@ 6+

	for bay: int in range(bay_count):
		var x: float = _bay_center(bay)
#@ 10+
		if index == 0 and bay == core:
			# Rez-de-chaussée sans boutique : la porte de l'immeuble prend la place de la baie.
			_wall(Vector3(bay_width, LINTEL_HEIGHT, WALL_DEPTH), Vector3(x, top_y - 0.5 * LINTEL_HEIGHT, -0.5 * WALL_DEPTH), _materials.facade)
			_build_entrance(x - 0.5 * bay_width, x + 0.5 * bay_width, top_y - LINTEL_HEIGHT, 1.0 if core == 0 else -1.0)
			continue
#@ 6+
		# La travée de l'escalier a sa propre baie, petite et haute.
		var is_core: bool = bay == core and index > 0
		var size: Vector2 = CORE_OPENING if is_core else level.opening
		var sill: float = CORE_SILL if is_core else level.sill
		# Aucune baie ne peut être plus grande que sa case.
		size.x = minf(size.x, bay_width - 0.3)
		size.y = minf(size.y, level.height - sill - 0.2)
		var bottom: float = base_y + sill
		var pier: float = 0.5 * (bay_width - size.x)
#@ 6
		# Le mur est derrière le plan z = 0 : son milieu est à une demi-épaisseur en arrière.
		var wall_z: float = -0.5 * WALL_DEPTH
		var glass_z: float = -WINDOW_RECESS
#@ 7+
		# Le mur est derrière le plan z = 0. Aux étages à balcon, il recule encore de la
		# profondeur du balcon, sauf dans la travée de l'escalier, qui reste au nu de la façade.
		var recess: float = 0.0 if is_core else level.recess
		var wall_z: float = -recess - 0.5 * WALL_DEPTH
		var glass_z: float = -recess - WINDOW_RECESS
#@ 6+

		# On ne perce pas un mur : on pose du mur autour du trou. Trumeaux de part et d'autre
		# de la baie, allège dessous, linteau dessus.
		_wall(Vector3(pier, level.height, WALL_DEPTH), Vector3(x - 0.5 * bay_width + 0.5 * pier, base_y + 0.5 * level.height, wall_z), _materials.facade)
		_wall(Vector3(pier, level.height, WALL_DEPTH), Vector3(x + 0.5 * bay_width - 0.5 * pier, base_y + 0.5 * level.height, wall_z), _materials.facade)
		if sill > 0.001:
			_wall(Vector3(size.x, sill, WALL_DEPTH), Vector3(x, base_y + 0.5 * sill, wall_z), _materials.facade)
		var lintel: float = top_y - (bottom + size.y)
		_wall(Vector3(size.x, lintel, WALL_DEPTH), Vector3(x, top_y - 0.5 * lintel, wall_z), _materials.facade)

		# La fenêtre : un rectangle instancié, en retrait du mur ; son shader fait le reste. La
		# donnée de l'instance lui dit quelle pièce dessiner derrière la vitre, et la hauteur
		# de l'allège, pour qu'il place le sol de cette pièce.
		var kind: int = KIND_CORE if is_core else level.kind
#@ 13+
		# Elle est dessinée à toute distance, mais ne porte pas d'ombre : elle est au fond de sa
		# baie, son ombre ne tomberait sur rien.
		_mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ 6+
		_panel(size, Vector3(x, bottom + 0.5 * size.y, glass_z), _materials.window, Color(float(kind), sill, 0.0, 0.0))
#@ 8
		if sill > 0.3:
			# Appui d'aluminium sous la fenêtre : un profil de tôle pliée, extrudé sur sa largeur.
			_mesh.extrude(Profiles.sill(0.07), MeshBuilder.along_x(Vector3(x, bottom, wall_z + 0.5 * WALL_DEPTH)), size.x + 0.04, _materials.aluminium)
#@ 9-12
		if sill > 0.3:
			# Appui d'aluminium sous la fenêtre : un profil de tôle pliée, extrudé sur sa largeur.
			_mesh.extrude(Profiles.sill(0.07), MeshBuilder.along_x(_at(Vector3(x, bottom, wall_z + 0.5 * WALL_DEPTH))), size.x + 0.04, _materials.aluminium)
#@ 13+
		if sill > 0.3:
			# Appui d'aluminium sous la fenêtre : un profil de tôle pliée, extrudé sur sa largeur.
			# Un détail fin : de près seulement, et sans ombre portée.
			_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
			_mesh.extrude(Profiles.sill(0.07), MeshBuilder.along_x(_at(Vector3(x, bottom, wall_z + 0.5 * WALL_DEPTH))), size.x + 0.04, _materials.aluminium)
		# On revient toujours à la normale : la suite ne doit pas hériter d'une zone.
		_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 7+

	if level.recess > 0.0:
		_build_balcony(level, index, base_y)
	_build_back(level, base_y)
#@ 6+
	return top_y
#@ 7+


## Volume arrière d'un niveau : une boîte nue derrière son mur de façade. Aux étages à balcon,
## elle commence plus loin, et la travée de l'escalier reçoit la sienne.
func _build_back(level: Level, base_y: float) -> void:
	var width: float = get_facade_width()
	var front: float = level.recess + WALL_DEPTH
#@ 7-8
	var length: float = depth - front
#@ 9+
	var length: float = depth - _setback - front
#@ 7+
	_box(Vector3(width, level.height, length), Vector3(0.0, base_y + 0.5 * level.height, -front - 0.5 * length), _materials.side)
	var core: int = _core_bay()
	if level.recess > 0.0 and core >= 0:
		_box(Vector3(bay_width, level.height, level.recess), Vector3(_bay_center(core), base_y + 0.5 * level.height, -WALL_DEPTH - 0.5 * level.recess), _materials.side)


## Balcon en creux d'un étage de logements : une dalle, une poutre de rive, deux murs d'aile,
## un garde-corps au nu de la façade, un climatiseur.
func _build_balcony(level: Level, index: int, base_y: float) -> void:
	var width: float = get_facade_width()
	var core: int = _core_bay()
	var reach: float = level.recess
	var top_y: float = base_y + level.height
	# Le balcon court devant toutes les travées, sauf celle de l'escalier.
	var left: float = -0.5 * width + (bay_width if core == 0 else 0.0)
	var right: float = 0.5 * width - (bay_width if core == bay_count - 1 else 0.0)
	var span: float = right - left
	var middle: float = 0.5 * (left + right)
#@ 7-8
	var slab_material: Material = _materials.side
#@ 9+
	var slab_material: Material = _materials.concrete
#@ 7+

	# La dalle : le sol du balcon. Son nez dépasse de deux centimètres du nu de la façade.
	_box(Vector3(span, SLAB_THICKNESS, reach + 0.02), Vector3(middle, base_y + 0.5 * SLAB_THICKNESS, -0.5 * reach + 0.01), slab_material)
	# La poutre de rive : elle ferme le haut du balcon.
	_box(Vector3(span, BEAM_HEIGHT, 0.2), Vector3(middle, top_y - 0.5 * BEAM_HEIGHT, -0.1), _materials.facade)
	# Les murs d'aile : ils ferment les deux bouts.
	for side: float in [-1.0, 1.0]:
		var edge: float = left if side < 0.0 else right
		_box(Vector3(WING_WIDTH, level.height, reach), Vector3(edge - side * 0.5 * WING_WIDTH, base_y + 0.5 * level.height, -0.5 * reach), _materials.facade)

	# Le garde-corps, entre les deux murs d'aile, posé sur la dalle.
	var guard: Vector2 = Vector2(span - 2.0 * WING_WIDTH, GUARD_HEIGHT)
	var guard_y: float = base_y + SLAB_THICKNESS + 0.5 * GUARD_HEIGHT
#@ 7-10
	# Dans la liste de l'inspecteur, les formes sont numérotées à partir de 0.
	var style: int = railing_style + 1
#@ 11+
	var style: int = _railing_choice
#@ 7-12
	if style == RAILING_WALL:
		# Muret plein, du même revêtement que la façade, coiffé d'une lisse d'aluminium.
		_box(Vector3(guard.x, GUARD_HEIGHT, 0.12), Vector3(middle, guard_y, -0.06), _materials.facade)
		_box(Vector3(guard.x, 0.04, 0.16), Vector3(middle, guard_y + 0.5 * GUARD_HEIGHT + 0.02, -0.06), _materials.aluminium)
	else:
		# Barreaux ou panneaux : un rectangle instancié, et le shader fait le reste. La donnée
		# de l'instance lui dit quel motif dessiner.
		var motif: float = MOTIF_PANELS if style == RAILING_PANELS else MOTIF_BARS
		_panel(guard, Vector3(middle, guard_y, -0.04), _materials.railing, Color(motif, 0.0, 0.0, 0.0))
#@ 13+
	if style == RAILING_WALL:
		# Muret plein, du même revêtement que la façade, coiffé d'une lisse d'aluminium.
		_box(Vector3(guard.x, GUARD_HEIGHT, 0.12), Vector3(middle, guard_y, -0.06), _materials.facade)
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
		_box(Vector3(guard.x, 0.04, 0.16), Vector3(middle, guard_y + 0.5 * GUARD_HEIGHT + 0.02, -0.06), _materials.aluminium)
	elif style == RAILING_PANELS:
		# Panneaux translucides : un rectangle instancié, et le shader fait le reste. Un seul
		# rectangle : on le garde à toute distance.
		_mesh.set_zones(MeshBuilder.ZONE_ALL, false)
		_panel(guard, Vector3(middle, guard_y, -0.04), _materials.railing, Color(MOTIF_PANELS, 0.0, 0.0, 0.0))
	else:
		# Barreaux : de près, ils portent leur ombre ; à mi-distance, ils n'en portent plus ; de
		# loin, ils sont plus fins qu'un pixel et ne sont plus dessinés.
		for zone: int in [MeshBuilder.ZONE_NEAR, MeshBuilder.ZONE_MID]:
			_mesh.set_zones(zone, zone == MeshBuilder.ZONE_NEAR)
			_panel(guard, Vector3(middle, guard_y, -0.04), _materials.railing, Color(MOTIF_BARS, 0.0, 0.0, 0.0))
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 7+

	if ac_units:
		# Le climatiseur : une boîte posée sur la dalle, contre le mur, et sa grille ronde
		# dessinée par le shader sur un rectangle. Il change de bout d'un étage à l'autre.
		var unit: Vector3 = Vector3(0.78, 0.55, 0.29)
		var unit_side: float = 1.0 if index % 2 == 0 else -1.0
		var unit_x: float = middle + unit_side * (0.5 * span - WING_WIDTH - 0.6)
		var unit_center: Vector3 = Vector3(unit_x, base_y + SLAB_THICKNESS + 0.5 * unit.y, -reach + 0.5 * unit.z + 0.06)
#@ 13+
		# De loin, on ne le voit plus derrière le garde-corps.
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ 7+
		_box(unit, unit_center, _materials.appliance)
#@ 13+
		_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ 7+
		_panel(Vector2(unit.x, unit.y), unit_center + Vector3(0.0, 0.0, 0.5 * unit.z + 0.004), _materials.railing, Color(MOTIF_FAN_GRILLE, 0.0, 0.0, 0.0))
#@ 13+
		_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 11+

	# Un balcon sur quatre a un futon qui sèche sur son garde-corps. Les trois tirages se font
	# à chaque balcon, qu'il ait un futon ou non : le nombre de tirages ne dépend pas du hasard.
	var futon: bool = _random.randf() < 0.25
	var futon_x: float = middle + _random.randf_range(-0.25, 0.25) * span
	var futon_color: Color = Color(0.90, 0.89, 0.86).lerp(Color(0.62, 0.70, 0.80), _random.randf())
	if futon and style != RAILING_PANELS:
#@ 13+
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ 11+
		_box(Vector3(1.25, 0.8, 0.22), Vector3(futon_x, guard_y + 0.5 * GUARD_HEIGHT - 0.36, -0.05), _materials.lacquer(futon_color))
#@ 13+
		_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 9+


## Terrasse laissée par un niveau qui recule : un sol d'étanchéité et un garde-corps à
## barreaux, du recul « front » du niveau du dessous au recul « back » de celui-ci.
## Toujours des barreaux : un garde-corps ajouré n'est pas compté dans la hauteur du gabarit,
## un muret plein le serait (c'est la pratique de l'arrondissement de Nakano, voir la note
## de l'étape).
func _build_terrace(base_y: float, front: float, back: float) -> void:
	var width: float = get_facade_width()
	var length: float = back - front
	_mesh.box(Vector3(width, 0.04, length), Vector3(0.0, base_y + 0.02, -front - 0.5 * length), _materials.roofing)
#@ 13+
	# Le garde-corps : de près et à mi-distance, sans ombre portée.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ 9+
	var guard_y: float = base_y + 0.5 * GUARD_HEIGHT
	_mesh.panel(Vector2(width - 0.1, GUARD_HEIGHT), Transform3D(Basis.IDENTITY, Vector3(0.0, guard_y, -front - 0.05)), _materials.railing)
	# Les retours sont tournés d'un quart de tour : leur repère regarde vers le côté.
	for side: float in [-1.0, 1.0]:
		var frame: Transform3D = Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(side * (0.5 * width - 0.05), guard_y, -front - 0.05 - 0.5 * length))
		_mesh.panel(Vector2(length, GUARD_HEIGHT), frame, _materials.railing)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 6+


## Acrotère : le muret qui borde le toit, côté rue.
func _build_parapet(base_y: float) -> void:
	var width: float = get_facade_width()
	_wall(Vector3(width, parapet_height, PARAPET_DEPTH), Vector3(0.0, base_y + 0.5 * parapet_height, -0.5 * PARAPET_DEPTH), _materials.facade)
#@ 8
	# Couvertine : le chapeau de tôle de l'acrotère. Un profil, extrudé sur toute la largeur.
	_mesh.extrude(Profiles.coping(PARAPET_DEPTH, 0.03, 0.05), MeshBuilder.along_x(Vector3(0.0, base_y + parapet_height, 0.0)), width + 0.06, _materials.aluminium)
#@ 9-12
	# Couvertine : le chapeau de tôle de l'acrotère. Un profil, extrudé sur toute la largeur.
	_mesh.extrude(Profiles.coping(PARAPET_DEPTH, 0.03, 0.05), MeshBuilder.along_x(_at(Vector3(0.0, base_y + parapet_height, 0.0))), width + 0.06, _materials.aluminium)
#@ 13+
	# Couvertine : le chapeau de tôle de l'acrotère. De près, un profil extrudé sur toute la
	# largeur ; au-delà, une simple boîte de la même taille.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR)
	_mesh.extrude(Profiles.coping(PARAPET_DEPTH, 0.03, 0.05), MeshBuilder.along_x(_at(Vector3(0.0, base_y + parapet_height, 0.0))), width + 0.06, _materials.aluminium)
	_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
	_box(Vector3(width + 0.06, 0.07, PARAPET_DEPTH + 0.06), Vector3(0.0, base_y + parapet_height + 0.005, -0.5 * PARAPET_DEPTH), _materials.aluminium)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 8+


## Auvent au-dessus du rez-de-chaussée : un profil de tôle pliée, extrudé sur la largeur.
func _build_canopy() -> void:
	if canopy_depth <= 0.0:
		return
	var width: float = get_facade_width() - 0.1
	var y: float = ground_height - LINTEL_HEIGHT
#@ 8-12
	_mesh.extrude(Profiles.canopy(canopy_depth, 0.08), MeshBuilder.along_x(Vector3(0.0, y, 0.0)), width, _materials.aluminium)
#@ 13+
	# De près, le profil ; au-delà, une boîte : même silhouette, même ombre.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR)
	_mesh.extrude(Profiles.canopy(canopy_depth, 0.08), MeshBuilder.along_x(Vector3(0.0, y, 0.0)), width, _materials.aluminium)
	_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
	_mesh.box(Vector3(width, 0.1, canopy_depth), Vector3(0.0, y + 0.05, 0.5 * canopy_depth), _materials.aluminium)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 8+


## Descentes d'eau de pluie : un tuyau à chaque bout de la façade, de « top_y » au trottoir.
## Chacun a une boîte à eau en haut, des colliers, et un coude en bas, vers le caniveau.
func _build_downpipes(top_y: float) -> void:
	var radius: float = 0.045
	var elbow: float = 0.12
	# Le tuyau est devant le mur ; son coude commence à 30 cm du sol.
	var pipe_z: float = radius + 0.03
	var bottom_y: float = 0.3
	var length: float = top_y - 0.25 - bottom_y
	if length < 1.0:
		return
	for side: float in [-1.0, 1.0]:
		var x: float = side * (0.5 * get_facade_width() - 0.14)
#@ 8-12
		# Un tronc de cône à deux rayons égaux est un cylindre.
		_mesh.cone(Vector3(x, bottom_y + 0.5 * length, pipe_z), radius, radius, length, _materials.pipe, Basis.IDENTITY, 8)
		# La boîte à eau, là où le tuyau reçoit l'eau du toit.
		_mesh.box(Vector3(0.16, 0.2, 0.13), Vector3(x, bottom_y + length + 0.1, pipe_z), _materials.pipe)
		# Un collier tous les deux mètres environ.
		var clamps: int = maxi(int(length / 2.0), 1)
		for clamp_index: int in range(clamps):
			var clamp_y: float = bottom_y + (float(clamp_index) + 0.5) * length / float(clamps)
			_mesh.box(Vector3(0.13, 0.03, 2.0 * radius + 0.04), Vector3(x, clamp_y, pipe_z - 0.01), _materials.pipe)
		# Le coude : la section ronde du tuyau, balayée le long d'un quart de cercle. Le repère
		# du balayage est tourné pour que l'arc se trace dans le plan vertical qui va vers la rue.
		var frame: Transform3D = Transform3D(Basis(Vector3.BACK, Vector3.UP, Vector3.LEFT), Vector3(x, bottom_y, pipe_z + elbow))
		_mesh.sweep(Profiles.circle(radius, 8), frame, Vector2(elbow, elbow), PI, 1.5 * PI, _materials.pipe, 6)
#@ 13+
		# Un tronc de cône à deux rayons égaux est un cylindre. Huit pans de près, cinq à
		# mi-distance ; de loin, le tuyau n'est plus dessiné. Il ne porte pas d'ombre.
		_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
		_mesh.cone(Vector3(x, bottom_y + 0.5 * length, pipe_z), radius, radius, length, _materials.pipe, Basis.IDENTITY, 8)
		_mesh.set_zones(MeshBuilder.ZONE_MID, false)
		_mesh.cone(Vector3(x, bottom_y + 0.5 * length, pipe_z), radius, radius, length, _materials.pipe, Basis.IDENTITY, 5)
		# Tout le reste, de près seulement.
		_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
		# La boîte à eau, là où le tuyau reçoit l'eau du toit.
		_mesh.box(Vector3(0.16, 0.2, 0.13), Vector3(x, bottom_y + length + 0.1, pipe_z), _materials.pipe)
		# Un collier tous les deux mètres environ.
		var clamps: int = maxi(int(length / 2.0), 1)
		for clamp_index: int in range(clamps):
			var clamp_y: float = bottom_y + (float(clamp_index) + 0.5) * length / float(clamps)
			_mesh.box(Vector3(0.13, 0.03, 2.0 * radius + 0.04), Vector3(x, clamp_y, pipe_z - 0.01), _materials.pipe)
		# Le coude : la section ronde du tuyau, balayée le long d'un quart de cercle. Le repère
		# du balayage est tourné pour que l'arc se trace dans le plan vertical qui va vers la rue.
		var frame: Transform3D = Transform3D(Basis(Vector3.BACK, Vector3.UP, Vector3.LEFT), Vector3(x, bottom_y, pipe_z + elbow))
		_mesh.sweep(Profiles.circle(radius, 8), frame, Vector2(elbow, elbow), PI, 1.5 * PI, _materials.pipe, 6)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 10+


## Rez-de-chaussée à boutique : un bandeau de mur en haut, des poteaux, la porte de l'immeuble
## dans la travée de l'escalier, et la devanture dans tout le reste. Renvoie la hauteur du
## plancher haut.
func _build_shop_level(level: Level, shutter_choice: int) -> float:
	var width: float = get_facade_width()
	var height: float = level.height
	var core: int = _core_bay()
	var opening_top: float = height - LINTEL_HEIGHT
	var wall_z: float = -0.5 * WALL_DEPTH
	var post: float = 0.3
	_setback = 0.0

	# Le bandeau de mur au-dessus des ouvertures, sur toute la largeur.
	_wall(Vector3(width, LINTEL_HEIGHT, WALL_DEPTH), Vector3(0.0, height - 0.5 * LINTEL_HEIGHT, wall_z), _materials.facade)
	# Un poteau à chaque bout.
	for side: float in [-1.0, 1.0]:
		_wall(Vector3(post, opening_top, WALL_DEPTH), Vector3(side * 0.5 * (width - post), 0.5 * opening_top, wall_z), _materials.facade)

	# La boutique occupe tout ce qui reste entre les poteaux.
	var shop_left: float = -0.5 * width + post
	var shop_right: float = 0.5 * width - post
	if core >= 0:
		# La travée de l'escalier : un poteau la sépare de la boutique, et la porte de
		# l'immeuble s'ouvre au milieu de ce qui reste.
		var toward_shop: float = 1.0 if core == 0 else -1.0
		var boundary: float = _bay_center(core) + toward_shop * 0.5 * bay_width
		_wall(Vector3(post, opening_top, WALL_DEPTH), Vector3(boundary, 0.5 * opening_top, wall_z), _materials.facade)
		if core == 0:
			shop_left = boundary + 0.5 * post
		else:
			shop_right = boundary - 0.5 * post
		var entry_left: float = (-0.5 * width + post) if core == 0 else (boundary + 0.5 * post)
		var entry_right: float = (boundary - 0.5 * post) if core == 0 else (0.5 * width - post)
		_build_entrance(entry_left, entry_right, opening_top, toward_shop)

	ShopBuilder.build(_mesh, _materials, _random, shop_left, shop_right, opening_top, LINTEL_HEIGHT,
			shutter_choice, fascia_sign, japanese_signs)
	_build_back(level, 0.0)
	return height


## Entrée de l'immeuble, entre les abscisses « left » et « right » : une porte de verre du
## côté « door_side » (1 : à droite, -1 : à gauche), un pan de mur de l'autre côté, du mur
## au-dessus, et le distributeur de boissons adossé au pan de mur.
func _build_entrance(left: float, right: float, opening_top: float, door_side: float) -> void:
	var wall_z: float = -0.5 * WALL_DEPTH
	var door: Vector2 = Vector2(minf(0.9, right - left), minf(2.1, opening_top))
	var cheek: float = right - left - door.x
	var door_x: float = (right - 0.5 * door.x) if door_side > 0.0 else (left + 0.5 * door.x)
	var cheek_x: float = (left + 0.5 * cheek) if door_side > 0.0 else (right - 0.5 * cheek)
	# Le pan de mur à côté de la porte, puis le mur au-dessus d'elle.
	if cheek > 0.01:
		_wall(Vector3(cheek, opening_top, WALL_DEPTH), Vector3(cheek_x, 0.5 * opening_top, wall_z), _materials.facade)
	if opening_top - door.y > 0.01:
		_wall(Vector3(door.x, opening_top - door.y, WALL_DEPTH), Vector3(door_x, 0.5 * (opening_top + door.y), wall_z), _materials.facade)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ 10+
	# La porte : le même shader que les vitrines, avec la donnée « porte », le 2 qui veut dire
	# « hall d'entrée », et la teinte de l'aluminium de l'immeuble.
	_mesh.panel(door, Transform3D(Basis.IDENTITY, Vector3(door_x, 0.5 * door.y, -WINDOW_RECESS)), _materials.shop_window,
			Color(ShopBuilder.KIND_SHOP_DOOR, 0.0, 2.0, 0.0), frame_color)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 10+
	# Le distributeur, adossé au pan de mur, s'il y a la place.
	if vending_machine and cheek >= 0.75:
		SignBuilder.vending(_mesh, _materials, _random, Vector3(cheek_x, 0.0, 0.0), minf(cheek - 0.05, 1.0))
