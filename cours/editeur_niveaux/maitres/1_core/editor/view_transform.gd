class_name ViewTransform
extends ViewProjection
## Le passage entre la salle (en mètres, plan x, z) et l'écran de la carte vue de dessus (en pixels). Un mètre fait
## `pixels_per_meter × zoom` pixels ; `origin` est l'endroit de l'écran où tombe le point (0, 0) de la salle. Le zoom
## à la molette garde immobile le point sous le curseur : c'est ce qu'attend la main. La vue de dessus sert de carte
## de navigation ; la vue où l'on édite est celle de la caméra du jeu (`CameraTransform`).

## La position, à l'écran, du point (0, 0) de la salle.
var origin: Vector2 = Vector2.ZERO
var _settings: EditorSettingsDef


## Prend les réglages (pixels par mètre, bornes du zoom, cran de molette).
func setup(settings: EditorSettingsDef) -> void:
	_settings = settings


## Le nombre de pixels d'un mètre, au zoom courant.
func pixels_per_meter() -> float:
	return _settings.pixels_per_meter * zoom


## Le point de l'écran où se trouve `world` (y, la hauteur, est ignoré : la vue regarde d'en haut).
func world_to_screen(world: Vector3) -> Vector2:
	return origin + Vector2(world.x, world.z) * pixels_per_meter()


## Le point de la salle, au sol, qui se trouve sous `screen`.
func screen_to_world(screen: Vector2) -> Vector3:
	var flat: Vector2 = (screen - origin) / pixels_per_meter()
	return Vector3(flat.x, 0.0, flat.y)


## Déplace la vue de `delta` pixels.
func pan(delta: Vector2) -> void:
	origin += delta
	notify_changed()


## Multiplie le zoom par `factor` (dans les bornes des réglages), en gardant immobile le point sous `screen`.
func zoom_at(screen: Vector2, factor: float) -> void:
	var anchor: Vector3 = screen_to_world(screen)
	zoom = clampf(zoom * factor, _settings.min_zoom, _settings.max_zoom)
	origin = screen - Vector2(anchor.x, anchor.z) * pixels_per_meter()
	notify_changed()


## Cadre la salle de taille `size_m` (en mètres) au milieu d'une vue de `view_size` pixels, au plus grand zoom qui la
## montre entière.
func frame(size_m: Vector2, view_size: Vector2) -> void:
	var fit: float = minf(view_size.x / size_m.x, view_size.y / size_m.y) / _settings.pixels_per_meter
	zoom = clampf(fit, _settings.min_zoom, _settings.max_zoom)
	origin = (view_size - size_m * pixels_per_meter()) / 2.0
	notify_changed()
