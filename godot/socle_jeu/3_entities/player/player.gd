class_name Player
extends CharacterBody3D
## Le vaisseau du joueur (simulation). Il consomme des intentions (set_intent), jamais le clavier :
## player_input.gd les lui donne (ARC-04). Comportements : états (states/). Réglages :
## 5_data/actors/player.tres. Vie : HealthComponent.
## Entrées : setup(), set_intent(), start_dash_cooldown(). Possède : intentions, recharge du dash.

@export var stats: ActorStats

## Intentions du tour, posées par player_input.gd (ou par un test).
var move_input: Vector3 = Vector3.ZERO
var wants_dash: bool = false
var wants_fire: bool = false
## Direction du tir et du dash à l'arrêt : la dernière direction de déplacement.
var aim: Vector3 = Vector3.FORWARD
var _dash_cooldown_left: float = 0.0

@onready var health: HealthComponent = $Health
@onready var weapon: WeaponComponent = $Weapon
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	process_physics_priority = ProcessOrder.ATTACK
	if stats == null:
		push_error("Player : stats n'est pas posé dans la scène")
		return
	for message in stats.validate():
		push_error("Player : %s" % message)
	health.setup(stats.max_health, stats.hit_invulnerability)


## Le niveau fournit le projectile de l'arme et le nœud qui reçoit les tirs.
func setup(projectile: PackedScene, projectile_parent: Node) -> void:
	weapon.setup(projectile, projectile_parent)


func set_intent(move: Vector3, dash: bool, fire: bool) -> void:
	move_input = move
	wants_dash = dash
	wants_fire = fire


func _physics_process(delta: float) -> void:
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	if not move_input.is_zero_approx():
		aim = move_input.normalized()
	if wants_fire:
		weapon.fire(aim)


func can_dash() -> bool:
	return _dash_cooldown_left <= 0.0


func start_dash_cooldown() -> void:
	_dash_cooldown_left = stats.dash_cooldown


## Vitesse de marche pour une entrée donnée (normalisée en diagonale).
func walk_velocity(input: Vector3) -> Vector3:
	return input.limit_length(1.0) * stats.speed
