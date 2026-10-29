class_name OrbitCamera extends Node3D
## La caméra à la troisième personne : un pivot qui rejoint le héros en douceur et tourne autour de lui (lacet,
## inclinaison bornée), un bras à ressort (SpringArm3D) qui raccourcit devant un mur, et la caméra au bout, décalée
## vers l'épaule. En visant, le bras raccourcit ; verrouillée, elle se tourne d'elle-même vers sa cible.
#@ 13+
## Elle sait trembler (un impact, un rugissement) : la vue se décale sans que la caméra bouge (h_offset, v_offset), de
## moins en moins, jusqu'à s'arrêter.
#@ all

## Le héros suivi.
@export var target: Node3D
## Distances, épaule, sensibilités, suivi, verrouillage.
@export var settings: CameraSettings

## Le lacet du pivot, en radians.
var yaw: float = 0.0
## L'inclinaison du pivot, en radians (positive : regarder vers le bas).
var pitch: float = deg_to_rad(15.0)
## Vrai pendant la visée.
var aiming: bool = false
## La cible verrouillée, ou null.
var locked: Node3D = null
#@ 13+
## L'ampleur du tremblement en cours, en mètres, à son début.
var shake_strength: float = 0.0
## Le temps qui reste au tremblement, en secondes.
var shake_left: float = 0.0

var _shake_time: float = 0.0
#@ all

@onready var _arm: SpringArm3D = $Arm
@onready var _camera: Camera3D = $Arm/Camera


func _ready() -> void:
	process_physics_priority = ProcessOrder.CAMERA
	_arm.collision_mask = Layers.bit(Layers.WORLD)
	_arm.spring_length = settings.distance
	if target != null:
		global_position = focus(target.global_position, settings)
#@ 7+
		yaw = wrapf(target.global_rotation.y, -PI, PI)
#@ all
	apply_rotation()
	_camera.make_current()


func _physics_process(delta: float) -> void:
	follow(delta)


## Le point que suit le pivot : les pieds du héros, relevés de `height`.
static func focus(feet: Vector3, camera_settings: CameraSettings) -> Vector3:
	return feet + Vector3.UP * camera_settings.height


## Tourne la caméra de `delta_yaw` et `delta_pitch` radians ; l'inclinaison reste dans ses bornes, le lacet entre -PI
## et PI. Sans effet quand la caméra est verrouillée : c'est la cible qui commande.
func rotate_by(delta_yaw: float, delta_pitch: float) -> void:
	if locked != null:
		return
	yaw = wrapf(yaw + delta_yaw, -PI, PI)
	pitch = clampf(pitch + delta_pitch, deg_to_rad(settings.pitch_min_degrees), deg_to_rad(settings.pitch_max_degrees))
	apply_rotation()


## Verrouille la caméra sur `node` (null : déverrouille).
func lock(node: Node3D) -> void:
	locked = node


## Fait passer `delta` secondes : le pivot rejoint le héros ; verrouillée, la caméra se tourne vers sa cible ; le bras
## prend la longueur de visée ou de course ; l'épaule décale la caméra.
func follow(delta: float) -> void:
	var weight: float = 1.0 - exp(-settings.follow_speed * delta)
	global_position = global_position.lerp(focus(target.global_position, settings), weight)
	if locked != null and is_instance_valid(locked):
		var goal: Vector2 = LockOn.look_angles(global_position, locked.global_position)
		var turn: float = 1.0 - exp(-settings.lock_speed * delta)
		yaw = lerp_angle(yaw, goal.x, turn)
		pitch = clampf(lerpf(pitch, goal.y, turn), deg_to_rad(settings.pitch_min_degrees), deg_to_rad(settings.pitch_max_degrees))
	elif locked != null:
		locked = null
	_arm.spring_length = lerpf(_arm.spring_length, settings.aim_distance if aiming else settings.distance, weight)
	_camera.position.x = settings.shoulder
	apply_rotation()
#@ 13+
	_update_shake(delta)
#@ all


## Pose le lacet sur le pivot et l'inclinaison sur le bras.
func apply_rotation() -> void:
	rotation.y = yaw
	_arm.rotation.x = -pitch


## La direction « avant » de la caméra sur le sol (y nul, longueur 1).
func ground_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))
#@ 13+


## Fait trembler la vue de `strength` mètres au plus, qui s'éteignent en `duration` secondes ; un tremblement plus
## faible que celui en cours ne le remplace pas.
func shake(strength: float, duration: float) -> void:
	if duration <= 0.0 or strength < current_shake():
		return
	shake_strength = strength
	shake_left = duration
	_shake_time = duration


## L'ampleur du tremblement à cet instant, en mètres (0 : la vue ne tremble pas).
func current_shake() -> float:
	return shake_strength * shake_left / _shake_time if shake_left > 0.0 else 0.0


func _update_shake(delta: float) -> void:
	shake_left = maxf(shake_left - delta, 0.0)
	var amount: float = current_shake()
	_camera.h_offset = sin(shake_left * 61.0) * amount
	_camera.v_offset = cos(shake_left * 47.0) * amount
#@ all
