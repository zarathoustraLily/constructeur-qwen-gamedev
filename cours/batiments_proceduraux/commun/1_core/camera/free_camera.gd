extends Camera3D
## Caméra libre, sans rien de propre à un niveau : elle vit dans « 1_core ».
##
## Elle ne lit ni le clavier ni la souris : free_camera_input.gd lui donne des intentions
## (tourner, se déplacer, aller vite), et elle avance au pas de la physique. Elle sait aussi se
## placer pour que tout un ensemble tienne dans l'image (frame_bounds).

const LOOK_SPEED: float = 0.003
const MOVE_SPEED: float = 6.0
const FAST_FACTOR: float = 4.0
const MAX_PITCH: float = 1.5

var _yaw: float = 0.0
var _pitch: float = 0.0
## Déplacement demandé : x vers la droite, y vers le haut, z vers l'arrière de la caméra.
var _move: Vector3 = Vector3.ZERO
var _fast: bool = false


## Commence à tourner : on repart de l'orientation courante, quelle que soit la façon dont elle
## a été fixée.
func begin_look() -> void:
	_yaw = rotation.y
	_pitch = rotation.x


## Tourne la caméra d'un déplacement de la souris, en pixels.
func look(relative: Vector2) -> void:
	_yaw -= relative.x * LOOK_SPEED
	_pitch = clampf(_pitch - relative.y * LOOK_SPEED, -MAX_PITCH, MAX_PITCH)
	rotation = Vector3(_pitch, _yaw, 0.0)


## Le déplacement voulu (chaque axe entre -1 et 1), et s'il faut aller vite.
func set_intent(move: Vector3, fast: bool) -> void:
	_move = move
	_fast = fast


func _physics_process(delta: float) -> void:
	var direction: Vector3 = basis.x * _move.x + Vector3.UP * _move.y + basis.z * _move.z
	if direction.is_zero_approx():
		return
	var speed: float = MOVE_SPEED * (FAST_FACTOR if _fast else 1.0)
	position += direction.normalized() * speed * delta


## Se place de trois quarts pour que la boîte « bounds » tienne dans une image de taille « view ».
## « margin » allonge la distance (1,3 : 30 % de plus), « side_share » décale l'œil sur le côté
## (part de la distance) ; l'œil reste au moins à « eye_height » mètres, ou à « eye_height_share »
## de la hauteur du centre.
func frame_bounds(bounds: AABB, view: Vector2, margin: float, side_share: float, eye_height: float,
		eye_height_share: float) -> void:
	var half_fov: float = tan(deg_to_rad(0.5 * fov))
	var fit_height: float = 0.5 * bounds.size.y / half_fov
	var fit_width: float = 0.5 * bounds.size.x / (half_fov * view.x / maxf(view.y, 1.0))
	var distance: float = margin * maxf(fit_height, fit_width)
	var center: Vector3 = bounds.get_center()
	var eye: Vector3 = Vector3(center.x + side_share * distance, maxf(eye_height, eye_height_share * center.y),
			bounds.end.z + distance)
	look_at_from_position(eye, center, Vector3.UP)
