class_name FlatLayout
extends RefCounted
## La pose d'un sprite à plat sur le sol, en calcul pur, partagée par le jeu et l'éditeur. Chaque chose est un quad
## couché (tourné de -90° autour de x), tourné de sa rotation autour de la verticale, à la taille de son asset. L'ordre
## de dessin devient une hauteur : chaque calque monte d'un cran, chaque rang d'un cran plus petit ; vu par la caméra
## inclinée, le plus haut passe devant. Les crans sont assez fins pour ne pas se voir à l'écran.

## L'écart de hauteur entre deux calques, en mètres.
const LAYER_STEP_M: float = 0.05
## L'écart de hauteur entre deux rangs d'un calque, en mètres : cinquante rangs de part et d'autre tiennent dans un
## demi-cran de calque, si bien qu'un calque plus haut passe toujours au-dessus, quels que soient les rangs.
const SORT_STEP_M: float = 0.0005


## La hauteur de pose d'une chose : sa hauteur propre, plus les crans de son calque et de son rang.
static func height(layer_index: int, sort: int, height_m: float) -> float:
	return height_m + maxi(layer_index, 0) * LAYER_STEP_M + sort * SORT_STEP_M


## La taille d'un pixel de l'asset, en mètres : sa largeur en jeu divisée par sa largeur dans la planche.
static func pixel_size(asset: AssetDef) -> float:
	return asset.size_m.x / maxf(asset.region.size.x, 1.0)


## Le rapport à appliquer à la profondeur du quad, pour qu'elle fasse `size_m.y` mètres quelle que soit l'image.
static func depth_ratio(asset: AssetDef) -> float:
	return asset.size_m.y / maxf(asset.region.size.y * pixel_size(asset), 0.0001)


## Le décalage du sprite, en pixels, qui pose son point d'ancrage sur la position de la chose.
static func offset(asset: AssetDef) -> Vector2:
	var size: Vector2 = Vector2(asset.region.size)
	return Vector2((0.5 - asset.anchor.x) * size.x, (asset.anchor.y - 0.5) * size.y)


## L'orientation d'une chose : couchée, tournée de `rotation_deg` autour de la verticale, à l'échelle `scale` (et la
## profondeur multipliée par `ratio`).
static func basis(rotation_deg: float, scale: float, ratio: float) -> Basis:
	return Basis(Vector3.UP, -deg_to_rad(rotation_deg)) * Basis(Vector3.RIGHT, -PI / 2.0) \
			* Basis.from_scale(Vector3(scale, scale * ratio, scale))
