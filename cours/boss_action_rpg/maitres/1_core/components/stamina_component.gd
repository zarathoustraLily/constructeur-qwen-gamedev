class_name StaminaComponent extends Node
## L'endurance d'une entité : les actions la dépensent, elle remonte d'elle-même après un court délai sans dépense.
## Règle du genre : on peut agir tant qu'il en reste, même un peu ; l'action vide alors la jauge, jamais sous zéro.

## L'endurance vaut maintenant `current` sur `maximum` (pour une jauge).
signal changed(current: float, maximum: float)

## Le maximum, la remontée et son délai.
@export var settings: StaminaSettings

## L'endurance actuelle.
var stamina: float = 0.0

var _delay_left: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.COMPONENTS
	stamina = settings.max_stamina


func _physics_process(delta: float) -> void:
	tick(delta)


## Vrai tant qu'il reste de l'endurance : une action peut partir.
func can_spend() -> bool:
	return stamina > 0.0


## Dépense `amount` points, sans descendre sous zéro, et relance le délai avant la remontée.
func spend(amount: float) -> void:
	if amount <= 0.0:
		return
	_delay_left = settings.regen_delay
	_set_stamina(maxf(stamina - amount, 0.0))


## Fait passer `delta` secondes : le délai d'abord, puis la remontée avec le temps qui reste, jamais au-dessus du
## maximum.
func tick(delta: float) -> void:
	var left: float = delta
	if _delay_left > 0.0:
		var waited: float = minf(left, _delay_left)
		_delay_left -= waited
		left -= waited
	if left > 0.0 and stamina < settings.max_stamina:
		_set_stamina(minf(stamina + settings.regen_rate * left, settings.max_stamina))


## La part d'endurance qui reste, de 0 à 1 (pour une jauge).
func ratio() -> float:
	return clampf(stamina / settings.max_stamina, 0.0, 1.0)


func _set_stamina(value: float) -> void:
	if value == stamina:
		return
	stamina = value
	changed.emit(stamina, settings.max_stamina)
