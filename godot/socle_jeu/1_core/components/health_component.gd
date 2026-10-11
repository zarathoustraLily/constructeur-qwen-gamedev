class_name HealthComponent
extends Node
## Points de vie d'un acteur. Une seule responsabilité : recevoir des dégâts et dire quand c'est fini.

signal damaged(amount: int, current: int)
signal died

@export var max_health: int = 3
## Durée d'invincibilité après un coup (0 : aucune).
@export var hit_invulnerability: float = 0.0

var current_health: int
## Vrai pendant un dash ou après un coup : les dégâts sont ignorés.
var invulnerable: bool = false
var _invulnerable_left: float = 0.0


func _ready() -> void:
	current_health = max_health


func _process(delta: float) -> void:
	if _invulnerable_left > 0.0:
		_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)


func take_damage(amount: int) -> bool:
	if amount <= 0 or is_dead() or invulnerable or _invulnerable_left > 0.0:
		return false
	current_health = maxi(current_health - amount, 0)
	damaged.emit(amount, current_health)
	if current_health == 0:
		died.emit()
	else:
		_invulnerable_left = hit_invulnerability
	return true


func is_dead() -> bool:
	return current_health <= 0
