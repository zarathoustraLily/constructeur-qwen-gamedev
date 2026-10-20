class_name RainView extends Node3D
## La pluie dessinée : des traits de pluie émis au-dessus de la caméra, un peu en avant de son déplacement, pour
## qu'il pleuve devant le kart lancé ; sous l'averse, le soleil faiblit et le brouillard s'épaissit. La force de
## la pluie (`intensity`) lui est donnée par la scène, qui tient la météo ; le soleil et l'environnement aussi.
## Elle ne change pas la météo.

## Force de la pluie, de 0 à 1, donnée par la scène à chaque image.
@export_range(0.0, 1.0) var intensity: float = 0.0
## Soleil assombri par l'averse.
@export var sun: DirectionalLight3D
## Environnement dont le brouillard s'épaissit.
@export var environment: WorldEnvironment
## Hauteur d'émission des gouttes au-dessus de la caméra (m).
@export var height_above_camera: float = 14.0
## Anticipation du déplacement de la caméra (s), pour qu'il pleuve devant le kart en vitesse.
@export var follow_lead: float = 0.5
## Part de l'énergie du soleil retirée sous une averse (intensité 1).
@export_range(0.0, 1.0) var sun_dim: float = 0.35
## Densité de brouillard ajoutée sous une averse (intensité 1).
@export var extra_fog_density: float = 0.006
## Au-delà de cette vitesse (m/s), la caméra a sauté : sa vitesse n'est pas suivie.
@export var max_camera_speed: float = 80.0

var _sun_energy: float = 1.0
var _fog_density: float = 0.0
var _last_camera_position: Vector3
var _camera_velocity: Vector3

@onready var _drops: GPUParticles3D = $Drops


func _ready() -> void:
	top_level = true
	if sun != null:
		_sun_energy = sun.light_energy
	if environment != null and environment.environment != null:
		_fog_density = environment.environment.fog_density


func _exit_tree() -> void:
	if sun != null:
		sun.light_energy = _sun_energy
	if environment != null and environment.environment != null:
		environment.environment.fog_density = _fog_density


func _process(delta: float) -> void:
	_drops.emitting = intensity > 0.0
	_drops.amount_ratio = intensity
	if sun != null:
		sun.light_energy = _sun_energy * (1.0 - sun_dim * intensity)
	if environment != null and environment.environment != null:
		environment.environment.fog_density = _fog_density + extra_fog_density * intensity
	var camera := get_viewport().get_camera_3d()
	if camera == null or delta <= 0.0:
		return
	var camera_position := camera.global_position
	var velocity := (camera_position - _last_camera_position) / delta
	if velocity.length() > max_camera_speed:
		velocity = Vector3.ZERO
	_camera_velocity = _camera_velocity.lerp(velocity, 1.0 - pow(0.05, delta))
	_last_camera_position = camera_position
	var lead := Vector3(_camera_velocity.x, 0.0, _camera_velocity.z) * follow_lead
	global_position = camera_position + lead + Vector3.UP * height_above_camera
