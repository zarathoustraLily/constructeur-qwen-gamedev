class_name WeaponComponent
extends Node3D
## Arme générique : tire le projectile reçu, avec la cadence et les dégâts de ses réglages.
## Dépend de : stats (WeaponStats, posé dans la scène) ; projectile et parent des projectiles,
## fournis par setup() (le niveau les connaît, pas l'acteur). Émet : fired.

signal fired(projectile: Node3D)

@export var stats: WeaponStats

var _projectile: PackedScene
var _projectile_parent: Node
var _cooldown_left: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.ATTACK
	if stats == null:
		push_error("WeaponComponent %s : stats n'est pas posé dans la scène" % get_path())
		return
	for message in stats.validate():
		push_error("WeaponComponent %s : %s" % [get_path(), message])


func setup(projectile: PackedScene, projectile_parent: Node) -> void:
	if projectile == null or projectile_parent == null:
		push_error("WeaponComponent.setup %s : projectile ou parent absent" % get_path())
	_projectile = projectile
	_projectile_parent = projectile_parent


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func can_fire() -> bool:
	return stats != null and _projectile != null and _projectile_parent != null and _cooldown_left <= 0.0


func fire(direction: Vector3) -> Node3D:
	if not can_fire() or direction.is_zero_approx():
		return null
	_cooldown_left = 1.0 / stats.fire_rate
	var projectile := _projectile.instantiate() as Node3D
	_projectile_parent.add_child(projectile)
	projectile.global_position = global_position
	if projectile.has_method(&"launch"):
		projectile.call(&"launch", direction.normalized() * stats.projectile_speed, stats.damage, stats.lifetime)
	fired.emit(projectile)
	return projectile
