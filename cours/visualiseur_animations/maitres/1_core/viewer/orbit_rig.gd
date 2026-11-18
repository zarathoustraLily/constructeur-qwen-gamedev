class_name OrbitRig extends RefCounted
## La caméra qui tourne autour du sujet : un angle autour de la verticale (lacet), une hauteur (tangage), une distance
## et le point visé. Le sujet regarde +Z : au lacet 0, la caméra est devant lui ; à 90, de son côté gauche (+X).
## Deux vues :
## - la vue libre, en perspective, qu'on tourne et qu'on rapproche ;
## - la vue du jeu, orthographique, à l'inclinaison et à la rotation des réglages, à la taille du jeu : l'asset s'y
##   voit comme en partie. Tourner la caméra la quitte (elle repasse en vue libre) ; la vue du jeu ne bouge jamais.

## Le tangage le plus bas : un peu sous l'horizon, pour voir sous un ennemi volant.
const MIN_PITCH_DEG: float = -10.0
## Le tangage le plus haut : presque à la verticale (à 90, la caméra n'aurait plus de haut).
const MAX_PITCH_DEG: float = 85.0
## La distance la plus courte.
const MIN_DISTANCE: float = 0.5
## La distance la plus longue.
const MAX_DISTANCE: float = 60.0
## Le champ de vision vertical de la vue libre, en degrés.
const FOV_DEG: float = 40.0
## La marge autour du sujet quand on le cadre (1,2 : un cinquième de plus que sa taille).
const FRAME_MARGIN: float = 1.2

## Le lacet de la vue libre, en degrés, entre 0 et 360.
var yaw_deg: float = 0.0
## Le tangage de la vue libre, en degrés au-dessus de l'horizon.
var pitch_deg: float = 15.0
## La distance de la caméra au point visé, en mètres.
var distance: float = 5.0
## Le point visé.
var target: Vector3 = Vector3.ZERO
## Vrai en vue du jeu.
var game_view: bool = false
## L'inclinaison de la vue du jeu (ViewerConfig.game_pitch_deg).
var game_pitch_deg: float = 30.0
## La rotation de la vue du jeu (ViewerConfig.game_yaw_deg).
var game_yaw_deg: float = 45.0
## La hauteur vue en vue du jeu, en mètres (ViewerConfig.game_ortho_size).
var game_ortho_size: float = 8.0


## Prend la vue du jeu des réglages `config`.
func use_config(config: ViewerConfig) -> void:
	game_pitch_deg = config.game_pitch_deg
	game_yaw_deg = config.game_yaw_deg
	game_ortho_size = config.game_ortho_size


## Tourne de `d_yaw` degrés autour de la verticale et de `d_pitch` en hauteur ; quitte la vue du jeu.
func orbit(d_yaw: float, d_pitch: float) -> void:
	if game_view:
		yaw_deg = game_yaw_deg
		pitch_deg = game_pitch_deg
		game_view = false
	yaw_deg = fposmod(yaw_deg + d_yaw, 360.0)
	pitch_deg = clampf(pitch_deg + d_pitch, MIN_PITCH_DEG, MAX_PITCH_DEG)


## Rapproche (facteur < 1) ou éloigne (> 1) la vue libre ; ne change pas la vue du jeu, qui garde la taille du jeu.
func zoom(factor: float) -> void:
	if not game_view:
		distance = clampf(distance * factor, MIN_DISTANCE, MAX_DISTANCE)


## Vise le milieu de `box` et recule jusqu'à le voir en entier dans la vue libre.
func frame(box: AABB) -> void:
	target = box.get_center()
	var radius: float = maxf(box.size.length() * 0.5, 0.1)
	distance = clampf(radius * FRAME_MARGIN / sin(deg_to_rad(FOV_DEG) * 0.5), MIN_DISTANCE, MAX_DISTANCE)


## Le lacet de la vue en cours.
func view_yaw() -> float:
	return fposmod(game_yaw_deg, 360.0) if game_view else yaw_deg


## Le tangage de la vue en cours.
func view_pitch() -> float:
	return minf(game_pitch_deg, 89.9) if game_view else pitch_deg


## La direction du point visé vers la caméra.
func eye_direction() -> Vector3:
	var yaw: float = deg_to_rad(view_yaw())
	var pitch: float = deg_to_rad(view_pitch())
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))


## La place de la caméra : au point visé, reculée de `distance` (assez loin en vue du jeu pour ne rien couper).
func camera_transform() -> Transform3D:
	var direction: Vector3 = eye_direction()
	var reach: float = maxf(distance, game_ortho_size * 2.0) if game_view else distance
	return Transform3D(Basis.looking_at(-direction, Vector3.UP), target + direction * reach)


## Place `camera` et règle sa projection selon la vue en cours.
func apply(camera: Camera3D) -> void:
	camera.transform = camera_transform()
	if game_view:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = game_ortho_size
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = FOV_DEG
