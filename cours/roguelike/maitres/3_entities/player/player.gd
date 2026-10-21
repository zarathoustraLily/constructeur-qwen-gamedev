class_name Player extends CharacterBody3D
## Le héros. Il ne lit jamais les touches : à chaque image physique, il prend les commandes de son adaptateur
## d'entrées (PlayerInput ; sans adaptateur, un test les écrit lui-même), puis sa machine à états le déplace
#@ 2-4
## (course, chute). Les directions de l'écran deviennent des directions du sol, tournées comme sa caméra.
#@ 5+
## (course, chute, esquive). Les directions de l'écran deviennent des directions du sol, tournées comme sa
## caméra. Il signale ce qui se voit (dashed) : sa vue (PlayerView) en joue les effets et les sons.
#@ all
#@ 3+
## Les états choisissent aussi l'animation du modèle (animation_tree) : dans ce jeu, la durée d'un coup ou
## d'une esquive est celle de son animation.
#@ all
#@ 5+

## Émis au début d'une esquive, avec sa direction au sol (de longueur 1).
signal dashed(direction: Vector3)
#@ all

## Réglages du joueur (5_data/player/player_settings.tres).
@export var settings: PlayerSettings
## Adaptateur d'entrées ; sans lui, les commandes restent celles qu'on écrit dans `commands`.
@export var input: PlayerInput

## Les commandes de l'image en cours.
var commands: PlayerCommands = PlayerCommands.new()

@onready var model: Node3D = $Mannequin
#@ 3+
@onready var animation_tree: AnimationTreeView = $Mannequin/AnimationTree
#@ all
#@ 2-3
@onready var camera: Camera3D = $CameraRoot/Camera3D
#@ 4+
@onready var camera: ShakeCamera3D = $CameraRoot/Camera3D
#@ 5+
@onready var dash_cooldown: Timer = $DashCooldown
#@ all


func _ready() -> void:
	if settings == null:
		push_error("Player : les réglages (settings) manquent")
#@ 5+
		return
	dash_cooldown.wait_time = settings.dash_cooldown
#@ all


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
#@ 5+


## Vrai si le joueur peut esquiver : il marche, et la recharge de la dernière esquive est finie.
func can_dash() -> bool:
	return not get_movement_direction().is_zero_approx() and dash_cooldown.is_stopped()


## Lance une esquive vers `direction` (au sol, de longueur 1) : la vitesse d'esquive, la recharge, et le signal
## dashed. L'état d'esquive l'appelle en entrant.
func start_dash(direction: Vector3) -> void:
	velocity = direction * settings.dash_speed
	dash_cooldown.start()
	dashed.emit(direction)
#@ all
