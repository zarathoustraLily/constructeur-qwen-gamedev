class_name EditorSettingsDef
extends Resource
## Les réglages de l'éditeur (`5_data/editeur/reglages.tres`) : le pas de la grille, le pas de rotation, les bornes de
## l'échelle, le décalage d'un double. Ce sont des réglages de confort de l'éditeur, pas des valeurs du jeu.

## Identifiant des réglages.
@export var id: StringName = &"reglages_editeur"
## Le pas de la grille aimantée, en mètres.
@export var snap_m: float = 0.25
## Le pas de la rotation aimantée, en degrés.
@export var rotation_step_deg: float = 15.0
## L'échelle la plus petite qu'un geste peut donner.
@export var min_scale: float = 0.1
## L'échelle la plus grande qu'un geste peut donner.
@export var max_scale: float = 10.0
## Le décalage d'une chose dupliquée par rapport à l'original, en mètres.
@export var duplicate_offset_m: Vector3 = Vector3(0.5, 0, 0.5)
#@ 6+
## Le nombre de pixels d'un mètre, au zoom 1.
@export var pixels_per_meter: float = 32.0
## Le zoom le plus petit (la salle vue de loin).
@export var min_zoom: float = 0.25
## Le zoom le plus grand.
@export var max_zoom: float = 4.0
## Le facteur d'un cran de molette.
@export var zoom_step: float = 1.1
#@ all


## Les erreurs des réglages, une phrase par erreur ; vide s'ils sont valides.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if snap_m <= 0.0:
		errors.append("snap_m : pas positif requis")
	if rotation_step_deg <= 0.0:
		errors.append("rotation_step_deg : pas positif requis")
	if min_scale <= 0.0 or max_scale < min_scale:
		errors.append("min_scale, max_scale : 0 < min_scale <= max_scale requis")
#@ 6+
	if pixels_per_meter <= 0.0:
		errors.append("pixels_per_meter : valeur positive requise")
	if min_zoom <= 0.0 or max_zoom < min_zoom:
		errors.append("min_zoom, max_zoom : 0 < min_zoom <= max_zoom requis")
	if zoom_step <= 1.0:
		errors.append("zoom_step : facteur plus grand que 1 requis")
#@ all
	return errors
