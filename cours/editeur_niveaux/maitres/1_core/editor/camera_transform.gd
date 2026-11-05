class_name CameraTransform
extends ViewProjection
## La projection de la caméra du jeu, en calcul pur : une caméra orthographique tournée de `yaw_deg` autour de la
## verticale (la vue en diagonale : les axes du sol partent en biais), puis inclinée de `pitch_deg` au-dessus du sol,
## qui regarde le point `focus` de la salle. Un point se projette sur les deux axes de l'écran de la caméra : sa droite
## (horizontale, tournée du lacet) et son haut (incliné). La même projection règle la `Camera3D` de la vue rendue
## (`apply_to`) : les tests vérifient que le calcul et Godot tombent au même pixel.

## Le point du sol que regarde la caméra (au centre de la vue).
var focus: Vector3 = Vector3.ZERO
var _settings: EditorSettingsDef
var _camera: CameraDef
var _view_size: Vector2 = Vector2.ONE


## Prend les réglages de l'éditeur (bornes du zoom) et la caméra du jeu `camera`.
func setup(settings: EditorSettingsDef, camera: CameraDef) -> void:
	_settings = settings
	_camera = camera


## Donne la taille de la vue, en pixels.
func resize(view_size: Vector2) -> void:
	_view_size = Vector2(maxf(view_size.x, 1.0), maxf(view_size.y, 1.0))
	notify_changed()


## La taille orthographique de la caméra : la hauteur montrée, en mètres.
func ortho_size() -> float:
	return _camera.view_height_m / zoom


## Le nombre de pixels d'un mètre, mesuré le long de la droite de l'écran.
func pixels_per_meter() -> float:
	return _view_size.y / ortho_size()


## L'orientation de la caméra : tournée du lacet autour de la verticale, puis inclinée.
func basis() -> Basis:
	return Basis(Vector3.UP, deg_to_rad(_camera.yaw_deg)) * Basis(Vector3.RIGHT, -deg_to_rad(_camera.pitch_deg))


## Le point de l'écran où se trouve `world`.
func world_to_screen(world: Vector3) -> Vector2:
	var axes: Basis = basis()
	var offset: Vector3 = world - focus
	return _view_size / 2.0 + Vector2(offset.dot(axes.x), -offset.dot(axes.y)) * pixels_per_meter()


## Le point du sol qui se trouve sous `screen`.
func screen_to_world(screen: Vector2) -> Vector3:
	return focus + _ground_offset((screen - _view_size / 2.0) / pixels_per_meter())


## Déplace la vue de `delta` pixels : le sol suit la souris.
func pan(delta: Vector2) -> void:
	focus -= _ground_offset(delta / pixels_per_meter())
	notify_changed()


## Multiplie le zoom par `factor`, dans les bornes des réglages, en gardant immobile le point du sol sous `screen`.
func zoom_at(screen: Vector2, factor: float) -> void:
	var anchor: Vector3 = screen_to_world(screen)
	zoom = clampf(zoom * factor, _settings.min_zoom, _settings.max_zoom)
	focus = anchor - _ground_offset((screen - _view_size / 2.0) / pixels_per_meter())
	notify_changed()


## Cadre la salle de taille `size_m` entière au milieu d'une vue de `view_size` pixels.
func frame(size_m: Vector2, view_size: Vector2) -> void:
	_view_size = Vector2(maxf(view_size.x, 1.0), maxf(view_size.y, 1.0))
	focus = Vector3(size_m.x / 2.0, 0.0, size_m.y / 2.0)
	var axes: Basis = basis()
	var extent: Vector2 = Vector2.ZERO
	for corner: Vector3 in [Vector3.ZERO, Vector3(size_m.x, 0, 0), Vector3(size_m.x, 0, size_m.y), Vector3(0, 0, size_m.y)]:
		var offset: Vector3 = corner - focus
		extent.x = maxf(extent.x, absf(offset.dot(axes.x)))
		extent.y = maxf(extent.y, absf(offset.dot(axes.y)))
	var fit: float = minf(_view_size.x / (2.0 * extent.x), _view_size.y / (2.0 * extent.y))
	zoom = clampf(fit * _camera.view_height_m / _view_size.y, _settings.min_zoom, _settings.max_zoom)
	notify_changed()


## Montre la salle comme le jeu : au zoom du jeu (1), centrée sur `world` (le départ du héros), dans une vue de
## `view_size` pixels. C'est la vue d'un roguelike, proche du héros ; la salle entière se voit sur la carte.
func show_like_game(world: Vector3, view_size: Vector2) -> void:
	_view_size = Vector2(maxf(view_size.x, 1.0), maxf(view_size.y, 1.0))
	zoom = 1.0
	focus = Vector3(world.x, 0.0, world.z)
	notify_changed()


## Centre la vue sur le point `world` du sol.
func center_on(world: Vector3) -> void:
	focus = Vector3(world.x, 0.0, world.z)
	notify_changed()


## Règle `camera` sur cette projection : orthographique, tournée, inclinée, placée en recul du point regardé.
func apply_to(camera: Camera3D) -> void:
	var axes: Basis = basis()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = ortho_size()
	camera.far = _camera.distance_m * 2.0
	camera.transform = Transform3D(axes, focus + axes.z * _camera.distance_m)


# Le déplacement au sol (y = 0) qui se voit, à l'écran, comme `screen_m` (en mètres de l'écran : droite, bas).
# L'écran voit le sol par deux axes : sa droite (horizontale) et son haut (incliné, dont la part au sol vaut sin(pitch)).
func _ground_offset(screen_m: Vector2) -> Vector3:
	var axes: Basis = basis()
	var right: Vector3 = Vector3(axes.x.x, 0.0, axes.x.z)
	var forward: Vector3 = Vector3(axes.z.x, 0.0, axes.z.z).normalized()
	return right * screen_m.x + forward * (screen_m.y / sin(deg_to_rad(_camera.pitch_deg)))
