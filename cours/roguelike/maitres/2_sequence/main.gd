extends Node3D
## Scène principale. À chaque image physique, l'adaptateur d'entrées (PlayerInput) traduit le clavier, la
## souris et la manette en commandes, et l'affichage (InputDisplay) les montre ; la flèche au pied du
## personnage montre la visée (à défaut, la marche), tournée selon la caméra ; un coup fait vibrer la manette
## (attack_rumble). La scène fait le lien : l'adaptateur et l'affichage ne se connaissent pas.

## Vibration jouée à chaque coup (5_data/input/attack_rumble.tres).
@export var attack_rumble: Rumble

@onready var _input: PlayerInput = $PlayerInput
@onready var _display: InputDisplay = $InputDisplay
@onready var _aim_pivot: Node3D = $Hero/AimPivot
@onready var _camera: Camera3D = $Hero/CameraRoot/Camera3D


func _ready() -> void:
	if attack_rumble == null:
		push_error("Main : la vibration du coup (attack_rumble) manque")


func _physics_process(_delta: float) -> void:
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
