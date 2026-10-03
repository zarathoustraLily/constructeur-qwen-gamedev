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


## Retire `amount` points de vie et renvoie vrai si les dégâts ont été appliqués.
## Sans effet (renvoie faux) si amount <= 0, si `invulnerable` est vrai ou si déjà mort.
## Les points de vie ne descendent jamais sous 0. Après chaque changement, émet
## health_changed(current_health, max_health) ; émet died une seule fois, quand ils atteignent 0.
func take_damage(amount: int) -> bool:
	return false


## Rend des points de vie sans dépasser le maximum. Sans effet si mort.
func heal(amount: int) -> void:
	if amount <= 0 or is_dead():
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
