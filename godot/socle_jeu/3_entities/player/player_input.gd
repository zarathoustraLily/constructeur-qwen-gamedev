class_name PlayerInput
extends Node
## Adaptateur d'entrées (ARC-04) : lit le clavier ou la manette et donne au joueur des intentions.
## Il passe avant tout le reste (ProcessOrder.INPUT). Dépend de : player (posé dans la scène).

@export var player: Player

var _dash_held: bool = false


func _ready() -> void:
	process_physics_priority = ProcessOrder.INPUT
	if player == null:
		push_error("PlayerInput : player n'est pas posé dans la scène")


func _physics_process(_delta: float) -> void:
	var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	# Le dash part à l'appui, une seule fois par appui, compté au pas fixe.
	var dash := Input.is_action_pressed(&"dash")
	player.set_intent(Vector3(v.x, 0.0, v.y), dash and not _dash_held, Input.is_action_pressed(&"fire"))
	_dash_held = dash
