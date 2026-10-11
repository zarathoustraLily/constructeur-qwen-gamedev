class_name WeaponComponent
extends Node3D
## Arme générique : tire le projectile de ses réglages (WeaponStats), avec une cadence.
## Les projectiles sont ajoutés au parent commun voulu (`projectile_parent`, sinon la scène courante).

signal fired(projectile: Node3D)

@export var stats: WeaponStats
var projectile_parent: Node

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func can_fire() -> bool:
	return stats != null and stats.projectile != null and _cooldown_left <= 0.0


func fire(direction: Vector3) -> Node3D:
	if not can_fire() or direction.is_zero_approx():
		return null
	_cooldown_left = 1.0 / stats.fire_rate
	var projectile := stats.projectile.instantiate() as Node3D
	var parent := projectile_parent if projectile_parent != null else get_tree().current_scene
	parent.add_child(projectile)
	projectile.global_position = global_position
	if projectile.has_method("launch"):
		projectile.call("launch", direction.normalized() * stats.projectile_speed, stats.damage, stats.lifetime)
	fired.emit(projectile)
	return projectile
