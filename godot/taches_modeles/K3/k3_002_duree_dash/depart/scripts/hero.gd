class_name Hero
extends CharacterBody2D
## Héros : déplacement à 8 directions et dash avec i-frames.

signal dashed(direction: Vector2)

@export var speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5

var facing: Vector2 = Vector2.RIGHT
var _dash_time_left: float = 0.0
var _cooldown_left: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO

@onready var health: HealthComponent = $HealthComponent


func is_dashing() -> bool:
	return _dash_time_left > 0.0


func can_dash() -> bool:
	return not is_dashing() and _cooldown_left <= 0.0


## Lance un dash dans la direction donnée (ou celle du regard si nulle).
func try_dash(direction: Vector2) -> bool:
	if not can_dash():
		return false
	_dash_direction = direction.normalized() if direction != Vector2.ZERO else facing
	_dash_time_left = dash_cooldown
	_cooldown_left = dash_duration
	health.invulnerable = true
	dashed.emit(_dash_direction)
	return true


## Fait avancer les minuteurs du dash ; les i-frames durent autant que le dash.
func advance_dash(delta: float) -> void:
	if is_dashing():
		_dash_time_left = maxf(_dash_time_left - delta, 0.0)
	elif _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	health.invulnerable = is_dashing()


## Vitesse voulue pour une direction d'entrée (longueur ≤ 1).
func compute_velocity(input_dir: Vector2) -> Vector2:
	if is_dashing():
		return _dash_direction * dash_speed
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	return input_dir * speed


func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()
	if Input.is_action_just_pressed("ui_accept"):
		try_dash(input_dir)
	advance_dash(delta)
	velocity = compute_velocity(input_dir)
	move_and_slide()
