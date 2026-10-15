class_name HurtboxComponent
extends Area3D
## Zone qui reçoit les coups et les transmet au composant de vie.
## Dépend de : health (posé dans la scène de l'acteur, vérifié au démarrage). Émet : hurt.

signal hurt(damage: int)

@export var health: HealthComponent


func _ready() -> void:
	if health == null:
		push_error("HurtboxComponent %s : health n'est pas posé dans la scène" % get_path())


func take_hit(damage: int) -> bool:
	if health == null or not health.take_damage(damage):
		return false
	hurt.emit(damage)
	return true
