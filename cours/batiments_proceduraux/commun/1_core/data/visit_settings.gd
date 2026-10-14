class_name VisitSettings
extends Resource
## Réglages de la visite des étapes : ciel, soleil et sol, jour et nuit, cadrage de la caméra,
## mesure du rendu et qualité. Ce sont des réglages de la visite, pas de l'immeuble : leurs
## valeurs vivent dans 5_data/visit/visit_settings.tres.

## Identifiant stable, en snake_case, jamais renommé.
@export var id: StringName

@export_group("Caméra")
## Champ de vision quand la scène de visite n'en donne pas, en degrés.
@export var camera_fov: float = 0.0
## Distance au-delà de laquelle la caméra ne dessine plus rien, en mètres.
@export var camera_far: float = 0.0
## Où la caméra se place quand rien ne se cadre (aucun nœud visité ne dessine).
@export var camera_position: Vector3 = Vector3.ZERO
@export var camera_target: Vector3 = Vector3.ZERO
## Cadrage automatique : de l'air autour de ce qu'on visite (1,3 : 30 % de distance en plus),
## un œil décalé sur le côté (part de la distance), à une hauteur d'au moins « eye_height » mètres
## ou d'une part de la hauteur du centre.
@export var frame_margin: float = 0.0
@export var frame_side_share: float = 0.0
@export var eye_height: float = 0.0
@export var eye_height_share: float = 0.0

@export_group("Soleil et ciel")
## Hauteur et azimut du soleil, en degrés.
@export var sun_angles: Vector2 = Vector2.ZERO
## Portée des ombres du soleil quand la scène de visite n'en donne pas, en mètres.
@export var shadow_distance: float = 0.0
@export var day_sky_top: Color = Color.BLACK
@export var day_sky_horizon: Color = Color.BLACK
@export var day_ground_bottom: Color = Color.BLACK
@export var day_ground_horizon: Color = Color.BLACK
@export var day_sun_color: Color = Color.BLACK
@export var day_sun_energy: float = 0.0
## Nuit : l'heure bleue, assez de lumière pour lire encore les façades.
@export var night_sky_top: Color = Color.BLACK
@export var night_sky_horizon: Color = Color.BLACK
@export var night_ground_bottom: Color = Color.BLACK
@export var night_ground_horizon: Color = Color.BLACK
@export var night_sun_color: Color = Color.BLACK
@export var night_sun_energy: float = 0.0
## Compatibilité additionne en sRGB la lumière des lampes à ombres : à réglages égaux, les surfaces
## éclairées y sortent bien plus claires qu'en Forward+ ou Mobile. La visite y garde une part du
## soleil (le jour, la nuit), et le réchauffe le jour.
@export var compatibility_sun_day: float = 0.0
@export var compatibility_sun_night: float = 0.0
@export var compatibility_day_sun_color: Color = Color.BLACK
## Halo autour des fenêtres éclairées, la nuit.
@export var glow_intensity: float = 0.0
@export var glow_bloom: float = 0.0

@export_group("Sol")
## Un trottoir devant la façade, puis la chaussée : taille, centre, teinte.
@export var sidewalk_size: Vector3 = Vector3.ZERO
@export var sidewalk_center: Vector3 = Vector3.ZERO
@export var sidewalk_color: Color = Color.BLACK
@export var road_size: Vector3 = Vector3.ZERO
@export var road_center: Vector3 = Vector3.ZERO
@export var road_color: Color = Color.BLACK
@export var ground_roughness: float = 0.0

@export_group("Rendu et mesure")
## Résolutions du rendu 3D que la touche R fait défiler, et la plus basse que « --scale » accepte.
@export var render_scales: Array[float] = []
@export var min_render_scale: float = 0.0
## Durée sur laquelle le compteur fait sa moyenne, en secondes.
@export var meter_period: float = 0.0
## Images écartées au début d'une mesure : elles compilent les shaders et remplissent les caches.
@export var warmup_frames: int = 0
## Images rendues avant une capture, le temps que les ombres et le ciel se stabilisent.
@export var capture_frames: int = 0

@export_group("Qualité")
## Les qualités que la touche P fait défiler, de la plus basse à la plus haute ; dans chaque
## tableau, une valeur par qualité.
@export var quality_names: PackedStringArray = []
## Portée des ombres du soleil, en part de « shadow_distance ».
@export var quality_shadow_shares: Array[float] = []
## Résolution du rendu 3D.
@export var quality_render_scales: Array[float] = []
## Au-dessus de cette durée par image, la visite baisse la qualité ; il faut plusieurs mesures
## lentes de suite, et les premières mesures sont ignorées (elles compilent les shaders).
@export var slow_frame_ms: float = 0.0
@export var slow_periods: int = 0
@export var startup_periods: int = 0
## Le dernier levier en qualité basse : rendre à cette résolution.
@export var last_resort_render_scale: float = 0.0


## Erreurs de la définition ; vide si elle est valide.
func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if String(id).is_empty():
		errors.append("%s : id vide" % resource_path)
	if camera_fov <= 0.0 or camera_far <= 0.0 or frame_margin <= 0.0:
		errors.append("%s : caméra (champ, portée, marge) attendue > 0" % resource_path)
	if shadow_distance <= 0.0 or meter_period <= 0.0 or capture_frames <= 0:
		errors.append("%s : portée des ombres, période de mesure et images de capture attendues > 0" % resource_path)
	if render_scales.is_empty() or min_render_scale <= 0.0:
		errors.append("%s : résolutions du rendu absentes" % resource_path)
	var count: int = quality_names.size()
	if count == 0 or quality_shadow_shares.size() != count or quality_render_scales.size() != count:
		errors.append("%s : une valeur par qualité attendue dans chaque tableau (%d qualités)" % [resource_path, count])
	return errors
