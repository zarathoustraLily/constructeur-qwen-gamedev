class_name Drone
extends CharacterBody3D
## Drone ennemi (simulation) : attend, poursuit sa cible, tire à portée, meurt. Un état par
## comportement (states/), réglages dans 5_data/enemies/drone.tres. Se pose à la main dans un
## niveau ; le niveau lui fournit sa cible et ses projectiles par setup(). Sa présentation
## (étincelles, disparition) est dans drone_view.gd.
## Entrées : setup(). Dépend de : sa cible, fournie par le niveau.

@export var stats: ActorStats

var _target: Node3D

@onready var health: HealthComponent = $Health
@onready var weapon: WeaponComponent = $Weapon
@onready var state_machine: StateMachine = $StateMachine
@onready var view: DroneView = $View


func _ready() -> void:
	if stats == null:
		push_error("Drone %s : stats n'est pas posé dans la scène" % name)
		return
	for message in stats.validate():
		push_error("Drone %s : %s" % [name, message])
	health.setup(stats.max_health, stats.hit_invulnerability)
	health.died.connect(_on_died)


## Le niveau fournit la cible, le projectile et où le poser, et où jouer les effets.
func setup(target: Node3D, projectile: PackedScene, projectile_parent: Node, effects_parent: Node,
		hit_effect: PackedScene) -> void:
	if target == null:
		push_error("Drone.setup %s : cible absente" % name)
	_target = target
	weapon.setup(projectile, projectile_parent)
	view.setup(effects_parent, hit_effect)


func _on_died() -> void:
	state_machine.transition_to(&"dead")


## La cible, ou null s'il n'y en a pas.
func target() -> Node3D:
	return _target if is_instance_valid(_target) else null


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
