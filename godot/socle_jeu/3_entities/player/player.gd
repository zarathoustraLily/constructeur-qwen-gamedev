class_name Player
extends CharacterBody3D
## Le vaisseau du joueur. Ses comportements sont des états (states/), ses réglages un .tres
## (5_data/actors/player.tres), sa vie un composant.

@export var stats: ActorStats

## Lire le clavier à chaque image. Les tests le coupent et posent move_input / wants_dash.
var read_input: bool = true
var move_input: Vector3 = Vector3.ZERO
var wants_dash: bool = false
var wants_fire: bool = false
## Direction du tir et du dash à l'arrêt : la dernière direction de déplacement.
var aim: Vector3 = Vector3.FORWARD
var dash_cooldown_left: float = 0.0

@onready var health: HealthComponent = $Health
@onready var weapon: WeaponComponent = $Weapon
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	health.max_health = stats.max_health
	health.current_health = stats.max_health
	health.hit_invulnerability = stats.hit_invulnerability
	health.damaged.connect(func(_amount: int, current: int) -> void: EventBus.player_damaged.emit(current))
	health.died.connect(func() -> void: EventBus.player_died.emit())


func _physics_process(delta: float) -> void:
	if read_input:
		var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		move_input = Vector3(v.x, 0.0, v.y)
		wants_dash = Input.is_action_just_pressed(&"dash")
		wants_fire = Input.is_action_pressed(&"fire")
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	if not move_input.is_zero_approx():
		aim = move_input.normalized()
	if wants_fire:
		weapon.fire(aim)


func can_dash() -> bool:
	return dash_cooldown_left <= 0.0


## Vitesse de marche pour une entrée donnée (normalisée en diagonale).
func walk_velocity(input: Vector3) -> Vector3:
	return input.limit_length(1.0) * stats.speed
