extends Node3D
## Présentation du kart : à chaque image, le modèle s'aligne sur le sol (en l'air, il pique du nez ou se
## cabre selon la vitesse verticale), les roues tournent avec la vitesse et braquent, le volant suit le
## braquage et la caisse penche dans les virages. Elle lit l'état du kart sans jamais le changer (règle
## ARC-02) ; ses chiffres sont des choix d'affichage, pas des réglages de conduite.

## Lissage de l'alignement au sol : part de l'écart qui reste après une demi-seconde.
const GROUND_SMOOTHING := 0.025
## Lissage de l'alignement en l'air.
const AIR_SMOOTHING := 0.5
#@ 7+
## Lissage de l'alignement sur l'eau.
const WATER_SMOOTHING := 0.3
## Lissage de la pente de l'eau lue sous le kart.
const WATER_NORMAL_SMOOTHING := 0.03125
#@ all
## Inclinaison en l'air (radians) par m/s de vitesse verticale.
const AIR_LEAN_STRENGTH := -0.2
## Inclinaison maximale en l'air, en radians.
const AIR_LEAN_MAX := 0.2
## Les roues braquent plus que le kart, pour qu'on le voie.
const WHEEL_STEERING_SCALE := 2.0
## Le volant tourne encore plus.
const STEERING_WHEEL_SCALE := 3.0
## La caisse penche dans les virages.
const BODY_ROLL_SCALE := 0.5

## Le kart montré.
@export var kart: Kart
## Le modèle (caisse, pilote, roues), penché dans les virages.
@export var model: Node3D
## Le volant, tourné avec le braquage.
@export var steering_wheel: Node3D
## Les roues.
@export var wheels: Array[WheelView] = []

var _model_up: Vector3 = Vector3.UP
#@ 7+
var _water_normal: Vector3 = Vector3.UP
#@ all


func _process(delta: float) -> void:
	var target := Vector3.UP
	var smoothing := AIR_SMOOTHING
#@ 2-6
	if kart.is_on_ground():
#@ 7+
	if kart.is_in_water():
		smoothing = WATER_SMOOTHING
		_water_normal = _water_normal.lerp(kart.water_sensor.compute_normal(),
			1.0 - pow(WATER_NORMAL_SMOOTHING, 2.0 * delta))
		target = _water_normal
	elif kart.is_on_ground():
#@ all
		smoothing = GROUND_SMOOTHING
		target = kart.get_floor_normal()
	else:
		var side := kart.global_basis.z.cross(Vector3.UP)
		var lean := clampf(kart.velocity.y * AIR_LEAN_STRENGTH, -AIR_LEAN_MAX, AIR_LEAN_MAX)
		target = Vector3.UP.rotated(side.normalized(), lean)
	_model_up = _model_up.lerp(target, 1.0 - pow(smoothing, 2.0 * delta))
	align(_model_up)
	var angle := deg_to_rad(kart.settings.max_steering_angle_fast)
	for wheel: WheelView in wheels:
		wheel.set_steering(-kart.steering * WHEEL_STEERING_SCALE * angle)
		wheel.speed = kart.forward_speed()
	steering_wheel.rotation.y = -kart.steering * STEERING_WHEEL_SCALE * angle
	model.rotation.z = kart.steering * BODY_ROLL_SCALE * angle


## Oriente le modèle : son haut suit `up`, son avant reste celui du kart.
func align(up: Vector3) -> void:
	var normal := up.normalized()
	var forward := -kart.global_basis.z
	forward = (forward - normal * forward.dot(normal)).normalized()
	global_basis = Basis(normal.cross(forward).normalized(), normal, forward)
