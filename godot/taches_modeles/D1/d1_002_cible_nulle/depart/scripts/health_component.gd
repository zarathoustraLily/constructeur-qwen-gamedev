class_name HealthComponent
extends Node
## Composant de vie réutilisable : points de vie, invulnérabilité, mort.

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 3

var current_health: int = 0
## Tant que vrai, take_damage n'a aucun effet (i-frames du dash).
var invulnerable: bool = false


func _ready() -> void:
	reset()


func reset() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health <= 0


## Retire des points de vie. Renvoie vrai si les dégâts ont été appliqués.
func take_damage(amount: int) -> bool:
	if amount <= 0 or invulnerable or is_dead():
		return false
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()
	return true


## Rend des points de vie sans dépasser le maximum. Sans effet si mort.
func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
