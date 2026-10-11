class_name Drone
extends CharacterBody3D
## Drone ennemi : attend, poursuit le joueur, tire à portée, meurt. Un état par comportement
## (states/), réglages dans 5_data/enemies/drone.tres. Se pose à la main dans un niveau.

@export var stats: ActorStats
## Effet joué à chaque coup reçu (3_entities/effects/).
@export var hit_effect: PackedScene

@onready var health: HealthComponent = $Health
@onready var weapon: WeaponComponent = $Weapon
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	health.max_health = stats.max_health
	health.current_health = stats.max_health
	health.died.connect(func() -> void: state_machine.transition_to(&"dead"))
	health.damaged.connect(func(_amount: int, _current: int) -> void: _play_hit_effect())


func _play_hit_effect() -> void:
	if hit_effect == null or not is_inside_tree():
		return
	var effect := hit_effect.instantiate() as Node3D
	get_parent().add_child(effect)
	effect.global_position = global_position


## Le joueur, ou null s'il n'y en a pas.
func target() -> Node3D:
	return get_tree().get_first_node_in_group(&"player") as Node3D


func distance_to_target() -> float:
	var t := target()
	return global_position.distance_to(t.global_position) if t != null else INF


func direction_to_target() -> Vector3:
	var t := target()
	if t == null:
		return Vector3.ZERO
	var d := t.global_position - global_position
	d.y = 0.0
	return d.normalized()
