class_name HealthComponent extends Node
## La santé d'une entité : des dégâts, des soins, un court répit d'invincibilité après chaque coup, et une mort
## annoncée une seule fois. L'entité ne touche jamais aux points de vie elle-même : elle écoute les signaux.

## Un coup a retiré `amount` points ; il en reste `remaining`.
signal damaged(amount: float, remaining: float)
## Un soin a rendu `amount` points ; il y en a `remaining`.
signal healed(amount: float, remaining: float)
## Les points de vie sont tombés à zéro (une seule fois).
signal died

## Le maximum et le répit d'invincibilité.
@export var settings: HealthSettings

## Les points de vie actuels.
var health: float = 0.0

var _invincible_left: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.COMPONENTS
	health = settings.max_health


func _physics_process(delta: float) -> void:
	tick(delta)


## Fait passer `delta` secondes sur le répit d'invincibilité.
func tick(delta: float) -> void:
	_invincible_left = maxf(_invincible_left - delta, 0.0)


## Retire `amount` points et rend ce qui a vraiment été retiré : rien pendant le répit, après la mort, ou pour un
## coup nul ou négatif ; jamais plus que ce qui reste. Un coup qui porte ouvre le répit ; à zéro, `died` part.
func take_damage(amount: float) -> float:
	if amount <= 0.0 or is_dead() or is_invincible():
		return 0.0
	var dealt: float = minf(amount, health)
	health -= dealt
	_invincible_left = settings.invincibility_time
	damaged.emit(dealt, health)
	if is_dead():
		died.emit()
	return dealt


## Rend jusqu'à `amount` points, sans dépasser le maximum, et rend ce qui a vraiment été soigné ; rien après la mort.
func heal(amount: float) -> float:
	if amount <= 0.0 or is_dead():
		return 0.0
	var restored: float = minf(amount, settings.max_health - health)
	health += restored
	if restored > 0.0:
		healed.emit(restored, health)
	return restored


## Vrai quand il ne reste plus de points de vie.
func is_dead() -> bool:
	return health <= 0.0


## Vrai pendant le répit qui suit un coup.
func is_invincible() -> bool:
	return _invincible_left > 0.0


## La part de santé qui reste, de 0 à 1 (pour une barre de vie).
func ratio() -> float:
	return clampf(health / settings.max_health, 0.0, 1.0)
