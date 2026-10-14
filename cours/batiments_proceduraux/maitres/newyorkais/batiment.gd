@tool
extends Node3D
## Tour new-yorkaise, montée par le code à partir des variables ci-dessous.
## {STATUS}
##
## Dans l'éditeur, changer une variable dans l'inspecteur reconstruit la tour aussitôt.
## En jeu, changer des variables par le code puis appeler « rebuild() ».
##
## Ce que le script produit :
##   - quatre façades de brique en grille : un pilier par travée, un bandeau par étage, et un
##     noyau sombre derrière ;
#@ 2-3 quiet
##   - rien d'autre pour l'instant : les étapes suivantes ajoutent une ligne à cette liste.
#@ 4+ quiet
##   - une fenêtre à guillotine dans chaque baie : un rectangle, dont le shader dessine le reste ;
#@ 6+ quiet
##   - des gradins, que le règlement de zonage de 1916 impose, puis une tour qui monte droit ;
##   - un socle de pierre, un rez-de-chaussée plus haut, des murs mitoyens sans fenêtre ;
#@ 7+ quiet
##   - ou bien une tour de verre, sur sa place : un mur-rideau par façade, qu'un shader
##     dessine en entier sur un seul rectangle. Deux familles : à allèges opaques (1961), ou
##     tout en verre, du sol au plafond (aujourd'hui). Leur hauteur sort du règlement de 1961,
##     toujours en vigueur : une surface de planchers, divisée par l'emprise de la tour ;
#@ 8+ quiet
##   - des profils : un chaperon sur chaque parapet, un bandeau en gradins au-dessus du socle
##     de pierre, des ailettes de métal devant les meneaux de 1961, une marquise à l'entrée ;
#@ 9+ quiet
##   - un couronnement : flèche d'acier, pyramide de cuivre ou gradins de pierre sur la tour de
##     brique, et son château d'eau de bois ; un écran de ventelles sur celle de 1961 ; une
##     couronne de verre sur la tour tout en verre, éclairée la nuit ;
#@ 10+ quiet
##   - un rez-de-chaussée : l'entrée et ses portes tambour, des boutiques et leurs enseignes,
##     le numéro de la tour sur la marquise ; des jardinières sur la place ;
#@ 13+ quiet
## Chaque gradin n'est dessiné qu'aux distances où il se voit : les détails de près, leur version
## simplifiée au-delà ; de loin, une façade de brique tient sur un seul rectangle. Chaque gradin
## pose aussi une boîte d'occultation : ce qu'elle cache entièrement n'est pas dessiné. Voir
## « Niveaux de détail » dans les variables, set_zones() et _add_occluder().
#@ all
##
## Comment il est organisé :
##   - ce script décide de la composition : combien de travées, combien d'étages, où ;
#@ 6 quiet
##   - « _make_tiers() » traduit le règlement en une liste de gradins ; les nombres du
##     règlement viennent de « 5_data » (le script « _palette ») ;
#@ 7+ quiet
##   - « _make_tiers() » traduit le règlement en une liste de gradins : celui de 1916 pour la
##     tour de brique, celui de 1961 pour les tours de verre ; les nombres des deux règlements
##     viennent de « 5_data » (le script « _palette ») ;
#@ all
##   - « _materiaux » fabrique les matériaux ;
#@ 8+ quiet
##   - « _profils » dessine la section des chaperons, des bandeaux et des ailettes ;
#@ 9+ quiet
##   - « _couronne » pose ce qui se dresse au-dessus du dernier étage ;
#@ 10+ quiet
##   - « _rez_de_chaussee » monte le rez-de-chaussée : l'entrée et les boutiques ;
#@ all
##   - MeshBuilder (dans 1_core) transforme le tout en maillages, un par matériau.
##
## Repère de la tour : la façade principale est dans le plan z = 0 et regarde vers +Z (la rue),
## elle est centrée sur x = 0, le sol est à y = 0, la tour s'enfonce vers -Z. Unité : le mètre.
#@ 6+ quiet
##
## Le plan du terrain : on décrit les gradins vu de dessus, dans un rectangle (Rect2) dont x
## va de gauche à droite et y de l'alignement de devant vers l'arrière. Un point (x, y) du plan
## est le point (x, 0, -y) de la tour.
#@ all

## L'outil commun de maillage : les fonctions _add_quad et _add_box de l'étape 001 y sont rangées.
const MeshBuilder := preload("res://1_core/procedural/mesh_builder.gd")
## Les matériaux de la tour. « preload » charge le script une fois, à la lecture de celui-ci.
const Materials := preload("{MESH}_materiaux.gd")
#@ 6+
## Les nombres des règlements sont des données : ils vivent dans « 5_data ».
const Palette := preload("{DATA}_palette.gd")
#@ 8+
const Profiles := preload("{MESH}_profils.gd")
#@ 9+
const CrownBuilder := preload("{MESH}_couronne.gd")
#@ 10+
const GroundBuilder := preload("{MESH}_rez_de_chaussee.gd")
#@ all

## Nom du nœud qui reçoit tout ce que le script fabrique.
const GENERATED_NAME: String = "Generated"
## Épaisseur des bandeaux, et saillie des piliers devant eux.
const WALL_DEPTH: float = 0.35
const PIER_PROJECTION: float = 0.12
## Les morceaux de mur voisins se recouvrent de quelques millimètres : posés bord à bord, ils
## laisseraient passer un liseré de lumière à leur jonction.
const WALL_OVERLAP: float = 0.006
## Retrait du noyau sombre derrière les façades.
const CORE_INSET: float = 1.0
#@ 4+
## Retrait des fenêtres derrière le nu des bandeaux.
const WINDOW_RECESS: float = 0.12
#@ 6+
## Ce qu'il y a derrière une fenêtre. Le shader de fenêtre connaît les mêmes nombres.
const KIND_OFFICE: float = 0.0
const KIND_LOBBY: float = 1.0
## Le rez-de-chaussée : allège basse, et un linteau haut au-dessus de ses grandes baies.
const GROUND_SILL: float = 0.6
const GROUND_LINTEL: float = 1.0
## Hauteur du parapet qui borde le toit de chaque gradin. Il compte dans la hauteur du gradin :
## c'est un mur plein, il doit rester sous l'enveloppe.
const PARAPET_HEIGHT: float = 1.1
## Épaisseur de la dalle de toit de chaque gradin.
const ROOF_THICKNESS: float = 0.3
#@ 7+
## Les trois familles de tours.
const FAMILY_BRICK: int = 0
const FAMILY_GLASS_1961: int = 1
const FAMILY_ALL_GLASS: int = 2
## Retrait du noyau sombre derrière le mur-rideau.
const GLASS_CORE_INSET: float = 0.4
## Épaisseur du dallage de la place.
const PLAZA_THICKNESS: float = 0.1
#@ 8+
## Le chaperon de pierre des parapets de brique : il déborde assez pour couvrir la saillie des
## piliers. Celui de métal des tours de verre est plus mince.
const COPING_OVERHANG: float = 0.16
const COPING_HEIGHT: float = 0.15
## Le bandeau en gradins au-dessus du socle de pierre : sa hauteur, sa saillie.
const BAND_HEIGHT: float = 0.45
const BAND_DEPTH: float = 0.3
## Les ailettes des meneaux de la tour de 1961 : leur saillie, la largeur de leur aile.
const FIN_DEPTH: float = 0.2
const FIN_FLANGE: float = 0.12
## La marquise au-dessus de l'entrée : largeur, épaisseur, saillie.
const MARQUEE_SIZE: Vector3 = Vector3(6.0, 0.35, 2.6)
#@ 9+
## Hauteur de la couronne de verre de la tour tout en verre, en étages.
const GLASS_CROWN_STOREYS: float = 3.0
## Largeur de terrasse qu'il faut au château d'eau.
const TANK_TERRACE: float = 7.0
#@ all

#@ 2-5
@export_group("Plan")
## Nombre de travées des façades avant et arrière, puis des façades latérales.
@export_range(2, 30, 1) var bay_count: int = 13
@export_range(2, 30, 1) var side_bay_count: int = 9
## Largeur d'une travée : une fenêtre et un pilier.
@export_range(1.4, 3.0, 0.05, "suffix:m") var bay_width: float = 2.0

@export_group("Niveaux")
## Nombre d'étages, rez-de-chaussée compris. Ils sont tous pareils jusqu'à l'étape 006.
@export_range(1, 80, 1) var floor_count: int = 30
## Hauteur d'un étage, de plancher à plancher : 12 pieds.
@export_range(3.0, 4.5, 0.01, "suffix:m") var floor_height: float = 3.66
#@ 6+
@export_group("Terrain")
## Largeur du terrain, le long de la rue de devant, puis sa profondeur. 61 m : les 200 pieds
## d'un îlot de Manhattan, du nord au sud ; le terrain va d'une rue à l'autre.
@export_range(16.0, 120.0, 0.5, "suffix:m") var lot_width: float = 45.0
@export_range(16.0, 80.0, 0.5, "suffix:m") var lot_depth: float = 61.0
## Largeur de la rue de chaque côté du terrain. 0 : pas de rue, un voisin mitoyen.
## 18,29 m : une rue transversale de 60 pieds ; 30,48 m : une avenue de 100 pieds.
@export_range(0.0, 40.0, 0.01, "suffix:m") var street_front: float = 18.29
@export_range(0.0, 40.0, 0.01, "suffix:m") var street_right: float = 30.48
@export_range(0.0, 40.0, 0.01, "suffix:m") var street_back: float = 18.29
@export_range(0.0, 40.0, 0.01, "suffix:m") var street_left: float = 0.0
## Largeur d'une travée : une fenêtre et un pilier.
@export_range(1.4, 3.0, 0.05, "suffix:m") var bay_width: float = 2.0

@export_group("Niveaux")
## Nombre d'étages au-dessus du rez-de-chaussée.
@export_range(1, 100, 1) var floor_count: int = 40
## Hauteur d'un étage, de plancher à plancher : 12 pieds.
@export_range(3.0, 4.5, 0.01, "suffix:m") var floor_height: float = 3.66
## Hauteur du rez-de-chaussée, de plancher à plancher.
@export_range(4.0, 8.0, 0.05, "suffix:m") var ground_height: float = 5.5
## Nombre de niveaux habillés de pierre, rez-de-chaussée compris : le socle.
@export_range(0, 8, 1) var stone_floors: int = 3

@export_group("Règlement de 1916")
## District de hauteur : la façade sur rue monte droit jusqu'à ce multiple de la largeur de
## la rue, puis l'enveloppe se couche.
@export_enum("1 fois", "1¼ fois", "1½ fois", "2 fois", "2½ fois") var height_district: int = 3
## Profondeur d'un retrait, en travées. L'enveloppe permettrait un escalier d'étage en étage ;
## l'architecte regroupe les retraits en quelques gradins francs.
@export_range(1, 6, 1) var setback_bays: int = 3
## Part du terrain que couvre la tour. Le règlement en permet un quart au plus.
@export_range(0.05, 0.25, 0.01) var tower_share: float = 0.25
#@ 7+

@export_group("Famille")
## La tour de brique en gradins du règlement de 1916 ; la tour de verre à allèges opaques du
## règlement de 1961 ; la tour tout en verre d'aujourd'hui, sous le même règlement de 1961,
## toujours en vigueur.
#@ 7-10
@export_enum("Brique (1916)", "Verre et allèges (1961)", "Tout en verre (aujourd'hui)") var family: int = 0
#@ 11+
@export_enum("Selon la graine", "Brique (1916)", "Verre et allèges (1961)", "Tout en verre (aujourd'hui)") var family_choice: int = 1
#@ 7+

@export_group("Règlement de 1961")
## Étages d'un socle bâti à l'alignement, sous la tour : six au plus, et 85 pieds. 0 : la tour
## se dresse seule sur sa place.
@export_range(0, 6, 1) var podium_floors: int = 0
## Part du terrain que couvre la tour de verre. Le règlement la plafonne : 40 % sur un grand
## terrain, un peu plus sur un petit. Une tour plus fine monte plus haut : sa surface de
## planchers est fixée.
@export_range(0.1, 0.5, 0.01) var glass_tower_share: float = 0.4
## Largeur d'un module de mur-rideau : l'écart entre deux meneaux. Cinq pieds.
@export_range(1.0, 3.0, 0.01, "suffix:m") var module_width: float = 1.52
#@ all

@export_group("Baies")
## Largeur et hauteur d'une fenêtre. La largeur fixe celle des piliers : ce qui reste de la
## travée.
@export_range(0.6, 2.4, 0.05, "suffix:m") var window_width: float = 1.2
@export_range(0.8, 3.0, 0.05, "suffix:m") var window_height: float = 1.9
## Hauteur de l'allège : du plancher au bas de la fenêtre.
@export_range(0.2, 1.4, 0.05, "suffix:m") var sill_height: float = 0.85

@export_group("Aspect")
#@ 2
## Teinte de la brique. Le script la donne aux matériaux, qui la donnent au shader.
@export var brick_color: Color = Color(0.62, 0.46, 0.36)
#@ 3+
## Teinte de la brique, du chamois au brun.
@export var brick_color: Color = Color(0.62, 0.46, 0.36)
## Encrassement des murs, de 0 (lavés) à 1 (noirs de suie).
@export_range(0.0, 1.0, 0.01) var grime: float = 0.35
#@ 4+
## Teinte des châssis des fenêtres.
@export var frame_color: Color = Color(0.16, 0.17, 0.15)
#@ 6+
## Teinte de la pierre du socle.
@export var stone_color: Color = Color(0.78, 0.75, 0.68)
#@ 7+
## Teintes des tours de verre : le verre, les allèges, le métal des meneaux.
@export var glass_tint: Color = Color(0.62, 0.74, 0.72)
@export var spandrel_color: Color = Color(0.12, 0.15, 0.16)
@export var metal_color: Color = Color(0.62, 0.63, 0.64)
#@ 9+

@export_group("Couronnement")
## Le sommet de la tour de brique. Les tours de verre ont le leur : un écran de ventelles en
## 1961, une couronne de verre aujourd'hui.
#@ 9-10
@export_enum("Toit plat", "Gradins", "Flèche", "Pyramide de cuivre") var crown: int = 2
#@ 11+
@export_enum("Selon la graine", "Toit plat", "Gradins", "Flèche", "Pyramide de cuivre") var crown_choice: int = 3
#@ 9+
## Le château d'eau de bois, sur une terrasse de la tour de brique.
@export var water_tank: bool = true
## Des projecteurs éclairent le couronnement la nuit.
@export var crown_lights: bool = true
#@ 11+

@export_group("Graine")
## Change tous les tirages : la famille et le couronnement laissés « Selon la graine », les
## proportions et les teintes si on les lui confie, les pièces derrière les vitres, les
## boutiques du rez-de-chaussée.
@export var variation_seed: int = 0
## Petits bois des fenêtres à guillotine.
@export_enum("Selon la graine", "Un sur un", "Deux sur deux", "Six sur six", "Trois sur un") var window_lights: int = 1
## Vrai : la graine choisit les proportions (retraits, emprise de la tour, socle, nombre
## d'étages à un quart près) ; faux : on garde celles de l'inspecteur.
@export var random_massing: bool = false
## Vrai : la graine choisit les teintes dans les listes de la palette ; faux : on garde celles de
## l'inspecteur.
@export var random_colors: bool = false
#@ 13+

@export_group("Niveaux de détail")
## Jusqu'à cette distance, un gradin est dessiné en entier. Au-delà, ses profils deviennent des
## boîtes et ses petits objets disparaissent. La distance est comptée de la caméra au centre de
## chaque gradin : une tour est trop haute pour un seul niveau de détail. 0 pour les deux
## distances : pas de niveaux de détail.
@export_range(0.0, 300.0, 1.0, "suffix:m") var near_distance: float = 60.0
## Au-delà de cette distance, une façade de brique n'est plus qu'un rectangle, dessiné par le
## shader de la façade lointaine.
@export_range(0.0, 1000.0, 1.0, "suffix:m") var far_distance: float = 250.0
## Chaque gradin pose une boîte d'occultation : ce qu'elle cache entièrement n'est pas dessiné.
@export var occluders: bool = true
#@ 6+


## Un gradin de la tour : un prisme droit, sur un rectangle du plan du terrain.
## « _make_tiers() » en fait la liste, du bas vers le haut ; « _build_tier() » les monte.
class Tier:
	## Emprise dans le plan du terrain : x de gauche à droite, y de l'alignement de devant vers
	## l'arrière.
	var rect: Rect2 = Rect2()
	## Premier étage du gradin (0 : le rez-de-chaussée), et nombre d'étages.
	var first_floor: int = 0
	var floor_count: int = 0
	## Hauteur du sol du gradin, et de son toit (sans le parapet).
	var base_y: float = 0.0
	var top_y: float = 0.0
	## Vrai si ce gradin fait partie de la tour : elle a le droit de percer l'enveloppe.
	var tower: bool = false
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
## Le dé de la tour. Sa graine est fixée au début de chaque construction.
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
#@ 11+
## Les choix retenus, après les tirages de la graine (voir _resolve()). « family » et « crown »
## gardent les noms des variables des étapes précédentes : le reste du script les lit sans
## changer ; « family_choice » et « crown_choice » sont ce que demande l'inspecteur.
var family: int = 0
var crown: int = 0
var _lights: int = 0
var _setback_bays: int = 3
var _tower_share: float = 0.25
var _glass_share: float = 0.4
var _podium: int = 0
var _floor_count: int = 40
var _brick_color: Color = Color.WHITE
var _stone_color: Color = Color.WHITE
var _frame_color: Color = Color.WHITE
var _glass_tint: Color = Color.WHITE
var _spandrel_color: Color = Color.WHITE
var _metal_color: Color = Color.WHITE
#@ all


func _ready() -> void:
	# Dans le jeu, la tour est montée une fois ; inutile de surveiller ses variables.
	set_process(Engine.is_editor_hint())
	rebuild()


func _process(_delta: float) -> void:
	# Dans l'éditeur, à chaque image : une variable a-t-elle changé dans l'inspecteur ?
	if _current_signature() != _signature:
		rebuild()
#@ 2-5


## Largeur de la façade principale, et profondeur de la tour.
func get_facade_width() -> float:
	return float(bay_count) * bay_width


func get_depth() -> float:
	return float(side_bay_count) * bay_width
#@ 6+


## Largeur de la façade principale : celle du terrain, le rez-de-chaussée occupe tout.
func get_facade_width() -> float:
	return lot_width


#@ 6
## Marge sous l'enveloppe de 1916, en mètres : la plus petite distance verticale entre le haut
## d'un gradin (parapet compris) et le plan incliné d'une des rues. Les gradins de la tour ne
## comptent pas : ils ont le droit de percer l'enveloppe. Négative : un gradin la perce. Le
## test de l'étape s'en sert. Sans aucune rue, elle est infinie.
func get_zoning_margin() -> float:
	var lot: Rect2 = _lot_rect()
	var margin: float = INF
	for tier: Tier in _make_tiers():
		if tier.tower:
			continue
		for side: int in range(4):
			var street: float = _street(side)
			if street <= 0.0:
				continue
			var envelope: float = _envelope_height(street, _setback_from(lot, tier.rect, side))
			margin = minf(margin, envelope - (tier.top_y + _parapet_top()))
	return margin


## Part du terrain couverte par la tour (x) et part permise par le règlement (y). Sans tour,
## x vaut 0.
func get_tower_coverage() -> Vector2:
	var share: float = 0.0
	for tier: Tier in _make_tiers():
		if tier.tower:
			share = maxf(share, tier.rect.get_area() / _lot_rect().get_area())
	return Vector2(share, Palette.TOWER_SHARE_1916)
#@ 7+
## Marge sous le règlement, en mètres. Négative : la tour est en faute. Le test de l'étape s'en
## sert. Sans aucune rue, elle est infinie.
##   - tour de brique : la plus petite distance verticale entre le haut d'un gradin (parapet
##     compris) et le plan incliné d'une rue. Les gradins de la tour ne comptent pas : ils ont
##     le droit de percer l'enveloppe ;
##   - tour de verre : pour le socle, ce qui reste sous les 85 pieds du mur de façade ; pour la
##     tour, ce qu'elle garde en plus des 15 ou 10 pieds de retrait qu'elle doit aux rues.
func get_zoning_margin() -> float:
	var lot: Rect2 = _lot_rect()
	var margin: float = INF
	for tier: Tier in _make_tiers():
		if family == FAMILY_BRICK:
			if tier.tower:
				continue
			for side: int in range(4):
				var street: float = _street(side)
				if street > 0.0:
					var envelope: float = _envelope_height(street, _setback_from(lot, tier.rect, side))
					margin = minf(margin, envelope - (tier.top_y + _parapet_top()))
		elif tier.tower:
			for side: int in range(4):
				var street: float = _street(side)
				if street > 0.0:
					margin = minf(margin, _setback_from(lot, tier.rect, side) - _tower_setback(street))
		else:
			margin = minf(margin, Palette.FRONT_WALL_MAX - (tier.top_y + _parapet_top()))
	return margin


## Part du terrain couverte par la tour (x) et part permise par le règlement (y) : un quart en
## 1916, 40 % en 1961 sur un grand terrain. Sans tour, x vaut 0.
func get_tower_coverage() -> Vector2:
	var lot_area: float = _lot_rect().get_area()
	var share: float = 0.0
	for tier: Tier in _make_tiers():
		if tier.tower:
			share = maxf(share, tier.rect.get_area() / lot_area)
	var allowed: float = Palette.TOWER_SHARE_1916 if family == FAMILY_BRICK else Palette.tower_share_1961(lot_area)
	return Vector2(share, allowed)


## Coefficient d'occupation : la surface de tous les planchers divisée par celle du terrain (x),
## et ce que le règlement permet (y). Le règlement de 1916 ne limitait pas la surface, seulement
## l'enveloppe : y est alors infini.
func get_floor_area_ratio() -> Vector2:
	var area: float = 0.0
	for tier: Tier in _make_tiers():
		area += tier.rect.get_area() * float(tier.floor_count)
	var allowed: float = INF if family == FAMILY_BRICK else Palette.FLOOR_AREA_RATIO
	return Vector2(area / _lot_rect().get_area(), allowed)
#@ 6+


## Hauteur de la tour au toit de son dernier étage, sans parapet.
func get_height() -> float:
#@ 6
	return _floor_y(floor_count + 1)
#@ 7+
	var tiers: Array[Tier] = _make_tiers()
	if tiers.is_empty():
		return 0.0
	var last: Tier = tiers.back()
	return last.top_y
#@ 6+
#@ 5+


## 0 : jour, 1 : nuit. Allume ou éteint les pièces derrière les fenêtres.
func set_night(value: float) -> void:
	_night = value
	if _materials != null:
		_materials.set_night(_night)
#@ 13+


## Finesse de calcul des shaders : 0 basse, 1 moyenne, 2 haute. Ce n'est pas une variable de la
## tour mais un réglage de la machine : il se change sans rien reconstruire.
func set_quality(level: int) -> void:
	_quality = level
	if _materials != null:
		_materials.set_quality(_quality)
#@ all


## Démonte la tour et la remonte d'après les variables courantes.
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

	# Les matériaux d'abord : chaque forme donnée à l'outil de maillage est rangée d'après son
	# matériau. On règle, puis on fabrique.
	_materials = Materials.new()
#@ 2-10
	_materials.brick_color = brick_color
#@ 3-10
	_materials.grime = grime
#@ 4-10
	_materials.frame_color = frame_color
#@ 5-10
	# Le shader de fenêtre a besoin des cotes des étages pour placer le sol et le plafond des
	# pièces qu'il dessine derrière la vitre.
	_materials.floor_height = floor_height
	_materials.sill_height = sill_height
	_materials.bay_width = bay_width
#@ 6-10
	_materials.ground_height = ground_height
	_materials.ground_sill = GROUND_SILL
	_materials.stone_color = stone_color
#@ 7-10
	# Les tours de verre : le mur-rideau dépend de la famille et des cotes de la grille.
	_materials.glass_style = family
	_materials.module_width = module_width
	_materials.parapet_height = PARAPET_HEIGHT
	_materials.glass_tint = glass_tint
	_materials.spandrel_color = spandrel_color
	_materials.metal_color = metal_color
#@ 11+
	# D'abord les choix de la graine : la famille, le couronnement, les proportions, les teintes.
	_resolve()
	_materials.brick_color = _brick_color
	_materials.grime = grime
	_materials.frame_color = _frame_color
	_materials.floor_height = floor_height
	_materials.sill_height = sill_height
	_materials.bay_width = bay_width
	_materials.ground_height = ground_height
	_materials.ground_sill = GROUND_SILL
	_materials.stone_color = _stone_color
	_materials.glass_style = family
	_materials.module_width = module_width
	_materials.parapet_height = PARAPET_HEIGHT
	_materials.glass_tint = _glass_tint
	_materials.spandrel_color = _spandrel_color
	_materials.metal_color = _metal_color
	# La graine décale aussi les motifs et change le tirage des pièces derrière les vitres.
	_materials.variation_seed = variation_seed
	_materials.upper_lights = Palette.WINDOW_LIGHTS[_lights][0]
	_materials.lower_lights = Palette.WINDOW_LIGHTS[_lights][1]
#@ 13+
	_materials.quality = _quality
	# La façade lointaine doit connaître la grille : la taille des fenêtres, le haut du socle.
	_materials.window_size = _opening(1)
	_materials.stone_top = _stone_top()
#@ all
	_materials.build()
#@ 5+
	_materials.set_night(_night)
#@ 10
	# Les boutiques tirent au sort leur sorte, leur nom, leurs teintes. Le dé repart toujours de
	# la même graine : la tour est la même à chaque construction. L'étape 011 rendra cette
	# graine réglable.
	_random.seed = 0
#@ 11+
	# Le dé des boutiques et du numéro : la même graine, décalée, pour qu'il ne rejoue pas les
	# tirages de _resolve().
	_random.seed = hash(variation_seed + 7919)
#@ all
	_mesh = MeshBuilder.new()
#@ 13+
	# Les distances des niveaux de détail. L'outil de maillage s'en sert pour ranger chaque
	# pièce dans sa zone : voir set_zones().
	_mesh.near_distance = near_distance
	_mesh.far_distance = far_distance
#@ all

#@ 2-5
	# Les quatre façades. Chacune est décrite dans son propre repère : son plan est z = 0, elle
	# regarde vers +Z, elle est centrée sur x = 0. Le repère est ensuite tourné et posé à sa
	# place : devant, à droite, derrière, à gauche.
	var width: float = get_facade_width()
	var depth: float = get_depth()
	var height: float = float(floor_count) * floor_height
	var faces: Array[Transform3D] = [
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, 0.0)),
		Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(0.5 * width, 0.0, -0.5 * depth)),
		Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -depth)),
		Transform3D(Basis(Vector3.UP, -0.5 * PI), Vector3(-0.5 * width, 0.0, -0.5 * depth)),
	]
	for index: int in range(faces.size()):
		var bays: int = bay_count if index % 2 == 0 else side_bay_count
		_build_face(faces[index], bays, height)

	# Le noyau : une boîte sombre, en retrait d'un mètre derrière les façades.
	_mesh.box(Vector3(width - 2.0 * CORE_INSET, height, depth - 2.0 * CORE_INSET),
			Vector3(0.0, 0.5 * height, -0.5 * depth), _materials.core)
#@ 6
	# La tour, gradin par gradin, du bas vers le haut. Chaque gradin connaît celui du dessus.
	var tiers: Array[Tier] = _make_tiers()
	for index: int in range(tiers.size()):
		_build_tier(tiers[index], _tier_above(tiers, index))
#@ 7+
	# La tour, gradin par gradin, du bas vers le haut : de brique, ou de verre. Une tour de verre
	# sans socle se dresse sur une place, qui occupe le reste du terrain.
	var tiers: Array[Tier] = _make_tiers()
	for index: int in range(tiers.size()):
		if family == FAMILY_BRICK:
			_build_tier(tiers[index], _tier_above(tiers, index))
		else:
			_build_glass_tier(tiers[index])
#@ 13+
		# Chaque gradin devient ses propres nœuds, avec sa propre boîte : ses niveaux de détail se
		# règlent sur la distance au centre du gradin, pas sur celle du centre de toute la tour.
		# Sans cela, au pied d'une tour de 150 m, on serait déjà à 75 m de son centre.
		_mesh.commit(_root)
		if occluders:
			_add_occluder(tiers[index])
#@ 7+
	if family != FAMILY_BRICK and (tiers.is_empty() or tiers[0].tower):
		_build_plaza()
#@ 8+
	_build_marquee(tiers)
#@ 13+
	# Le pied de la tour (la place, la marquise) a sa boîte à lui ; le couronnement, la sienne.
	_mesh.commit(_root)
#@ 9+
	if not tiers.is_empty():
		_build_crown(tiers)
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
#@ 6+


# --- Règlement : des variables aux gradins -----------------------------------

## Le terrain, dans le plan : centré sur x = 0, de l'alignement de devant (y = 0) vers l'arrière.
func _lot_rect() -> Rect2:
	return Rect2(-0.5 * lot_width, 0.0, lot_width, lot_depth)


## Largeur de la rue d'un côté du terrain. side : 0 devant, 1 à droite, 2 derrière, 3 à gauche.
func _street(side: int) -> float:
	return [street_front, street_right, street_back, street_left][side]


## Ce qui dépasse du toit d'un gradin et compte dans sa hauteur : le parapet, un mur plein,
#@ 6-7
## qui doit rester sous l'enveloppe.
func _parapet_top() -> float:
	return PARAPET_HEIGHT
#@ 8+
## et le chaperon qui le coiffe.
func _parapet_top() -> float:
	return PARAPET_HEIGHT + COPING_HEIGHT
#@ 6+


## Hauteur du plancher de l'étage « index » : 0 pour le rez-de-chaussée ; floor_count + 1 donne
## le toit du dernier étage.
func _floor_y(index: int) -> float:
	if index <= 0:
		return 0.0
	return ground_height + float(index - 1) * floor_height


## Hauteur que permet l'enveloppe d'une rue large de « street », à « distance » mètres en
## retrait de l'alignement. L'enveloppe est un plan incliné qui part de l'axe de la rue, au
## sol, et monte de 2 × m mètres par mètre : à l'alignement, à une demi-rue de l'axe, il
## passe à m fois la largeur de la rue. C'est la règle des districts de hauteur de 1916.
func _envelope_height(street: float, distance: float) -> float:
	var multiple: float = Palette.HEIGHT_MULTIPLES[height_district]
	return 2.0 * multiple * (0.5 * street + distance)


## Le rectangle « rect », rogné de « amount » mètres du côté « side ». grow_individual() fait
## grandir un rectangle par ses côtés gauche, haut, droit et bas : dans le plan du terrain, le
## « haut » est le côté de l'alignement de devant (les y les plus petits).
func _shrink(rect: Rect2, side: int, amount: float) -> Rect2:
	match side:
		0:
			return rect.grow_individual(0.0, -amount, 0.0, 0.0)
		1:
			return rect.grow_individual(0.0, 0.0, -amount, 0.0)
		2:
			return rect.grow_individual(0.0, 0.0, 0.0, -amount)
		_:
			return rect.grow_individual(-amount, 0.0, 0.0, 0.0)


## Un gradin de « count » étages à partir de l'étage « first », sur le rectangle « rect ».
func _tier(rect: Rect2, first: int, count: int, tower: bool) -> Tier:
	var tier: Tier = Tier.new()
	tier.rect = rect
	tier.first_floor = first
	tier.floor_count = count
	tier.base_y = _floor_y(first)
	tier.top_y = _floor_y(first + count)
	tier.tower = tower
	return tier


## Distance entre un côté du rectangle « rect » et le même côté du terrain : le retrait.
func _setback_from(lot: Rect2, rect: Rect2, side: int) -> float:
	match side:
		0:
			return rect.position.y - lot.position.y
		1:
			return lot.end.x - rect.end.x
		2:
			return lot.end.y - rect.end.y
		_:
			return rect.position.x - lot.position.x


## Emprise de la tour : centrée sur le terrain, la plus grande qui couvre au plus
## « tower_share » de sa surface, en préférant les tours presque carrées. Elle recule d'un
## nombre entier de travées de chaque côté, pour que ses fenêtres tombent dans l'alignement de
## celles des gradins du dessous.
func _tower_rect(lot: Rect2) -> Rect2:
#@ 6-10
	var allowed: float = tower_share * lot.get_area()
#@ 11+
	var allowed: float = _tower_share * lot.get_area()
#@ 6+
	var best: Rect2 = Rect2()
	var best_score: float = 0.0
	var steps_x: int = floori(lot.size.x / (2.0 * bay_width))
	var steps_y: int = floori(lot.size.y / (2.0 * bay_width))
	for kx: int in range(steps_x + 1):
		for ky: int in range(steps_y + 1):
			var size: Vector2 = lot.size - 2.0 * bay_width * Vector2(float(kx), float(ky))
			if size.x < 2.0 * bay_width or size.y < 2.0 * bay_width or size.x * size.y > allowed:
				continue
			# La surface, multipliée par l'élancement : un carré garde toute sa surface, un
			# rectangle deux fois plus long que large n'en garde que la moitié.
			var score: float = size.x * size.y * minf(size.x, size.y) / maxf(size.x, size.y)
			if score > best_score:
				best_score = score
				best = Rect2(lot.get_center() - 0.5 * size, size)
	return best


## La liste des gradins de la tour, du bas vers le haut, d'après son règlement.
func _make_tiers() -> Array[Tier]:
#@ 6
	return _make_setback_tiers()
#@ 11+
	# Les choix de la graine d'abord : la famille et les proportions en dépendent.
	_resolve()
#@ 7+
	if family == FAMILY_BRICK:
		return _make_setback_tiers()
	return _make_glass_tiers()
#@ 6+


## Les gradins du règlement de 1916. Étage par étage, du bas vers le haut :
##   1. chaque rue demande un retrait, pour que le haut de l'étage, parapet compris, reste sous
##      son enveloppe ; on l'arrondit au retrait entier suivant (setback_bays travées) ;
##   2. le terrain, rogné de ces retraits, donne l'emprise de l'étage ;
##   3. si cette emprise ne contient plus la tour, l'étage appartient à la tour : elle a le droit
##      de percer l'enveloppe, puisqu'elle couvre au plus un quart du terrain ;
##   4. un étage de même emprise que celui du dessous prolonge son gradin ; sinon, il en
##      commence un nouveau.
func _make_setback_tiers() -> Array[Tier]:
	var lot: Rect2 = _lot_rect()
	var tower: Rect2 = _tower_rect(lot)
#@ 6-10
	var step: float = float(setback_bays) * bay_width
#@ 11+
	var step: float = float(_setback_bays) * bay_width
#@ 6+
	var multiple: float = Palette.HEIGHT_MULTIPLES[height_district]
	var tiers: Array[Tier] = []
	var in_tower: bool = false
#@ 6-10
	for index: int in range(floor_count + 1):
#@ 11+
	for index: int in range(_floor_count + 1):
#@ 6+
		var top: float = _floor_y(index + 1) + _parapet_top()
		var plate: Rect2 = lot
		if not in_tower:
			for side: int in range(4):
				var street: float = _street(side)
				if street <= 0.0:
					continue
				# Retrait demandé : là où l'enveloppe atteint la hauteur « top ».
				var needed: float = top / (2.0 * multiple) - 0.5 * street
				if needed <= 0.0:
					continue
				plate = _shrink(plate, side, ceilf(needed / step - 0.0001) * step)
			# Une marge d'un millimètre : deux bords qui coïncident comptent comme contenus.
			in_tower = tower.has_area() and not plate.grow(0.001).encloses(tower)
		if in_tower:
			plate = tower
		elif plate.size.x < 2.0 * bay_width or plate.size.y < 2.0 * bay_width:
			# Sans tour possible (un terrain trop petit), les gradins finissent par ne plus
			# avoir la place : la construction s'arrête là.
			break
		if not tiers.is_empty() and tiers.back().rect.is_equal_approx(plate):
			var current: Tier = tiers.back()
			current.floor_count += 1
			current.top_y = _floor_y(index + 1)
		else:
			tiers.append(_tier(plate, index, 1, in_tower))
	return tiers
#@ 7+


## Retrait qu'une tour de verre doit à une rue (section 33-451) : 10 pieds d'une rue large,
## 15 pieds d'une rue étroite. Le cours garde aussi 15 pieds du côté d'un voisin (« street »
## vaut 0), pour que les quatre façades aient du verre.
func _tower_setback(street: float) -> float:
	return Palette.TOWER_SETBACK_WIDE if street >= Palette.WIDE_STREET else Palette.TOWER_SETBACK_NARROW


## Emprise de la tour de verre : dans ce qui reste du terrain une fois ôtés ses retraits, la
## plus grande qui couvre au plus « glass_tower_share » du terrain, et jamais plus que le
## règlement ne permet. Ses côtés font un nombre entier de modules de mur-rideau ; comme pour
## la tour de 1916, on préfère les tours presque carrées.
func _glass_tower_rect(lot: Rect2) -> Rect2:
	var free: Rect2 = lot
	for side: int in range(4):
		free = _shrink(free, side, _tower_setback(_street(side)))
#@ 7-10
	var allowed: float = minf(glass_tower_share, Palette.tower_share_1961(lot.get_area())) * lot.get_area()
#@ 11+
	var allowed: float = minf(_glass_share, Palette.tower_share_1961(lot.get_area())) * lot.get_area()
#@ 7+
	var best: Rect2 = Rect2()
	var best_score: float = 0.0
	for nx: int in range(2, floori(free.size.x / module_width) + 1):
		for ny: int in range(2, floori(free.size.y / module_width) + 1):
			var size: Vector2 = Vector2(float(nx), float(ny)) * module_width
			if size.x * size.y > allowed:
				continue
			var score: float = size.x * size.y * minf(size.x, size.y) / maxf(size.x, size.y)
			if score > best_score:
				best_score = score
				best = Rect2(free.get_center() - 0.5 * size, size)
	return best


## Les gradins du règlement de 1961 : un socle éventuel, bâti sur tout le terrain, puis la tour.
## Le règlement ne fixe pas la hauteur de la tour : il fixe la surface de tous les planchers,
## quinze fois celle du terrain. Le nombre d'étages de la tour en sort par une division :
## « floor_count » ne sert pas ici.
func _make_glass_tiers() -> Array[Tier]:
	var lot: Rect2 = _lot_rect()
	var tower: Rect2 = _glass_tower_rect(lot)
	var tiers: Array[Tier] = []
	# Le socle : six étages au plus, et son mur de façade, parapet compris, sous les 85 pieds.
#@ 7-10
	var podium: int = mini(podium_floors, Palette.FRONT_WALL_FLOORS)
#@ 11+
	var podium: int = mini(_podium, Palette.FRONT_WALL_FLOORS)
#@ 7+
	while podium > 0 and _floor_y(podium) + _parapet_top() > Palette.FRONT_WALL_MAX:
		podium -= 1
	if podium > 0:
		tiers.append(_tier(lot, 0, podium, false))
	if not tower.has_area():
		return tiers
	# La surface de planchers qui reste après le socle, divisée par celle d'un étage de la tour.
	var area_left: float = Palette.FLOOR_AREA_RATIO * lot.get_area() - float(podium) * lot.get_area()
	var tower_floors: int = floori(area_left / tower.get_area())
	if tower_floors > 0:
		tiers.append(_tier(tower, podium, tower_floors, true))
	return tiers
#@ all


# --- Façades ----------------------------------------------------------------

## Boîte décrite dans le repère d'une façade : son centre est transformé par le repère, et ses
## axes tournent avec lui.
func _box_in(frame: Transform3D, size: Vector3, center: Vector3, material: Material) -> void:
	_mesh.box(size, frame * center, material, frame.basis)
#@ 2-5


## Taille d'une fenêtre : elle ne peut pas être plus grande que sa case.
func _opening() -> Vector2:
	return Vector2(minf(window_width, bay_width - 0.3), minf(window_height, floor_height - sill_height - 0.3))


## Monte une façade de « bays » travées sur « height » mètres, dans le repère « frame » : les
## piliers, un bandeau sous chaque rangée de fenêtres, un dernier en haut, et le pilier d'angle
## de son bout gauche.
func _build_face(frame: Transform3D, bays: int, height: float) -> void:
	var width: float = float(bays) * bay_width
	var opening: Vector2 = _opening()
	var pier: float = bay_width - opening.x

	# Un pilier entre deux travées, sur toute la hauteur.
	for bay: int in range(1, bays):
		var x: float = -0.5 * width + float(bay) * bay_width
		_box_in(frame, Vector3(pier, height, WALL_DEPTH + PIER_PROJECTION),
				Vector3(x, 0.5 * height, 0.5 * (PIER_PROJECTION - WALL_DEPTH)), _materials.brick)

	# Un bandeau par étage, du haut de la fenêtre du dessous au bas de celle de cet étage.
	for floor_index: int in range(floor_count):
		var sill_y: float = float(floor_index) * floor_height + sill_height
		var bottom: float = maxf(sill_y - (floor_height - opening.y), 0.0)
		_box_in(frame, Vector3(width + WALL_OVERLAP, sill_y - bottom, WALL_DEPTH),
				Vector3(0.0, 0.5 * (bottom + sill_y), -0.5 * WALL_DEPTH), _materials.brick)
#@ 4-5
		# La fenêtre de chaque travée : un rectangle instancié, de la taille de la baie, en
		# retrait au fond de la baie. Le script ne pose que ce rectangle ; tout le reste
		# (châssis, carreaux, vitre) est dessiné par son shader. Le repère dit où est son centre
		# et vers où il regarde : celui de la façade, déplacé au centre de la baie.
		for bay: int in range(bays):
			var center: Vector3 = Vector3(-0.5 * width + (float(bay) + 0.5) * bay_width, sill_y + 0.5 * opening.y, -WINDOW_RECESS)
			_mesh.panel(opening, frame * Transform3D(Basis.IDENTITY, center), _materials.window)
#@ 2-5
	# Le dernier bandeau, du haut des fenêtres du dernier étage jusqu'au sommet.
	var last_head: float = float(floor_count - 1) * floor_height + sill_height + opening.y
	_box_in(frame, Vector3(width + WALL_OVERLAP, height - last_head, WALL_DEPTH),
			Vector3(0.0, 0.5 * (last_head + height), -0.5 * WALL_DEPTH), _materials.brick)

	# Le pilier d'angle : il prend la demi-largeur de pilier qui reste au bout de cette façade et
	# celle de la façade voisine, et avance comme les autres piliers sur les deux façades.
	var corner: float = 0.5 * pier + PIER_PROJECTION
	_box_in(frame, Vector3(corner, height, corner),
			Vector3(-0.5 * width - PIER_PROJECTION + 0.5 * corner, 0.5 * height, PIER_PROJECTION - 0.5 * corner), _materials.brick)
#@ 6+


## Allège et taille de la fenêtre de l'étage « index ». Le rez-de-chaussée a de grandes baies,
## de la même largeur que les autres, presque de plain-pied. Aucune fenêtre ne peut être plus
## grande que sa case.
func _sill(index: int) -> float:
	return GROUND_SILL if index == 0 else sill_height


func _opening(index: int) -> Vector2:
	var width: float = minf(window_width, bay_width - 0.3)
	if index == 0:
		return Vector2(width, ground_height - GROUND_SILL - GROUND_LINTEL)
	return Vector2(width, minf(window_height, floor_height - sill_height - 0.3))


## Hauteur où finit la pierre du socle : en haut des fenêtres de son dernier niveau. Le
## bandeau qui suit, sous les fenêtres de l'étage du dessus, est déjà en brique.
func _stone_top() -> float:
	if stone_floors <= 0:
		return 0.0
	var last: int = stone_floors - 1
	return _floor_y(last) + _sill(last) + _opening(last).y


## Brique ou pierre, pour un morceau de mur dont le haut est à « top » : tout ce qui finit sous
## le haut du socle est en pierre.
func _wall_material(top: float) -> Material:
	return _materials.stone if top <= _stone_top() + 0.001 else _materials.brick


## Nombre de travées entières dans une façade de « width » mètres, et la marge qui reste à
## chaque bout : elle est prise par les piliers d'angle.
func _bays(width: float) -> int:
	return floori(width / bay_width + 0.001)


func _margin(width: float) -> float:
	return 0.5 * (width - float(_bays(width)) * bay_width)


## Repère d'une façade du rectangle « rect » du plan : son origine est au milieu du pied de la
## façade, son axe x court le long d'elle (de gauche à droite pour qui la regarde du dehors),
## son axe z regarde vers le dehors. side : 0 devant, 1 à droite, 2 derrière, 3 à gauche.
func _face_frame(rect: Rect2, side: int) -> Transform3D:
	var center: Vector2 = rect.get_center()
	match side:
		0:
			return Transform3D(Basis.IDENTITY, Vector3(center.x, 0.0, -rect.position.y))
		1:
			return Transform3D(Basis(Vector3.UP, 0.5 * PI), Vector3(rect.end.x, 0.0, -center.y))
		2:
			return Transform3D(Basis(Vector3.UP, PI), Vector3(center.x, 0.0, -rect.end.y))
		_:
			return Transform3D(Basis(Vector3.UP, -0.5 * PI), Vector3(rect.position.x, 0.0, -center.y))


## Largeur d'une façade du rectangle : les côtés 0 et 2 courent le long de x, les autres le
## long de y.
func _face_width(rect: Rect2, side: int) -> float:
	return rect.size.x if side % 2 == 0 else rect.size.y


## Vrai si ce côté du rectangle est contre un voisin : sur la limite du terrain, sans rue. Un
## mur mitoyen n'a pas de fenêtre.
func _is_party_wall(rect: Rect2, side: int) -> bool:
	return _street(side) <= 0.0 and _setback_from(_lot_rect(), rect, side) < 0.01


## Distance, le long de la façade, entre le bout gauche de ce côté du rectangle et le bout
## gauche du même côté du terrain.
func _column_offset(rect: Rect2, side: int) -> float:
	var lot: Rect2 = _lot_rect()
	match side:
		0:
			return rect.position.x - lot.position.x
		1:
			return rect.position.y - lot.position.y
		2:
			return lot.end.x - rect.end.x
		_:
			return lot.end.y - rect.end.y


## Numéro, sur sa façade, de la première travée de ce côté du rectangle : les travées sont
## comptées depuis le bout gauche de la même façade du terrain. Les retraits se font par
## travées entières : une fenêtre garde son numéro de colonne d'un gradin à l'autre.
func _first_column(rect: Rect2, side: int) -> int:
	return roundi(_column_offset(rect, side) / bay_width)


## Monte un gradin : ses quatre façades, ses piliers d'angle, son noyau et son toit.
func _build_tier(tier: Tier, next: Tier) -> void:
	var rect: Rect2 = tier.rect
	for side: int in range(4):
		var frame: Transform3D = _face_frame(rect, side)
		var width: float = _face_width(rect, side)
		# Ce que le gradin du dessus couvre de cette façade, s'il monte dans son plan.
		var covered: Vector2 = _covered_span(tier, next, side)
		if _is_party_wall(rect, side):
			# Mur mitoyen : un mur plein de brique ordinaire, contre le voisin.
			_wall_run(frame, -0.5 * width, 0.5 * width, tier.base_y, tier.top_y, covered, _materials.brick)
		else:
			_build_face(frame, width, tier, side, covered)
#@ 13+
			_build_far_face(frame, width, tier, side, covered)
#@ 6+
		_build_corner(tier, side, next)

	# Le noyau : une boîte sombre, en retrait derrière les façades, qu'on aperçoit par les baies.
	var center: Vector2 = rect.get_center()
	var core_top: float = tier.top_y - ROOF_THICKNESS
	_mesh.box(Vector3(rect.size.x - 2.0 * CORE_INSET, core_top - tier.base_y, rect.size.y - 2.0 * CORE_INSET),
			Vector3(center.x, 0.5 * (tier.base_y + core_top), -center.y), _materials.core)
	# Le toit : une dalle posée sur les quatre murs. Le parapet la dépasse : c'est la terrasse
	# que le gradin du dessus, en retrait, laisse à l'air libre.
#@ 6-8
	_mesh.box(Vector3(rect.size.x - WALL_DEPTH, ROOF_THICKNESS, rect.size.y - WALL_DEPTH),
			Vector3(center.x, tier.top_y - 0.5 * ROOF_THICKNESS, -center.y), _materials.core)
#@ 9+
	_mesh.box(Vector3(rect.size.x - WALL_DEPTH, ROOF_THICKNESS, rect.size.y - WALL_DEPTH),
			Vector3(center.x, tier.top_y - 0.5 * ROOF_THICKNESS, -center.y), _materials.roofing)
#@ 6+
#@ 8+

	# Les profils : le chaperon de pierre sur le parapet, et le bandeau en gradins si le haut du
	# socle de pierre passe dans ce gradin.
	_build_copings(tier, next, _materials.stone, WALL_DEPTH, COPING_OVERHANG, COPING_HEIGHT)
	var stone_top: float = _stone_top()
	if stone_top > tier.base_y + 0.01 and stone_top < tier.top_y:
		_build_stepped_band(tier, stone_top)
#@ 6+


## Le gradin au-dessus du gradin « index », ou null pour le dernier.
func _tier_above(tiers: Array[Tier], index: int) -> Tier:
	if index + 1 < tiers.size():
		return tiers[index + 1]
	return null


## Ce que le gradin « next » couvre de la façade « side » de « tier », en abscisses du repère de
## cette façade : l'intervalle où il monte dans le même plan qu'elle, sans retrait. Là, le mur
## continue : pas de parapet, pas de chaperon. Vector2.ZERO : il ne couvre rien.
func _covered_span(tier: Tier, next: Tier, side: int) -> Vector2:
	if next == null:
		return Vector2.ZERO
	var lot: Rect2 = _lot_rect()
	if absf(_setback_from(lot, next.rect, side) - _setback_from(lot, tier.rect, side)) > 0.01:
		return Vector2.ZERO
	var center: Vector2 = tier.rect.get_center()
	var above: Rect2 = next.rect
	match side:
		0:
			return Vector2(above.position.x - center.x, above.end.x - center.x)
		1:
			return Vector2(above.position.y - center.y, above.end.y - center.y)
		2:
			return Vector2(center.x - above.end.x, center.x - above.position.x)
		_:
			return Vector2(center.y - above.end.y, center.y - above.position.y)


## Vrai si l'abscisse « x » de la façade est sous le gradin du dessus.
func _is_covered(covered: Vector2, x: float) -> bool:
	return covered.y > covered.x and x > covered.x - 0.001 and x < covered.y + 0.001


## Un pan de mur de la façade, de l'abscisse « x0 » à « x1 », du bas « bottom » jusqu'au haut du
## parapet, sauf sur l'intervalle « covered » : là, il s'arrête au toit, « roof », et le gradin
## du dessus prend le relais. Sans cela, deux murs dans le même plan se chevaucheraient sur la
## hauteur du parapet, et la carte graphique ne saurait pas lequel montrer.
func _wall_run(frame: Transform3D, x0: float, x1: float, bottom: float, roof: float, covered: Vector2, material: Material) -> void:
	var span: Vector2 = covered if covered.y > covered.x else Vector2(x1, x1)
	var cuts: Array[float] = [x0, clampf(span.x, x0, x1), clampf(span.y, x0, x1), x1]
	for index: int in range(3):
		var a: float = cuts[index]
		var b: float = cuts[index + 1]
		var top: float = roof if index == 1 else roof + PARAPET_HEIGHT
		if b - a < 0.001 or top - bottom < 0.001:
			continue
		_box_in(frame, Vector3(b - a + WALL_OVERLAP, top - bottom, WALL_DEPTH), Vector3(0.5 * (a + b), 0.5 * (bottom + top), -0.5 * WALL_DEPTH), material)


## Monte une façade de gradin dans le repère « frame » : des piliers, un bandeau sous chaque
## rangée de fenêtres, une fenêtre par travée et par étage, et un dernier bandeau jusqu'en
## haut du parapet. Là où le gradin du dessus continue la façade (« covered »), les piliers et
## le dernier bandeau s'arrêtent au toit.
func _build_face(frame: Transform3D, width: float, tier: Tier, side: int, covered: Vector2) -> void:
	var bays: int = _bays(width)
	var left: float = -0.5 * width + _margin(width)
	var top: float = tier.top_y + PARAPET_HEIGHT
	var pier: float = bay_width - _opening(1).x
	var first_column: int = _first_column(tier.rect, side)
#@ 6-9
	var bottom: float = tier.base_y
	var first_floor: int = tier.first_floor
#@ 10+
	# Le rez-de-chaussée a son propre script : la façade des étages commence au-dessus de lui.
	var ground: bool = tier.first_floor == 0
	var bottom: float = ground_height if ground else tier.base_y
	var first_floor: int = 1 if ground else tier.first_floor
#@ 13+
	# Les piliers, les bandeaux et les fenêtres : de près et à mi-distance. De loin, le rectangle
	# de la façade lointaine les remplace.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ 6+

	# Les piliers, du pied de la façade au haut du parapet (ou au toit, sous le gradin du
	# dessus) : en pierre jusqu'au haut du socle, en brique au-dessus. Une façade toute en brique
	# n'a qu'un morceau.
	for bay: int in range(1, bays):
		var x: float = left + float(bay) * bay_width
		var pier_top: float = tier.top_y if _is_covered(covered, x) else top
		var stone_top: float = clampf(_stone_top(), bottom, pier_top)
		for part: Vector2 in [Vector2(bottom, stone_top), Vector2(stone_top, pier_top)]:
			if part.y - part.x > 0.001:
				_box_in(frame, Vector3(pier, part.y - part.x, WALL_DEPTH + PIER_PROJECTION),
						Vector3(x, 0.5 * (part.x + part.y), 0.5 * (PIER_PROJECTION - WALL_DEPTH)), _wall_material(part.y))

	# Les étages. « head » est le haut des fenêtres de l'étage du dessous : le bandeau de cet
	# étage commence là.
	var head: float = bottom
	for index: int in range(first_floor, tier.first_floor + tier.floor_count):
		var size: Vector2 = _opening(index)
		var sill_y: float = _floor_y(index) + _sill(index)
		_box_in(frame, Vector3(width + WALL_OVERLAP, sill_y - head, WALL_DEPTH),
				Vector3(0.0, 0.5 * (head + sill_y), -0.5 * WALL_DEPTH), _wall_material(sill_y))
		# Les fenêtres. La donnée de l'instance dit au shader ce qu'il y a derrière (un bureau,
		# ou le hall du rez-de-chaussée), puis l'étage, la colonne et la façade : trois nombres
		# entiers qui font la clé de tirage de la fenêtre.
		var kind: float = KIND_LOBBY if index == 0 else KIND_OFFICE
#@ 13+
		# Une fenêtre au fond de sa baie ne porte pas d'ombre : elle ne tomberait sur rien.
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ 6+
		for bay: int in range(bays):
			var center: Vector3 = Vector3(left + (float(bay) + 0.5) * bay_width, sill_y + 0.5 * size.y, -WINDOW_RECESS)
			_mesh.panel(size, frame * Transform3D(Basis.IDENTITY, center), _materials.window,
					Color(kind, float(index), float(first_column + bay), float(side)))
#@ 13+
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ 6+
		head = sill_y + size.y
	# Le dernier bandeau, du haut des dernières fenêtres jusqu'en haut du parapet.
	_wall_run(frame, -0.5 * width, 0.5 * width, head, tier.top_y, covered, _wall_material(top))
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 6+
#@ 10+
	if ground:
		# Le rez-de-chaussée : l'entrée de la tour sur la façade de devant, des boutiques partout.
		GroundBuilder.masonry_face(_mesh, _materials, _random, frame, width, bay_width, pier, WALL_DEPTH, PIER_PROJECTION,
				ground_height, side, first_column, side == 0)
#@ 6+


## Pilier d'angle du gradin, au bout droit de la façade « side » : le coin qu'elle partage avec
## la façade suivante. Il couvre ce qui reste de mur au bout de chacune des deux façades, avant
## leur première fenêtre, et avance comme leurs piliers. Contre un mur mitoyen, il n'avance pas
## de ce côté-là ; entre deux murs mitoyens, il n'y a rien à faire.
func _build_corner(tier: Tier, side: int, above: Tier) -> void:
	var rect: Rect2 = tier.rect
	var next: int = (side + 1) % 4
	var party_a: bool = _is_party_wall(rect, side)
	var party_b: bool = _is_party_wall(rect, next)
	if party_a and party_b:
		return
	var pier: float = bay_width - _opening(1).x
	var width: float = _face_width(rect, side)
	# Ce que le pilier couvre de chaque façade, depuis le coin, et sa saillie devant chacune.
	var reach_a: float = WALL_DEPTH if party_a else _margin(width) + 0.5 * pier
	var reach_b: float = WALL_DEPTH if party_b else _margin(_face_width(rect, next)) + 0.5 * pier
	var out_a: float = 0.0 if party_a else PIER_PROJECTION
	var out_b: float = 0.0 if party_b else PIER_PROJECTION
	# Dans le repère de la façade « side », la façade suivante part du coin vers -z.
	var frame: Transform3D = _face_frame(rect, side)
	# Si le gradin du dessus garde les deux façades de cet angle, l'angle continue avec lui : le
	# pilier s'arrête au toit.
	var continued: bool = _covered_span(tier, above, side) != Vector2.ZERO and _covered_span(tier, above, next) != Vector2.ZERO
	var top: float = tier.top_y if continued else tier.top_y + PARAPET_HEIGHT
#@ 13+
	# De loin, les rectangles des deux façades se rejoignent à l'angle : le pilier ne sert que de
	# près et à mi-distance.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ 6+
#@ 6-9
	var bottom: float = tier.base_y
#@ 10+
	# Au rez-de-chaussée, ce sont les pilastres du script du rez-de-chaussée qui tiennent l'angle.
	var bottom: float = ground_height if tier.first_floor == 0 else tier.base_y
#@ 6+
	var stone_top: float = clampf(_stone_top(), bottom, top)
	for part: Vector2 in [Vector2(bottom, stone_top), Vector2(stone_top, top)]:
		if part.y - part.x <= 0.001:
			continue
		var size: Vector3 = Vector3(reach_a + out_b, part.y - part.x, reach_b + out_a)
		var center: Vector3 = Vector3(0.5 * width - reach_a + 0.5 * size.x, 0.5 * (part.x + part.y), out_a - 0.5 * size.z)
		_box_in(frame, size, center, _wall_material(part.y))
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 6+
#@ all
#@ 7+


# --- Tours de verre -------------------------------------------------------------

## Numéro du premier module de ce côté du rectangle, compté comme les colonnes de fenêtres.
func _first_module(rect: Rect2, side: int) -> int:
	return roundi(_column_offset(rect, side) / module_width)


## Monte un gradin de tour de verre : un mur-rideau par façade, un noyau sombre derrière, un
## toit. Contre un voisin, un mur mitoyen de brique.
func _build_glass_tier(tier: Tier) -> void:
	var rect: Rect2 = tier.rect
	var top: float = tier.top_y + PARAPET_HEIGHT
	var height: float = top - tier.base_y
	for side: int in range(4):
		var frame: Transform3D = _face_frame(rect, side)
		var width: float = _face_width(rect, side)
		if _is_party_wall(rect, side):
			_box_in(frame, Vector3(width + WALL_OVERLAP, height, WALL_DEPTH),
					Vector3(0.0, 0.5 * (tier.base_y + top), -0.5 * WALL_DEPTH), _materials.brick)
			continue
		# Le mur-rideau : un seul rectangle, de toute la largeur de la façade et de toute sa
		# hauteur, parapet compris. Le shader dessine le reste. La donnée de l'instance lui donne
		# le premier étage du rectangle, sa première colonne et sa façade : de quoi tirer chaque
		# bureau avec la même clé que derrière les fenêtres de la tour de brique.
#@ 13+
		# Il se voit à toute distance ; l'ombre, c'est le noyau qui la porte.
		_mesh.set_zones(MeshBuilder.ZONE_ALL, false)
#@ 7+
		_mesh.panel(Vector2(width, height), frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.5 * (tier.base_y + top), 0.0)),
				_materials.curtain, Color(float(tier.first_floor), float(_first_module(rect, side)), float(side), 0.0))
#@ 13+
		_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 7+
		# Le dos du parapet : un muret mince derrière le verre, qu'on voit depuis le toit.
		_box_in(frame, Vector3(width, PARAPET_HEIGHT, 0.12), Vector3(0.0, tier.top_y + 0.5 * PARAPET_HEIGHT, -0.08), _materials.core)

	# Le noyau : une boîte sombre juste derrière le verre. Le verre est opaque pour le moteur
	# (on voit les bureaux par le shader), mais le noyau porte les ombres et le toit.
	var center: Vector2 = rect.get_center()
	var core_top: float = tier.top_y - ROOF_THICKNESS
	_mesh.box(Vector3(rect.size.x - 2.0 * GLASS_CORE_INSET, core_top - tier.base_y, rect.size.y - 2.0 * GLASS_CORE_INSET),
			Vector3(center.x, 0.5 * (tier.base_y + core_top), -center.y), _materials.core)
#@ 7-8
	_mesh.box(Vector3(rect.size.x - 0.04, ROOF_THICKNESS, rect.size.y - 0.04),
			Vector3(center.x, tier.top_y - 0.5 * ROOF_THICKNESS, -center.y), _materials.core)
#@ 9+
	_mesh.box(Vector3(rect.size.x - 0.04, ROOF_THICKNESS, rect.size.y - 0.04),
			Vector3(center.x, tier.top_y - 0.5 * ROOF_THICKNESS, -center.y), _materials.roofing)
#@ 7+
#@ 8+

	# Les profils : un chaperon de métal sur le parapet ; des ailettes devant les meneaux de la
	# tour de 1961. La tour tout en verre n'en a pas : son verre affleure.
	_build_copings(tier, null, _materials.metal, 0.14, 0.04, 0.06)
	if family == FAMILY_GLASS_1961:
		_build_fins(tier)
#@ 10+
	# Au rez-de-chaussée, les portes tambour, au milieu de la façade de devant.
	if tier.first_floor == 0 and not _is_party_wall(rect, 0):
		GroundBuilder.glass_entrance(_mesh, _materials, _face_frame(rect, 0))
#@ 7+


## La place : un dallage de granit sur tout le terrain, au pied de la tour de verre. C'est la
## contrepartie du règlement de 1961 : la tour recule, la ville gagne une place.
func _build_plaza() -> void:
	var lot: Rect2 = _lot_rect()
	var center: Vector2 = lot.get_center()
	_mesh.box(Vector3(lot.size.x, PLAZA_THICKNESS, lot.size.y), Vector3(center.x, 0.5 * PLAZA_THICKNESS, -center.y), _materials.paving)
#@ 10+
	# Quatre jardinières de granit, plantées de buis, entre la rue et la tour, de part et d'autre
	# de l'allée qui mène à l'entrée.
	var tower: Rect2 = _glass_tower_rect(lot)
	var front: float = 0.5 * (lot.position.y + tower.position.y)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ 10+
	if tower.position.y - lot.position.y >= 6.0:
		for x: float in [-0.35, -0.2, 0.2, 0.35]:
			var spot: Vector3 = Vector3(tower.get_center().x + x * lot.size.x, PLAZA_THICKNESS, -front)
			_mesh.box(Vector3(3.0, 0.6, 1.2), spot + Vector3(0.0, 0.3, 0.0), _materials.stone)
			_mesh.box(Vector3(2.7, 0.5, 0.9), spot + Vector3(0.0, 0.85, 0.0), _materials.hedge)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 10+
#@ 7+
#@ 8+


# --- Profils -----------------------------------------------------------------------

## Chaperons : un profil extrudé le long de chaque façade du gradin, en haut du parapet. Il
## dépasse aux deux bouts de son débord : aux angles, les chaperons des deux façades se croisent
## et couvrent le coin. Là où le gradin du dessus « next » continue la façade, il n'y a pas de
## parapet, donc pas de chaperon.
func _build_copings(tier: Tier, next: Tier, material: Material, thickness: float, overhang: float, height: float) -> void:
	var top: float = tier.top_y + PARAPET_HEIGHT
	var profile: PackedVector2Array = Profiles.coping(thickness, overhang, height)
	for side: int in range(4):
		var frame: Transform3D = _face_frame(tier.rect, side)
		var half: float = 0.5 * _face_width(tier.rect, side)
		var covered: Vector2 = _covered_span(tier, next, side)
		# Les morceaux de la façade qui gardent leur parapet : tout, ou ce qui dépasse du gradin
		# du dessus, de chaque côté.
		var runs: Array[Vector2] = [Vector2(-half - overhang, half + overhang)]
		if covered.y > covered.x:
			runs = [Vector2(-half - overhang, covered.x), Vector2(covered.y, half + overhang)]
		for run: Vector2 in runs:
			if run.y - run.x < 0.01:
				continue
			# along_x() : le repère d'une moulure qui court le long de x, saillie vers +Z. Composé
			# avec celui de la façade, il la fait courir le long de la façade, vers le dehors.
#@ 8-12
			_mesh.extrude(profile, frame * MeshBuilder.along_x(Vector3(0.5 * (run.x + run.y), top, 0.0)), run.y - run.x, material)
#@ 13+
			# De près, le profil ; au-delà, une boîte de la même taille : même silhouette.
			_mesh.set_zones(MeshBuilder.ZONE_NEAR)
			_mesh.extrude(profile, frame * MeshBuilder.along_x(Vector3(0.5 * (run.x + run.y), top, 0.0)), run.y - run.x, material)
			_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
			var deep: float = thickness + 2.0 * overhang
			_box_in(frame, Vector3(run.y - run.x, height, deep), Vector3(0.5 * (run.x + run.y), top + 0.5 * height, overhang - 0.5 * deep), material)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 8+


## Bandeau en gradins à la hauteur « y », sur chaque façade du gradin qui n'est pas mitoyenne.
## Il avance plus que les piliers. À un angle, il dépasse de sa saillie pour rejoindre celui de
## la façade voisine, sauf du côté d'un mur mitoyen.
func _build_stepped_band(tier: Tier, y: float) -> void:
	var profile: PackedVector2Array = Profiles.stepped_band(BAND_HEIGHT, BAND_DEPTH)
	for side: int in range(4):
		if _is_party_wall(tier.rect, side):
			continue
		# Le bout gauche d'une façade touche la façade précédente ; le bout droit, la suivante.
		var left_out: float = 0.0 if _is_party_wall(tier.rect, (side + 3) % 4) else BAND_DEPTH
		var right_out: float = 0.0 if _is_party_wall(tier.rect, (side + 1) % 4) else BAND_DEPTH
		var length: float = _face_width(tier.rect, side) + left_out + right_out
		var frame: Transform3D = _face_frame(tier.rect, side)
#@ 8-12
		_mesh.extrude(profile, frame * MeshBuilder.along_x(Vector3(0.5 * (right_out - left_out), y, 0.0)), length, _materials.stone)
#@ 13+
		_mesh.set_zones(MeshBuilder.ZONE_NEAR)
		_mesh.extrude(profile, frame * MeshBuilder.along_x(Vector3(0.5 * (right_out - left_out), y, 0.0)), length, _materials.stone)
		_mesh.set_zones(MeshBuilder.ZONE_MID | MeshBuilder.ZONE_FAR)
		_box_in(frame, Vector3(length, BAND_HEIGHT, BAND_DEPTH), Vector3(0.5 * (right_out - left_out), y + 0.5 * BAND_HEIGHT, 0.5 * BAND_DEPTH), _materials.stone)
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 8+


## Ailettes : un profilé en T devant chaque meneau, de toute la hauteur du gradin, parapet
## compris. Les meneaux tombent tous les « unit » mètres, là où le shader du mur-rideau les
## dessine : on refait ici le même calcul que lui.
func _build_fins(tier: Tier) -> void:
	var profile: PackedVector2Array = Profiles.fin(FIN_DEPTH, FIN_FLANGE)
	var top: float = tier.top_y + PARAPET_HEIGHT
	for side: int in range(4):
		if _is_party_wall(tier.rect, side):
			continue
		var frame: Transform3D = _face_frame(tier.rect, side)
		var width: float = _face_width(tier.rect, side)
		var modules: int = maxi(1, roundi(width / module_width))
		var unit: float = width / float(modules)
		# Le repère de l'extrusion : x, la saillie vers le dehors ; y, la largeur le long de la
		# façade ; z, l'axe d'extrusion, vers le haut.
		var fin_basis: Basis = Basis(frame.basis.z, frame.basis.x, frame.basis.y)
#@ 13+
		# Les ailettes : de près et à mi-distance, sans ombre ; de loin, le shader dessine les
		# meneaux, et vingt centimètres de saillie ne se voient plus.
		_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID, false)
#@ 8+
		for index: int in range(1, modules):
			var origin: Vector3 = frame * Vector3(-0.5 * width + float(index) * unit, 0.5 * (tier.base_y + top), 0.0)
			_mesh.extrude(profile, Transform3D(fin_basis, origin), top - tier.base_y, _materials.metal)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 8+


## La marquise : un auvent au milieu de la façade de devant, au-dessus de l'entrée, tenu par
## deux tirants accrochés plus haut dans le mur. Bronze sur la tour de brique, métal clair sur
## les tours de verre.
func _build_marquee(tiers: Array[Tier]) -> void:
	if tiers.is_empty():
		return
	var frame: Transform3D = _face_frame(tiers[0].rect, 0)
	var brick: bool = family == FAMILY_BRICK
	var material: Material = _materials.metal
	if brick:
		material = _materials.bronze
	# Sur la tour de brique, la marquise part du nu des piliers, juste au-dessus des grandes
	# baies du rez-de-chaussée ; sur une tour de verre, du verre, à quatre mètres.
	var wall: float = PIER_PROJECTION if brick else 0.0
	var bottom: float = ground_height - GROUND_LINTEL + 0.15 if brick else 4.0
	var size: Vector3 = MARQUEE_SIZE
#@ 13+
	# La marquise, de près et à mi-distance ; ses tirants et son numéro, de près seulement.
	_mesh.set_zones(MeshBuilder.ZONE_NEAR | MeshBuilder.ZONE_MID)
#@ 8+
	_box_in(frame, size, Vector3(0.0, bottom + 0.5 * size.y, wall + 0.5 * size.z), material)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_NEAR, false)
#@ 8+
	# Les deux tirants : de l'avant de la marquise jusqu'au mur, 2,50 m plus haut.
	for end: float in [-1.0, 1.0]:
		var x: float = end * (0.5 * size.x - 0.4)
		var start: Vector3 = frame * Vector3(x, bottom + size.y, wall + size.z - 0.2)
		var finish: Vector3 = frame * Vector3(x, bottom + size.y + 2.5, wall)
		_rod(start, finish, 0.03, material)
#@ 10+
	# Le numéro de la tour, sur le devant de la marquise : à Manhattan, beaucoup de tours se
	# désignent par leur adresse, un numéro dans la rue ou l'avenue. Il est tiré au sort.
	var number: Label3D = Label3D.new()
	number.text = str(_random.randi_range(1, 999))
	number.font_size = GroundBuilder.FONT_SIZE
	number.pixel_size = 0.24 / float(GroundBuilder.FONT_SIZE)
	number.modulate = Color(0.95, 0.85, 0.6) if brick else Color(0.95, 0.95, 0.95)
	number.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	number.transform = frame * Transform3D(Basis.IDENTITY, Vector3(0.0, bottom + 0.5 * size.y, wall + size.z + 0.005))
	_mesh.node(number)
#@ 13+
	_mesh.set_zones(MeshBuilder.ZONE_ALL)
#@ 10+
#@ 8+


## Une barre ronde de rayon « radius » entre les points « a » et « b » : un cylindre (un cône à
## deux rayons égaux) dont l'axe y est tourné vers b - a.
func _rod(a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var axis: Vector3 = (b - a).normalized()
	var side: Vector3 = axis.cross(Vector3.FORWARD if absf(axis.z) < 0.9 else Vector3.RIGHT).normalized()
	_mesh.cone(0.5 * (a + b), radius, radius, a.distance_to(b), material, Basis(side, axis, side.cross(axis)), 6)
#@ 9+


# --- Couronnement --------------------------------------------------------------------

## Le couronnement, sur le toit du dernier gradin, selon la famille ; puis les projecteurs qui
## l'éclairent la nuit, et le château d'eau de la tour de brique.
func _build_crown(tiers: Array[Tier]) -> void:
	var last: Tier = tiers.back()
	var peak: float = last.top_y
	match family:
		FAMILY_BRICK:
			peak = CrownBuilder.brick_crown(_mesh, _materials, last.rect, last.top_y, crown, bay_width, floor_height)
			if water_tank:
				_place_water_tank(tiers)
		FAMILY_GLASS_1961:
			peak = CrownBuilder.louvred_screen(_mesh, _materials, last.rect, last.top_y, floor_height)
		_:
			peak = CrownBuilder.glass_crown(_mesh, _materials, last.rect, last.top_y, GLASS_CROWN_STOREYS * floor_height)
	# Les projecteurs sont au pied du couronnement et l'éclairent jusqu'à son sommet.
	_materials.set_floodlights(last.top_y, peak - last.top_y, 1.2 if crown_lights else 0.0)
	_materials.crown_glass.set_shader_parameter("crown_energy", 2.2 if crown_lights else 0.0)


## Le château d'eau : sur la terrasse la plus large que la tour laisse autour d'elle, au milieu
## de cette terrasse. Sans terrasse assez large, sur le toit de la tour, s'il est plat.
func _place_water_tank(tiers: Array[Tier]) -> void:
	var tower_index: int = -1
	for index: int in range(tiers.size()):
		if tiers[index].tower:
			tower_index = index
			break
	var spot: Vector2 = Vector2.ZERO
	var floor_y: float = -1.0
	if tower_index > 0:
		var below: Rect2 = tiers[tower_index - 1].rect
		var tower: Rect2 = tiers[tower_index].rect
		# Largeur de la terrasse de chaque côté : devant, à droite, derrière, à gauche.
		var widths: Array[float] = [tower.position.y - below.position.y, below.end.x - tower.end.x,
				below.end.y - tower.end.y, tower.position.x - below.position.x]
		var best: int = 0
		for side: int in range(1, 4):
			if widths[side] > widths[best]:
				best = side
		if widths[best] >= TANK_TERRACE:
			# Au milieu de la bande de terrasse, à mi-longueur de la tour.
			var middle: Vector2 = tower.get_center()
			match best:
				0:
					spot = Vector2(middle.x, below.position.y + 0.5 * widths[0])
				1:
					spot = Vector2(tower.end.x + 0.5 * widths[1], middle.y)
				2:
					spot = Vector2(middle.x, tower.end.y + 0.5 * widths[2])
				_:
					spot = Vector2(below.position.x + 0.5 * widths[3], middle.y)
			floor_y = tiers[tower_index - 1].top_y
	if floor_y < 0.0 and crown == CrownBuilder.CROWN_FLAT:
		# Sur le toit de la tour, dans un coin.
		var top: Tier = tiers.back()
		spot = top.rect.position + Vector2(4.0, 4.0)
		floor_y = top.top_y
	if floor_y < 0.0:
		return
	CrownBuilder.water_tank(_mesh, _materials, Vector3(spot.x, floor_y, -spot.y))
	_materials.set_tank_base(floor_y + CrownBuilder.TANK_STAND + 0.2)
#@ 11+


# --- La graine ---------------------------------------------------------------------

## Les choix laissés à la graine, tirés toujours dans le même ordre : la famille, le
## couronnement, les petits bois, les proportions, les teintes. Ce dé-ci est à part : la tour
## peut refaire ses choix à tout moment (le test le fait, pour lire son règlement) sans
## déranger le dé des boutiques. Tous les dés sont lancés, même ceux dont on n'a pas besoin :
## fixer un choix à la main ne décale pas les tirages suivants.
func _resolve() -> void:
	var dice: RandomNumberGenerator = RandomNumberGenerator.new()
	dice.seed = hash(variation_seed)
	# La famille : la brique un peu moins d'une fois sur deux, 1961 une fois sur cinq, le tout en
	# verre le reste du temps.
	var roll: float = dice.randf()
	var drawn: int = FAMILY_BRICK if roll < 0.45 else (FAMILY_GLASS_1961 if roll < 0.67 else FAMILY_ALL_GLASS)
	family = drawn if family_choice == 0 else family_choice - 1
	# Dans les listes de l'inspecteur, la première ligne est « Selon la graine » : on compte à
	# partir de 1, puis on revient aux numéros du script, qui comptent à partir de 0.
	crown = _pick(dice, crown_choice, 4) - 1
	_lights = _pick(dice, window_lights, Palette.WINDOW_LIGHTS.size()) - 1
	# Les proportions.
	var setbacks: int = dice.randi_range(2, 4)
	var share: float = dice.randf_range(0.16, 0.25)
	var glass_share: float = dice.randf_range(0.25, 0.4)
	var podium: int = [0, 0, 3, 5][dice.randi_range(0, 3)]
	var floors: int = roundi(float(floor_count) * dice.randf_range(0.75, 1.25))
	_setback_bays = setbacks if random_massing else setback_bays
	_tower_share = share if random_massing else tower_share
	_glass_share = glass_share if random_massing else glass_tower_share
	_podium = podium if random_massing else podium_floors
	_floor_count = floors if random_massing else floor_count
	# Les teintes.
	var brick: Color = Palette.BRICK_COLORS[dice.randi_range(0, Palette.BRICK_COLORS.size() - 1)]
	var stone: Color = Palette.STONE_COLORS[dice.randi_range(0, Palette.STONE_COLORS.size() - 1)]
	var frame: Color = Palette.FRAME_COLORS[dice.randi_range(0, Palette.FRAME_COLORS.size() - 1)]
	var glass: PackedColorArray = PackedColorArray(Palette.GLASS_SETS[dice.randi_range(0, Palette.GLASS_SETS.size() - 1)])
	var tint: Color = glass[0]
	var spandrel: Color = glass[1]
	var metal: Color = glass[2]
	_brick_color = brick if random_colors else brick_color
	_stone_color = stone if random_colors else stone_color
	_frame_color = frame if random_colors else frame_color
	_glass_tint = tint if random_colors else glass_tint
	_spandrel_color = spandrel if random_colors else spandrel_color
	_metal_color = metal if random_colors else metal_color


## Choix d'une liste dont la première ligne est « Selon la graine ». 0 : on garde le tirage,
## entre 1 et « count ». Sinon : on garde le choix. Le dé est lancé dans les deux cas.
func _pick(dice: RandomNumberGenerator, choice: int, count: int) -> int:
	var drawn: int = dice.randi_range(1, count)
	return choice if choice > 0 else drawn
#@ 13+


# --- Niveaux de détail et occultation ----------------------------------------------------

## De loin : toute la façade du gradin sur un seul rectangle, que le shader de la façade
## lointaine dessine (le mur, la grille des fenêtres, les fenêtres allumées). Il remplace, au-delà
## de la distance lointaine, les piliers, les bandeaux, les fenêtres instanciées et le
## rez-de-chaussée. Il est posé au nu des piliers, du pied du gradin à son toit ; le parapet
## reste un pan de brique, là où le gradin du dessus ne continue pas la façade.
func _build_far_face(frame: Transform3D, width: float, tier: Tier, side: int, covered: Vector2) -> void:
	_mesh.set_zones(MeshBuilder.ZONE_FAR, false)
	# La donnée de l'instance : le premier étage, la première colonne, la façade, et la marge de
	# mur au bout de la façade, avant la première travée. La teinte de l'instance porte de quoi
	# retrouver les coordonnées du shader de la brique : l'abscisse du bord gauche du rectangle le
	# long du mur (l'axe x du repère de la façade), et la hauteur de son pied.
	var left_edge: float = frame.origin.dot(frame.basis.x) - 0.5 * width
	_mesh.panel(Vector2(width, tier.top_y - tier.base_y), frame * Transform3D(Basis.IDENTITY, Vector3(0.0, 0.5 * (tier.base_y + tier.top_y), PIER_PROJECTION)),
			_materials.far_facade, Color(float(tier.first_floor), float(_first_column(tier.rect, side)), float(side), _margin(width)),
			Color(left_edge, tier.base_y, 0.0, 1.0))
	# Le parapet : un pan de brique au-dessus du toit, sauf sous le gradin du dessus.
	_mesh.set_zones(MeshBuilder.ZONE_FAR)
	_wall_run(frame, -0.5 * width, 0.5 * width, tier.top_y, tier.top_y, covered, _wall_material(tier.top_y + PARAPET_HEIGHT))
	_mesh.set_zones(MeshBuilder.ZONE_ALL)


## Une boîte d'occultation pour ce gradin, un peu plus petite que lui : elle ne cache jamais ce
## qui dépasse de ses façades. Le moteur dessine ces boîtes sur le processeur, dans une petite
## image de profondeur, et ne dessine pas ce qu'elles cachent entièrement : derrière une tour,
## les tours de l'avenue suivante ne coûtent rien. Il faut que le réglage du projet
## « rendering/occlusion_culling/use_occlusion_culling » soit vrai.
func _add_occluder(tier: Tier) -> void:
	var box: BoxOccluder3D = BoxOccluder3D.new()
	box.size = Vector3(tier.rect.size.x - 1.0, tier.top_y - tier.base_y, tier.rect.size.y - 1.0)
	var occluder: OccluderInstance3D = OccluderInstance3D.new()
	occluder.occluder = box
	var center: Vector2 = tier.rect.get_center()
	occluder.position = Vector3(center.x, 0.5 * (tier.base_y + tier.top_y), -center.y)
	_root.add_child(occluder)
