class_name WheelView extends Node3D
## Roue du kart, côté présentation : un rayon vers le bas cherche le sol, et le maillage descend jusqu'à lui
## (la suspension) ; il tourne avec la vitesse du kart, et braque si la roue est directrice. La conduite ne
## dépend pas des roues : le kart est un seul corps qui glisse sur le sol.

## Rotation du maillage (radians) par mètre parcouru, reprise du kart d'origine.
const SPIN_PER_METER := 0.21 * PI * PI
## Lissage de la suspension : part de l'écart qui reste après une seconde.
const SUSPENSION_SMOOTHING := 0.5
## Nombre d'étapes de lissage par seconde.
const SUSPENSION_RATE := 60.0

## Roue directrice : elle suit le braquage.
@export var steering_enabled: bool = false
## Roue du côté gauche : sa rotation est inversée.
@export var left_side: bool = false
## Longueur de la suspension au repos : la roue ne descend pas plus bas.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var spring_rest_length: float = 0.3
## Portée du rayon qui cherche le sol, un peu plus longue que la suspension : kart posé, le sol est à 0,53 à
## 0,60 m sous le rayon (mesuré en roulant sur l'île) ; kart en l'air, presque toujours à plus de 0,75 m.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var ground_probe_length: float = 0.7

## Vitesse du kart (m/s), donnée par sa présentation à chaque image : elle fait tourner le maillage.
var speed: float = 0.0
## Décalage vertical du maillage vers le sol (négatif), lissé.
var compression: float = 0.0

@onready var _raycast: RayCast3D = $RayCast3D
@onready var _visual: Node3D = $WheelVisual
@onready var _mesh: MeshInstance3D = $WheelVisual/WheelMesh


func _ready() -> void:
	_raycast.target_position = Vector3(0.0, -ground_probe_length, 0.0)


## Vrai si la roue touche le sol.
func is_grounded() -> bool:
	return _raycast.is_colliding()


## Position du maillage de la roue (pour les traces de pneus).
func get_wheel_position() -> Vector3:
	return _visual.global_position
#@ 10+


## Point où le rayon de la roue touche le sol (pour les gerbes et les traînées).
func get_contact_point() -> Vector3:
	return _raycast.get_collision_point()


## Normale du sol sous la roue.
func get_contact_normal() -> Vector3:
	return _raycast.get_collision_normal()
#@ all


func _process(delta: float) -> void:
	var spin := speed * delta * SPIN_PER_METER
	_mesh.rotation.x += -spin if left_side else spin
	# Sans sol sous elle, la roue pend à la longueur de repos (le dernier point touché n'est plus valable).
	var distance := spring_rest_length
	if _raycast.is_colliding():
		distance = clampf(_raycast.get_collision_point().distance_to(global_position), 0.0, spring_rest_length)
	compression = lerpf(compression, -distance, 1.0 - pow(SUSPENSION_SMOOTHING, SUSPENSION_RATE * delta))
	_visual.position = Vector3(0.0, compression, 0.0)


## Oriente une roue directrice de `angle` radians ; sans effet sur les autres.
func set_steering(angle: float) -> void:
	if steering_enabled:
		_visual.rotation.y = angle
