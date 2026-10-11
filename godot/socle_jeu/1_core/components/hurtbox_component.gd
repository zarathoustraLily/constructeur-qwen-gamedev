class_name HurtboxComponent
extends Area3D
## Zone qui reçoit les coups et les transmet au composant de vie.

signal hurt(damage: int)

@export var health: HealthComponent


func take_hit(damage: int) -> bool:
	if health == null or not health.take_damage(damage):
		return false
	hurt.emit(damage)
	return true
