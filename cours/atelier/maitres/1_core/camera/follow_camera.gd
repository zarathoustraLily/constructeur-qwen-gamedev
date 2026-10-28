class_name FollowCamera extends Node3D
## Une caméra qui suit sa cible : un pivot qui rejoint la cible en douceur et tourne autour d'elle (lacet), un bras
## à ressort (SpringArm3D) penché vers le bas qui raccourcit quand un mur s'interpose, et la caméra au bout du bras.

## Ce que la caméra suit.
@export var target: Node3D
## Distance, hauteur, inclinaison, douceur.
@export var settings: CameraSettings

## L'angle autour de la cible (lacet), en radians.
var yaw: float = 0.0

@onready var _arm: SpringArm3D = $Arm


func _ready() -> void:
	process_physics_priority = ProcessOrder.CAMERA
	_arm.spring_length = settings.distance
	_arm.collision_mask = Layers.bit(Layers.WORLD)
	_arm.rotation.x = -deg_to_rad(settings.pitch_degrees)
	if target != null:
		global_position = focus_point(target.global_position, settings)


func _physics_process(delta: float) -> void:
	follow(delta)


## Le point visé : la cible, relevée de `target_height`.
static func focus_point(target_position: Vector3, camera_settings: CameraSettings) -> Vector3:
	return target_position + Vector3.UP * camera_settings.target_height


## `current` rapproché de `goal` d'un pas qui ne dépend pas du nombre d'images (amortissement exponentiel).
static func smooth(current: Vector3, goal: Vector3, speed: float, delta: float) -> Vector3:
	return current.lerp(goal, 1.0 - exp(-speed * delta))


## Fait passer `delta` secondes : le pivot rejoint le point visé, et prend le lacet courant.
func follow(delta: float) -> void:
	global_position = smooth(global_position, focus_point(target.global_position, settings), settings.follow_speed, delta)
	rotation.y = yaw


## Tourne autour de la cible : `amount` de -1 à 1 (stick droit), pendant `delta` secondes ; le lacet reste entre
## -PI et PI.
func orbit(amount: float, delta: float) -> void:
	yaw = wrapf(yaw + deg_to_rad(settings.orbit_speed_degrees) * clampf(amount, -1.0, 1.0) * delta, -PI, PI)


## La direction « avant » de la caméra sur le sol (y nul, longueur 1) : pour que le stick pousse le joueur là où
## la caméra regarde.
func ground_forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))
