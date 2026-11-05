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
#@ 7+
## La couleur du cadre de sélection et de ses poignées.
@export var selection_color: Color = Color(0.2, 0.55, 1.0)
## Le côté d'une poignée, en pixels.
@export var handle_size_px: float = 10.0
## La distance entre le haut du cadre et la poignée de rotation, en pixels.
@export var rotate_handle_offset_px: float = 28.0
## Le déplacement de la souris, en pixels, au-delà duquel un clic devient un glisser.
@export var drag_threshold_px: float = 4.0
#@ 10+
## Le rayon autour d'un sommet ou d'un côté de collision où un clic le prend, en pixels.
@export var point_pick_px: float = 8.0
## Le côté d'une forme de collision neuve (Ctrl+clic), en mètres.
@export var collision_square_m: float = 2.0
#@ 15+
## La vitesse de marche du modèle sur le banc d'essai, en mètres par seconde.
@export var bench_move_speed_mps: float = 3.0
## La distance entre la caméra du banc et le modèle, en mètres.
@export var bench_camera_distance_m: float = 6.0
## Le côté du sol du banc, en mètres.
@export var bench_floor_m: float = 20.0
#@ 16+
## La taille d'une salle neuve, en mètres.
@export var new_room_size_m: Vector2 = Vector2(24, 16)
#@ 18+
## Le nombre de pixels d'un mètre d'écran, au zoom 1, dans les planches peintes : une seule échelle pour toutes les
## pièces, qui se marient donc entre elles à la bonne taille (valeur proposée : 1 080 pixels de haut pour les 9 m que
## montre la caméra, à régler sur la grille de référence de laurent).
@export var painted_pixels_per_meter: float = 120.0
## L'écart, en pixels, sous lequel deux pièces d'une planche n'en font qu'une, mesuré entre leurs cadres (0 : seules
## les pièces qui se touchent).
@export var sheet_merge_gap_px: int = 0
## La surface, en pixels, sous laquelle un îlot d'une planche est une poussière, ignorée.
@export var sheet_min_area_px: int = 16
## La marge transparente autour de chaque pièce, dans une page d'atlas, en pixels (contre le filtrage qui bave).
@export var sheet_padding_px: int = 2
## Le côté le plus grand d'une page d'atlas, en pixels.
@export var sheet_page_max_px: int = 2048
## Vrai pour compresser les pages pour la mémoire vidéo (BPTC : un octet par pixel, quatre fois moins qu'en RGBA8) ;
## faux pour les garder sans perte (quatre octets par pixel).
@export var sheet_vram_compression: bool = true
## Le calque où l'éditeur pose une pièce importée.
@export var sheet_layer: StringName = &"sol"
## La catégorie d'une pièce importée, qui la range dans la palette.
@export var sheet_category: StringName = &"sol"
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
#@ 7+
	if handle_size_px <= 0.0 or rotate_handle_offset_px <= 0.0 or drag_threshold_px < 0.0:
		errors.append("poignées : tailles positives requises")
#@ 10+
	if point_pick_px <= 0.0 or collision_square_m <= 0.0:
		errors.append("collisions : rayon de prise et côté positifs requis")
#@ 15+
	if bench_move_speed_mps <= 0.0 or bench_camera_distance_m <= 0.0 or bench_floor_m <= 0.0:
		errors.append("banc d'essai : vitesse, distance et sol positifs requis")
#@ 16+
	if new_room_size_m.x <= 0.0 or new_room_size_m.y <= 0.0:
		errors.append("new_room_size_m : taille positive requise")
#@ 18+
	if painted_pixels_per_meter <= 0.0:
		errors.append("painted_pixels_per_meter : valeur positive requise")
	if sheet_merge_gap_px < 0 or sheet_min_area_px < 0 or sheet_padding_px < 0:
		errors.append("planches : écart, surface et marge positifs ou nuls requis")
	if sheet_page_max_px < SheetImporter.BLOCK_PX:
		errors.append("sheet_page_max_px : au moins un bloc de compression requis")
#@ all
	return errors
