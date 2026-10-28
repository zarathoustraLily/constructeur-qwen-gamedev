class_name PlayerInput extends Node
## L'entrée du joueur : elle lit les actions (stick filtré par sa zone morte, saut) et les donne au joueur. Le
## joueur ne connaît ni la manette ni le clavier.

## Le joueur piloté.
@export var player: Player
## La zone morte du stick.
@export var gamepad: GamepadSettings


func _ready() -> void:
	process_physics_priority = ProcessOrder.INPUT


func _physics_process(_delta: float) -> void:
	player.wish = StickFilter.from_actions(&"move_left", &"move_right", &"move_up", &"move_down", gamepad.stick_deadzone)
	if Input.is_action_just_pressed(&"move_jump"):
		player.press_jump()
