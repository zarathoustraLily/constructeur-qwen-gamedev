extends Node3D
#@ 1
## Scène principale. À chaque image physique, l'adaptateur d'entrées (PlayerInput) traduit le clavier, la
## souris et la manette en commandes, et l'affichage (InputDisplay) les montre ; la flèche au pied du
## personnage montre la visée (à défaut, la marche), tournée selon la caméra ; un coup fait vibrer la manette
## (attack_rumble). La scène fait le lien : l'adaptateur et l'affichage ne se connaissent pas.
#@ 2+
## Scène principale : le joueur sur une estrade, au milieu d'un grand sol. À chaque image physique, la scène
## montre les commandes du joueur (InputDisplay), et un coup fait vibrer la manette (attack_rumble). La scène
## fait le lien : le joueur et l'affichage ne se connaissent pas.
#@ all

## Vibration jouée à chaque coup (5_data/input/attack_rumble.tres).
@export var attack_rumble: Rumble

#@ 1
@onready var _input: PlayerInput = $PlayerInput
#@ 2+
@onready var _player: Player = $Player
#@ all
@onready var _display: InputDisplay = $InputDisplay
#@ 1
@onready var _aim_pivot: Node3D = $Hero/AimPivot
@onready var _camera: Camera3D = $Hero/CameraRoot/Camera3D
#@ all


func _ready() -> void:
	if attack_rumble == null:
		push_error("Main : la vibration du coup (attack_rumble) manque")


func _physics_process(_delta: float) -> void:
#@ 1
	var commands := _input.read()
	if commands.attack and attack_rumble != null:
		_input.vibrate(attack_rumble)
	_display.show_commands(commands, _input.joypad_names())
	var aim := commands.move if commands.aim.is_zero_approx() else commands.aim
	_aim_pivot.visible = not aim.is_zero_approx()
	if _aim_pivot.visible:
		# Une direction de l'écran devient une direction du sol, tournée comme la caméra autour de la verticale.
		var direction := Vector3(aim.x, 0.0, aim.y).rotated(Vector3.UP, _camera.global_rotation.y)
		_aim_pivot.look_at(_aim_pivot.global_position + direction, Vector3.UP)
#@ 2+
	# La scène passe avant le joueur, son enfant : elle montre les commandes qu'il a lues à l'image d'avant.
	var commands := _player.commands
	if commands.attack and attack_rumble != null:
		_player.input.vibrate(attack_rumble)
	_display.show_commands(commands, _player.input.joypad_names())
#@ all
