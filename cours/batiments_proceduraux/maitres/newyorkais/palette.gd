@tool
extends RefCounted
## Les données de la tour new-yorkaise : les nombres des règlements de zonage.
## {STATUS}
##
## Pourquoi un fichier à part : ce ne sont pas des choix de code mais des données. Elles vivent
## dans « 5_data » ; le script de la tour les lit, il ne les invente pas. Chaque nombre dit
## d'où il vient.
##
## Unités : les règlements de New York comptent en pieds, le cours compte en mètres. Un pied
## vaut 0,3048 m exactement : les constantes ci-dessous sont écrites en pieds, puis converties.

## Un pied, en mètres.
const FOOT: float = 0.3048

# --- La trame de Manhattan ------------------------------------------------------
# Source : Museum of the City of New York, « The Greatest Grid », « The Commissioners' Plan,
# 1811 ». Rues transversales de 60 pieds, avenues de 100 pieds, îlots de 200 pieds du nord au
# sud.

## Largeur d'une rue transversale, puis d'une avenue.
const STREET_WIDTH: float = 60.0 * FOOT
const AVENUE_WIDTH: float = 100.0 * FOOT
## Profondeur d'un îlot, du nord au sud, d'une rue à l'autre.
const BLOCK_DEPTH: float = 200.0 * FOOT

# --- Le règlement de zonage de 1916 ------------------------------------------------
# Sources : Carol Willis, The Skyscraper Museum, « How the 1916 Zoning Law Shaped Manhattan's
# Central Business Districts » (2016) ; MCNY, « The Setback Principle of the 1916 Zoning Law ».

## Les cinq districts de hauteur : la façade sur rue monte droit jusqu'à ce multiple de la
## largeur de la rue. Au-delà, l'enveloppe est un plan incliné qui part de l'axe de la rue :
## dans un district « deux fois », un pied de retrait pour quatre pieds de hauteur.
const HEIGHT_MULTIPLES: Array[float] = [1.0, 1.25, 1.5, 2.0, 2.5]
## Une tour peut monter sans limite de hauteur si elle couvre au plus le quart du terrain.
const TOWER_SHARE_1916: float = 0.25
#@ 7+

# --- Le règlement de zonage de 1961, texte en vigueur (districts C5 et C6) ------------
# Source : Ville de New York, Zoning Resolution, sections 12-10, 33-122, 33-432, 33-451 et
# 33-454. Le règlement de 1961 ne dessine plus d'enveloppe pour la tour : il fixe une surface
# de planchers, une part du terrain et des distances aux rues.

## Une rue « large » mesure 75 pieds ou plus ; en dessous, elle est « étroite » (section 12-10).
const WIDE_STREET: float = 75.0 * FOOT
## Mur de façade du socle : 85 pieds ou six étages au plus (section 33-432).
const FRONT_WALL_MAX: float = 85.0 * FOOT
const FRONT_WALL_FLOORS: int = 6
## Tour (section 33-451) : à 15 pieds au moins d'une rue étroite, 10 pieds d'une rue large.
const TOWER_SETBACK_NARROW: float = 15.0 * FOOT
const TOWER_SETBACK_WIDE: float = 10.0 * FOOT
## Coefficient d'occupation des districts C5-3, C5-5, C6-6, C6-7 et C6-9 (section 33-122) :
## la surface de tous les planchers vaut au plus 15 fois celle du terrain.
const FLOOR_AREA_RATIO: float = 15.0


## Part du terrain qu'une tour peut couvrir (sections 33-451 et 33-454) : 40 % sur un terrain
## de 20 000 pieds carrés ou plus. Sur un terrain plus petit, la part grandit : 50 % jusqu'à
## 10 500 pieds carrés, puis un point de moins par tranche de 1 000 pieds carrés, et 41 % de
## 18 501 à 19 999.
static func tower_share_1961(lot_area: float) -> float:
	var square_feet: float = lot_area / (FOOT * FOOT)
	if square_feet >= 20000.0:
		return 0.40
	if square_feet <= 10500.0:
		return 0.50
	var bands: float = ceilf((square_feet - 10500.0) / 1000.0)
	return maxf(0.50 - 0.01 * bands, 0.41)
#@ 10+

# --- Le rez-de-chaussée -------------------------------------------------------------
# Des noms communs, en anglais, comme sur les enseignes de Manhattan ; aucun n'est celui d'une
# boutique réelle.

## Les sortes de boutiques (la pièce que le shader dessine derrière la vitrine), et des noms
## possibles pour chacune : une épicerie, un café, un magasin.
const SHOP_NAMES: Array[Array] = [
	["DELI", "GROCERY", "PHARMACY", "NEWSSTAND", "MARKET"],
	["COFFEE", "DINER", "BAKERY", "BAR & GRILL", "PIZZA"],
	["SHOES", "FLOWERS", "OPTICIAN", "BOOKS", "TAILOR", "JEWELRY"],
]
## Teintes des bandeaux d'enseigne : noir, vert bouteille, bordeaux, bleu nuit.
const FASCIA_COLORS: Array[Color] = [
	Color(0.08, 0.08, 0.09), Color(0.10, 0.20, 0.13), Color(0.32, 0.07, 0.07), Color(0.08, 0.12, 0.26),
]
#@ 11+

# --- Les tirages de la graine : teintes et petits bois -----------------------------------
# Des teintes plausibles, choisies à l'œil ; elles ne sont pas relevées sur des tours réelles.

## Briques : chamois, havane, rouge, brun, brun sombre.
const BRICK_COLORS: Array[Color] = [
	Color(0.78, 0.66, 0.50), Color(0.70, 0.55, 0.40), Color(0.62, 0.36, 0.26), Color(0.55, 0.40, 0.30), Color(0.40, 0.28, 0.22),
]
## Pierres du socle : calcaire clair, calcaire gris, granit rose.
const STONE_COLORS: Array[Color] = [Color(0.80, 0.77, 0.70), Color(0.70, 0.69, 0.66), Color(0.66, 0.55, 0.52)]
## Châssis des fenêtres : vert sombre, noir, blanc cassé, brun.
const FRAME_COLORS: Array[Color] = [
	Color(0.12, 0.18, 0.14), Color(0.08, 0.08, 0.08), Color(0.82, 0.80, 0.74), Color(0.25, 0.17, 0.12),
]
## Tours de verre : la teinte du verre, des allèges, du métal. Vert d'eau, bronze, gris bleu,
## argent.
const GLASS_SETS: Array[Array] = [
	[Color(0.62, 0.74, 0.72), Color(0.12, 0.15, 0.16), Color(0.62, 0.63, 0.64)],
	[Color(0.66, 0.58, 0.48), Color(0.16, 0.12, 0.09), Color(0.40, 0.30, 0.20)],
	[Color(0.58, 0.68, 0.78), Color(0.10, 0.13, 0.17), Color(0.72, 0.74, 0.76)],
	[Color(0.70, 0.72, 0.74), Color(0.14, 0.15, 0.16), Color(0.80, 0.80, 0.80)],
]
## Petits bois des fenêtres à guillotine : carreaux du châssis du haut, puis du bas (colonnes,
## rangées). Un sur un, deux sur deux, six sur six, trois sur un.
const WINDOW_LIGHTS: Array[Array] = [
	[Vector2i(1, 1), Vector2i(1, 1)],
	[Vector2i(2, 1), Vector2i(2, 1)],
	[Vector2i(3, 2), Vector2i(3, 2)],
	[Vector2i(3, 1), Vector2i(1, 1)],
]
#@ 12+

# --- La rue -----------------------------------------------------------------------
## Largeur d'un trottoir, prise dans la largeur de la rue : quinze pieds. Une cote plausible, pas
## relevée : les trottoirs de Manhattan varient d'une rue à l'autre.
const SIDEWALK_WIDTH: float = 15.0 * FOOT
