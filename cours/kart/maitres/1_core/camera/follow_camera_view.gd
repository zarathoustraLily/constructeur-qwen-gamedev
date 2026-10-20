class_name FollowCameraView extends Node3D
## Caméra qui suit une cible en orbite. Ce nœud est le pivot : il se place au-dessus du modèle de la cible
## (`anchor`), et la caméra, au bout d'un bras à ressort (SpringArm3D, enfant), le regarde ; le bras se
## raccourcit quand un obstacle passe entre les deux. Au départ, le pivot est derrière la cible ; la souris et
## le stick droit le font tourner, et après `reset_delay` secondes sans eux, il revient derrière la cible, si
## elle avance. La cible et les réglages sont donnés par la scène qui l'emploie : ce mécanisme ne connaît
## aucun acteur du jeu.

## Réglages (5_data/camera/follow_camera.tres).
@export var settings: FollowCameraSettings
## La cible suivie : la caméra revient dans son dos.
@export var target: Node3D
## Le point suivi (le modèle de la cible) ; vide : la cible elle-même.
@export var anchor: Node3D
## Adaptateur d'entrées de la caméra.
@export var input: CameraInput

var _reset_cooldown: float = 0.0
var _last_target_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	if settings == null or target == null:
		push_error("Caméra : réglages (settings) ou cible (target) absents")
		set_process(false)
		return
	_last_target_position = target.global_position
	# Au départ, la caméra est dans le dos de la cible.
	global_basis = target.global_basis.orthonormalized()


func _process(delta: float) -> void:
	var mouse := input.take_mouse_motion() if input != null else Vector2.ZERO
	var stick := input.stick() if input != null else Vector2.ZERO
	if mouse != Vector2.ZERO or stick != Vector2.ZERO:
		turn(mouse * settings.mouse_sensitivity + stick * settings.stick_speed * delta)
	_reset_cooldown -= delta
	var followed := anchor if anchor != null else target
	global_position = followed.global_position + Vector3.UP * settings.height
	var target_speed := target.global_position.distance_to(_last_target_position) / delta
	_last_target_position = target.global_position
	if _reset_cooldown < 0.0 and target_speed > settings.reset_min_speed:
		var weight := 1.0 - exp(-settings.reset_rate * delta)
		global_basis = global_basis.orthonormalized().slerp(target.global_basis.orthonormalized(), weight)


## Fait tourner le pivot de `amount` radians (x : autour de la verticale, y : inclinaison), dans les limites
## de l'inclinaison, et repousse le retour derrière la cible.
func turn(amount: Vector2) -> void:
	rotation.y -= amount.x
	rotation.x = clampf(rotation.x - amount.y, -settings.max_pitch, settings.max_pitch)
	_reset_cooldown = settings.reset_delay
