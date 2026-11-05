class_name FlatLayout
extends RefCounted
## La pose d'un sprite à plat sur le sol, en calcul pur, partagée par le jeu et l'éditeur. Chaque chose est un quad
## couché (tourné de -90° autour de x), tourné de sa rotation autour de la verticale, à la taille de son asset. L'ordre
## de dessin devient une hauteur : chaque calque monte d'un cran, chaque rang d'un cran plus petit ; vu par la caméra
## inclinée, le plus haut passe devant. Les crans sont assez fins pour ne pas se voir à l'écran.
#@ 17+
## Une pièce peinte en projection (`AssetDef.painted`) se couche aussi, à la même hauteur, mais ses axes suivent ceux de
## l'écran ramenés au sol (`painted_basis`) : vue par la caméra orthographique du jeu, elle apparaît telle qu'elle est
## peinte, sans être projetée une seconde fois.
#@ all

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
#@ 17+


## Le déplacement au sol (x, z), en mètres, que la caméra `camera` montre comme `screen_m` mètres de l'écran (vers la
## droite, vers le bas). La droite de l'écran est horizontale : elle suit le sol mètre pour mètre. Le bas de l'écran
## descend vers la caméra : un mètre d'écran y couvre 1 / sin(inclinaison) mètres de sol (2 m à 30°).
static func ground_from_screen(camera: CameraDef, screen_m: Vector2) -> Vector2:
	var yaw: float = deg_to_rad(camera.yaw_deg)
	var right: Vector2 = Vector2(cos(yaw), -sin(yaw))
	var toward_camera: Vector2 = Vector2(sin(yaw), cos(yaw))
	return right * screen_m.x + toward_camera * (screen_m.y / sin(deg_to_rad(camera.pitch_deg)))


## L'orientation d'une pièce peinte en projection : couchée sur le sol, mais étirée et cisaillée pour que la caméra
## `camera` la voie telle qu'elle est peinte ; tournée de `rotation_deg` dans le plan de l'écran, à l'échelle `scale`
## (et la hauteur de l'image multipliée par `ratio`). Les axes de l'image vont au sol par `ground_from_screen` ; la
## normale reste la verticale.
static func painted_basis(camera: CameraDef, rotation_deg: float, scale: float, ratio: float) -> Basis:
	var turn: float = deg_to_rad(rotation_deg)
	var across: Vector2 = ground_from_screen(camera, Vector2.RIGHT.rotated(turn)) * scale
	# Le haut de l'image (+y du sprite) est le haut de l'écran.
	var up: Vector2 = ground_from_screen(camera, Vector2.UP.rotated(turn)) * (scale * ratio)
	return Basis(Vector3(across.x, 0.0, across.y), Vector3(up.x, 0.0, up.y), Vector3.UP)
#@ all
