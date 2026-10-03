class_name Ghost
extends CharacterBody2D
## Ennemi : patrouille autour de son point de départ, puis poursuit la cible proche.

signal defeated

enum State { PATROL, CHASE }

@export var patrol_speed: float = 60.0
@export var chase_speed: float = 120.0
@export var detection_radius: float = 150.0
## Demi-amplitude horizontale de la patrouille, en pixels.
@export var patrol_distance: float = 64.0

var target: Node2D = null
var state: State = State.PATROL
var _origin: Vector2 = Vector2.ZERO
var _patrol_sign: float = 1.0

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	_origin = position


func can_see_target() -> bool:
	if target == null:
		return false
	return global_position.distance_to(target.global_position) <= detection_radius


func update_state() -> State:
	state = State.CHASE if can_see_target() else State.PATROL
	return state


func compute_velocity() -> Vector2:
	if state == State.CHASE:
		return global_position.direction_to(target.global_position) * chase_speed
	if position.x >= _origin.x + patrol_distance:
		_patrol_sign = -1.0
	elif position.x <= _origin.x - patrol_distance:
		_patrol_sign = 1.0
	return Vector2(_patrol_sign * patrol_speed, 0.0)


func _physics_process(_delta: float) -> void:
	update_state()
	velocity = compute_velocity()
	move_and_slide()


func _on_died() -> void:
	defeated.emit()
	queue_free()
