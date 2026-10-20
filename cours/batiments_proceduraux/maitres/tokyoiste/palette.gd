extends RefCounted
## Données de conception de l'immeuble tokyoïte : les nombres des règlements et les listes où
## le hasard tire.
## {STATUS}
##
## Ce fichier ne contient aucun mécanisme : seulement des cotes, des noms et des teintes. Il
## vit dans « 5_data », pas à côté du code. On peut changer une pente de gabarit ou allonger
## une liste sans ouvrir un seul script de « 6_assets ».
##
## Les scripts le chargent par « preload » et lisent ses constantes :
##     const Palette := preload("res://5_data/…_palette.gd")
##     var slope: float = Palette.ROAD_SLOPES[1]

# --- Règlement --------------------------------------------------------------

## Gabarit oblique sur rue (dōro shasen, 道路斜線制限). Une ligne part de la limite OPPOSÉE de
## la voie et monte selon cette pente : l'immeuble doit rester dessous. Premier nombre : zones
## d'habitation. Second : les autres zones. Source : arrondissement d'Ōta, « 建物の高さについて
## の制限 », lu le 11 octobre 2026.
const ROAD_SLOPES: Array[float] = [1.25, 1.5]
## Recul minimal d'un étage en retrait : en dessous, la terrasse gagnée ne sert à rien. Ce
## nombre-là n'est pas un règlement, c'est un choix de conception.
const MIN_SETBACK: float = 1.0
## Profondeur minimale d'un étage : au-dessous, on ne le construit pas. Choix de conception.
const MIN_FLOOR_DEPTH: float = 4.0
#@ 10+

# --- Enseignes --------------------------------------------------------------

## Saillie maximale d'une enseigne en drapeau ou d'un store au-dessus de la voie, saillie
## maximale d'une enseigne murale, et hauteur minimale de leur point le plus bas. Ce sont les
## règles du Bureau des routes nationales de Tokyo pour les routes qu'il gère (« 占用許可申請
## の詳細 », lu le 11 octobre 2026) ; les autres voies ont leur propre gestionnaire.
const SIGN_MAX_PROJECTION: float = 1.0
const WALL_SIGN_MAX_PROJECTION: float = 0.3
const SIGN_MIN_CLEARANCE: float = 2.5

## Polices où chercher les caractères japonais, dans l'ordre. Les deux premières sont livrées
## avec Windows 11, la troisième s'y installe en supplément ; viennent ensuite macOS et Linux.
## Si aucune n'est trouvée, les enseignes affichent des carrés : passer alors la variable
## « japanese_signs » de l'immeuble à faux.
const SIGN_FONTS: PackedStringArray = ["Yu Gothic", "MS Gothic", "Meiryo", "Hiragino Sans", "Noto Sans CJK JP", "IPAGothic"]

## Sortes de boutique : un magasin (vitrine, rayonnages), un restaurant (bois, rideau d'entrée,
## lanterne), un service (vitrage, bureau).
const SHOP_STORE: int = 0
const SHOP_RESTAURANT: int = 1
const SHOP_SERVICE: int = 2

## Boutiques du rez-de-chaussée. Chaque ligne : le nom en japonais, le même en lettres latines,
## la sorte de boutique. Ce sont des noms communs (« pharmacie », « nouilles »), pas des marques.
const SHOPS: Array[Array] = [
	["居酒屋", "IZAKAYA", SHOP_RESTAURANT], ["ラーメン", "RAMEN", SHOP_RESTAURANT], ["そば", "SOBA", SHOP_RESTAURANT],
	["寿司", "SUSHI", SHOP_RESTAURANT], ["焼肉", "YAKINIKU", SHOP_RESTAURANT], ["とんかつ", "TONKATSU", SHOP_RESTAURANT],
	["定食", "TEISHOKU", SHOP_RESTAURANT], ["喫茶", "KISSA", SHOP_RESTAURANT],
	["薬局", "YAKKYOKU", SHOP_STORE], ["書店", "SHOTEN", SHOP_STORE], ["酒店", "SAKETEN", SHOP_STORE],
	["花屋", "HANAYA", SHOP_STORE], ["パン", "PAN", SHOP_STORE], ["時計店", "TOKEITEN", SHOP_STORE],
	["文具", "BUNGU", SHOP_STORE], ["青果", "SEIKA", SHOP_STORE], ["クリーニング", "CLEANING", SHOP_STORE],
	["不動産", "FUDOSAN", SHOP_SERVICE], ["美容室", "BIYOSHITSU", SHOP_SERVICE], ["歯科", "SHIKA", SHOP_SERVICE],
	["整骨院", "SEIKOTSUIN", SHOP_SERVICE], ["写真館", "SHASHINKAN", SHOP_SERVICE],
]
## Occupants des étages, pour les plaques de l'enseigne en drapeau : japonais, lettres latines.
const TENANTS: Array[Array] = [
	["スナック", "SNACK"], ["麻雀", "MAHJONG"], ["カラオケ", "KARAOKE"], ["バー", "BAR"], ["囲碁", "IGO"],
	["内科", "NAIKA"], ["歯科", "SHIKA"], ["英会話", "EIKAIWA"], ["鍼灸", "SHINKYU"], ["質", "SHICHI"],
	["会計", "KAIKEI"], ["学習塾", "JUKU"], ["整体", "SEITAI"], ["雀荘", "JANSO"], ["喫茶", "KISSA"], ["美容室", "BIYO"],
]
## Fonds des enseignes : blanc, jaune, rouge, bleu, vert, noir, orange, rose, crème.
const SIGN_COLORS: Array[Color] = [
	Color(0.93, 0.93, 0.90), Color(0.95, 0.80, 0.15), Color(0.80, 0.12, 0.10), Color(0.10, 0.25, 0.60),
	Color(0.10, 0.42, 0.25), Color(0.06, 0.06, 0.07), Color(0.92, 0.45, 0.10), Color(0.90, 0.45, 0.60),
	Color(0.90, 0.85, 0.70),
]
## Lettres d'enseigne : claires sur fond sombre, sombres sur fond clair.
const SIGN_PALE_INK: Color = Color(0.96, 0.95, 0.91)
const SIGN_DARK_INK: Color = Color(0.08, 0.07, 0.07)
## Peintures des rideaux métalliques : gris clair, ivoire, vert pâle, bleu pâle, brun.
const SHUTTER_COLORS: Array[Color] = [
	Color(0.72, 0.72, 0.70), Color(0.80, 0.77, 0.66), Color(0.55, 0.66, 0.60), Color(0.56, 0.64, 0.72),
	Color(0.36, 0.26, 0.20),
]
## Menuiseries et habillages des devantures : noir, bronze, blanc, bois sombre, bois clair.
const SHOP_FRAME_COLORS: Array[Color] = [
	Color(0.08, 0.08, 0.09), Color(0.30, 0.25, 0.20), Color(0.86, 0.86, 0.84), Color(0.22, 0.14, 0.09),
	Color(0.50, 0.36, 0.22),
]
## Toiles des rideaux d'entrée des restaurants (noren) : indigo, blanc cassé, rouge sombre, brun.
const NOREN_COLORS: Array[Color] = [
	Color(0.10, 0.14, 0.32), Color(0.90, 0.89, 0.85), Color(0.50, 0.10, 0.10), Color(0.30, 0.20, 0.12),
]
## Carrosseries des distributeurs de boissons : blanc, rouge, bleu.
const VENDING_COLORS: Array[Color] = [
	Color(0.90, 0.90, 0.88), Color(0.78, 0.10, 0.10), Color(0.12, 0.28, 0.62),
]
#@ 11+

# --- Façades ----------------------------------------------------------------

## Formats de carreaux de façade. Chaque ligne : taille du carreau joint compris (longueur,
## hauteur), puis décalage d'un rang sur deux (0.5 : joints croisés, 0 : joints alignés).
## Dans l'ordre : le carreau long (nichōgake, 227 × 60 mm), le court (koguchi, 108 × 60 mm),
## le petit (95 × 45 mm) et la mosaïque carrée (45 × 45 mm). Ces cotes sont citées de mémoire :
## à vérifier dans un catalogue de fabricant avant de s'y fier.
const TILE_FORMATS: Array[Array] = [
	[Vector2(0.235, 0.068), 0.5], [Vector2(0.116, 0.068), 0.5], [Vector2(0.100, 0.050), 0.0], [Vector2(0.050, 0.050), 0.0],
]
#@ 12+

# --- Rue --------------------------------------------------------------------

## Largeur minimale d'une voie au sens de la loi sur les normes de construction. Les ruelles
## plus étroites existent, mais on doit alors bâtir à 2 m de leur axe. Source : arrondissement
## d'Ōta, « 2項道路 », lu le 11 octobre 2026.
const MIN_ROAD_WIDTH: float = 4.0
## Distance qu'un immeuble doit garder avec la limite de sa parcelle (code civil japonais,
## article 234) : deux voisins qui s'y tiennent sont séparés du double, un mètre. Dans les
## quartiers classés contre l'incendie, un mur résistant au feu peut aller jusqu'à la limite :
## là, les immeubles se touchent presque. Cité par un géomètre-expert (smtrc.jp, questions sur
## les limites de propriété).
const BOUNDARY_DISTANCE: float = 0.5

## Teintes de façade où la rue tire, pour le carrelage comme pour l'enduit peint : du blanc
## au brun, puis des gris.
const TILE_COLORS: Array[Color] = [
	Color(0.86, 0.85, 0.80), Color(0.80, 0.78, 0.72), Color(0.74, 0.66, 0.55), Color(0.70, 0.52, 0.40),
	Color(0.55, 0.38, 0.28), Color(0.42, 0.30, 0.24), Color(0.62, 0.64, 0.65), Color(0.48, 0.55, 0.60),
	Color(0.30, 0.31, 0.33),
]
## Aluminium des menuiseries, où la rue tire aussi : anodisé naturel, bronze, noir, laqué blanc.
const FRAME_COLORS: Array[Color] = [
	Color(0.62, 0.63, 0.64), Color(0.30, 0.25, 0.20), Color(0.08, 0.08, 0.09), Color(0.86, 0.86, 0.84),
]
