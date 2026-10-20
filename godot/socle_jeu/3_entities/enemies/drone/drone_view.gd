class_name DroneView
extends Node3D
## Présentation du drone (ARC-02) : étincelles à chaque coup, rétrécissement à la mort. Elle écoute
## la vie et ne décide de rien. Dépend de : drone et health (posés dans la scène) ; effet et parent
## des effets, fournis par setup().

## Échelle visée à la fin de la disparition.
const VANISH_SCALE := Vector3.ONE * 0.01

@export var drone: Drone
@export var health: HealthComponent

var _effects_parent: Node
var _hit_effect: PackedScene


func _ready() -> void:
	if drone == null or health == null:
		push_error("DroneView : drone ou health n'est pas posé dans la scène")
		return
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func setup(effects_parent: Node, hit_effect: PackedScene) -> void:
	_effects_parent = effects_parent
	_hit_effect = hit_effect


func _on_damaged(_amount: int, _current: int) -> void:
	if _hit_effect == null or _effects_parent == null or not is_inside_tree():
		return
	var effect := _hit_effect.instantiate() as Node3D
	_effects_parent.add_child(effect)
	effect.global_position = drone.global_position


func _on_died() -> void:
	var tween := create_tween()
	tween.tween_property(drone, ^"scale", VANISH_SCALE, drone.stats.death_duration)
