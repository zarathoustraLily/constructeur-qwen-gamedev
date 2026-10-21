class_name Player extends CharacterBody3D
## Le héros. Il ne lit jamais les touches : à chaque image physique, il prend les commandes de son adaptateur
## d'entrées (PlayerInput ; sans adaptateur, un test les écrit lui-même), puis sa machine à états le déplace
## (course, chute). Les directions de l'écran deviennent des directions du sol, tournées comme sa caméra.

## Réglages du joueur (5_data/player/player_settings.tres).
@export var settings: PlayerSettings
## Adaptateur d'entrées ; sans lui, les commandes restent celles qu'on écrit dans `commands`.
@export var input: PlayerInput

## Les commandes de l'image en cours.
var commands: PlayerCommands = PlayerCommands.new()

@onready var model: Node3D = $Mannequin
@onready var camera: Camera3D = $CameraRoot/Camera3D


func _ready() -> void:
	if settings == null:
		push_error("Player : les réglages (settings) manquent")


# Le joueur passe avant ses enfants : sa machine à états trouve les commandes de cette image.
func _physics_process(_delta: float) -> void:
	if input != null:
		commands = input.read()


## Direction de la marche, au sol : la marche de l'écran, tournée comme la caméra ; sa longueur va de 0 à 1.
func get_movement_direction() -> Vector3:
	return to_ground(commands.move)


## Une direction de l'écran (x vers la droite, y vers le bas) devenue direction du sol : tournée autour de la
## verticale du même angle que la caméra.
func to_ground(screen_direction: Vector2) -> Vector3:
	return Vector3(screen_direction.x, 0.0, screen_direction.y).rotated(Vector3.UP, camera.global_rotation.y)


## Tourne le modèle vers `direction`, en douceur : à chaque image, il fait la part
## 1 - exp(-turn_rate × delta) du chemin restant. Une direction nulle ne le tourne pas.
func look_toward_direction(direction: Vector3, delta: float) -> void:
	if direction.is_zero_approx():
		return
	var target := model.global_transform.looking_at(model.global_position + direction, Vector3.UP, true)
	model.global_transform = model.global_transform.interpolate_with(target, 1.0 - exp(-settings.turn_rate * delta))
