class_name HealthComponent
extends Node
## Points de vie d'un acteur : reçoit des dégâts, dit quand c'est fini. Seul écrivain de la vie
## et de l'invincibilité (SIM-04) : les autres demandent par take_damage() et set_invulnerable().
## Entrées : setup(), take_damage(), set_invulnerable(). Possède : current_health.
## Émet : damaged, died.

signal damaged(amount: int, current: int)
signal died

var max_health: int = 0
var current_health: int = 0
var _hit_invulnerability: float = 0.0
var _invulnerable: bool = false
var _invulnerable_left: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.DAMAGE


## À appeler par le propriétaire avant tout dégât : vie maximale et invincibilité après un coup.
func setup(new_max_health: int, hit_invulnerability: float) -> void:
	if new_max_health <= 0:
		push_error("HealthComponent.setup : vie maximale %d (attendu > 0)" % new_max_health)
	max_health = new_max_health
	current_health = new_max_health
	_hit_invulnerability = hit_invulnerability


func _physics_process(delta: float) -> void:
	if _invulnerable_left > 0.0:
		_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)


func take_damage(amount: int) -> bool:
	if amount <= 0 or is_dead() or is_invulnerable():
		return false
	current_health = maxi(current_health - amount, 0)
	damaged.emit(amount, current_health)
	if current_health == 0:
		died.emit()
	else:
		_invulnerable_left = _hit_invulnerability
	return true


## Invincibilité tenue par un état (le dash) ; distincte de celle qui suit un coup.
func set_invulnerable(on: bool) -> void:
	_invulnerable = on


func is_invulnerable() -> bool:
	return _invulnerable or _invulnerable_left > 0.0


func is_dead() -> bool:
	return current_health <= 0
