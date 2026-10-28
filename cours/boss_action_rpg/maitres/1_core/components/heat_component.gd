class_name HeatComponent extends Node
## La chaleur d'une arme : chaque tir la monte ; elle redescend après un court délai sans tir ; au maximum, l'arme
## surchauffe et reste bloquée jusqu'à ce que la chaleur soit retombée à zéro.

## La chaleur vaut maintenant `current` sur `maximum` (pour une jauge).
signal changed(current: float, maximum: float)
## L'arme vient de surchauffer.
signal overheated
## L'arme surchauffée est retombée à zéro : elle peut tirer de nouveau.
signal cooled_down

## Le maximum, le refroidissement et son délai.
@export var settings: HeatSettings

## La chaleur actuelle.
var heat: float = 0.0
## Vrai de la surchauffe jusqu'au retour à zéro.
var is_overheated: bool = false

var _delay_left: float = 0.0


func _ready() -> void:
	process_physics_priority = ProcessOrder.COMPONENTS


func _physics_process(delta: float) -> void:
	tick(delta)


## Ajoute `amount` points (un tir) et relance le délai ; au maximum, la surchauffe part. Rien pendant la surchauffe.
func add(amount: float) -> void:
	if amount <= 0.0 or is_overheated:
		return
	_delay_left = settings.cool_delay
	_set_heat(minf(heat + amount, settings.max_heat))
	if heat >= settings.max_heat:
		is_overheated = true
		overheated.emit()


## Fait passer `delta` secondes : le délai d'abord, puis le refroidissement avec le temps qui reste ; surchauffée,
## l'arme se débloque à zéro.
func tick(delta: float) -> void:
	var left: float = delta
	if _delay_left > 0.0:
		var waited: float = minf(left, _delay_left)
		_delay_left -= waited
		left -= waited
	if left > 0.0 and heat > 0.0:
		_set_heat(maxf(heat - settings.cool_rate * left, 0.0))
	if is_overheated and heat <= 0.0:
		is_overheated = false
		cooled_down.emit()


## La part de chaleur, de 0 à 1 (pour une jauge).
func ratio() -> float:
	return clampf(heat / settings.max_heat, 0.0, 1.0)


func _set_heat(value: float) -> void:
	if value == heat:
		return
	heat = value
	changed.emit(heat, settings.max_heat)
