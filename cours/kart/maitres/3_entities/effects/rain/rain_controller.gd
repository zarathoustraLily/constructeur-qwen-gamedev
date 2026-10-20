class_name RainController extends Node3D

## Pluie : traits de pluie autour de la caméra + paramètres globaux de shader
## « rain_intensity » (anneaux d'impact sur la mer et la route) et « rain_wetness » (route mouillée).

## 0 = pas de pluie, 1 = averse
@export_range(0.0, 1.0) var intensity : float = 0.8
## Vitesse à laquelle la route se mouille / sèche (unités par seconde)
@export var wetness_speed : float = 0.15
## Le niveau commence déjà mouillé s'il pleut au lancement
@export var start_wet : bool = true
## Hauteur d'émission des gouttes au-dessus de la caméra (m)
@export var height_above_camera : float = 14.0
## Anticipation du déplacement de la caméra (s) pour qu'il pleuve devant le kart en vitesse
@export var follow_lead : float = 0.5

@export_group("Ambiance")
## Assombrit le soleil et épaissit le brouillard quand il pleut
@export var darken_scene : bool = true
## Part de l'énergie du soleil retirée sous une averse (intensité 1).
@export_range(0.0, 1.0) var sun_dim : float = 0.35
## Densité de brouillard ajoutée sous une averse (intensité 1).
@export var extra_fog_density : float = 0.006

## Mouillage actuel de la route (0..1), lu aussi par les effets de roues
var wetness : float = 0.0

@onready var _drops : GPUParticles3D = $Drops
var _sun : DirectionalLight3D
var _sun_energy : float = 1.0
var _environment : Environment
var _fog_density : float = 0.0
var _last_camera_position : Vector3
var _camera_velocity : Vector3

func _ready() -> void:
	add_to_group("rain")
	top_level = true
	wetness = intensity if start_wet else 0.0
	# Trouver le soleil et l'environnement une fois la scène complète prête
	_find_ambience.call_deferred()

func _find_ambience() -> void:
	for node in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		_sun = node
		_sun_energy = _sun.light_energy
		break
	for node in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		_environment = (node as WorldEnvironment).environment
		if _environment:
			_fog_density = _environment.fog_density
		break

func _exit_tree() -> void:
	if is_instance_valid(GameState):
		GameState.rain_intensity = 0.0
		GameState.rain_wetness = 0.0
	if _sun:
		_sun.light_energy = _sun_energy
	if _environment:
		_environment.fog_density = _fog_density

func _process(delta: float) -> void:
	wetness = move_toward(wetness, intensity, wetness_speed * delta)
	GameState.rain_intensity = intensity
	GameState.rain_wetness = wetness

	_drops.emitting = intensity > 0.0
	_drops.amount_ratio = intensity

	if darken_scene:
		if _sun:
			_sun.light_energy = _sun_energy * (1.0 - sun_dim * intensity)
		if _environment:
			_environment.fog_density = _fog_density + extra_fog_density * intensity

	# Les gouttes sont émises au-dessus de la caméra, un peu en avant de son déplacement
	var camera := get_viewport().get_camera_3d()
	if camera and delta > 0.0:
		var cam_pos := camera.global_position
		var velocity := (cam_pos - _last_camera_position) / delta
		if velocity.length() > 80.0:
			velocity = Vector3.ZERO  # téléportation / première image
		_camera_velocity = _camera_velocity.lerp(velocity, 1.0 - pow(0.05, delta))
		_last_camera_position = cam_pos
		var lead := Vector3(_camera_velocity.x, 0.0, _camera_velocity.z) * follow_lead
		global_position = cam_pos + lead + Vector3.UP * height_above_camera
