class_name Candle extends Node3D
## Un bout de bougie, grand comme Bobine : une lumière qui vacille, qu'on souffle et qu'on rallume à la main.

## La bougie vient de changer : `burning` vaut vrai si elle brûle.
signal toggled(burning: bool)

## Sa lumière, son vacillement, les mots de l'invite.
@export var settings: CandleSettings

## Vrai tant qu'elle brûle.
var lit: bool = true

var _time: float = 0.0

@onready var _flame: MeshInstance3D = $Flame
@onready var _light: OmniLight3D = $Light
@onready var _hand: Interactable = $Hand


func _ready() -> void:
	_hand.used.connect(toggle)
	_show()


func _process(delta: float) -> void:
	if lit:
		_time += delta
		_light.light_energy = energy_at(_time)


## L'énergie de sa lumière à l'instant `time` : deux ondes de vitesses sans rapport, pour qu'elle ne batte pas en mesure.
func energy_at(time: float) -> float:
	var wave: float = sin(time * settings.flicker_speed) + sin(time * settings.flicker_speed * 1.73)
	return settings.energy * (1.0 + settings.flicker * wave * 0.5)


## La souffle si elle brûle, la rallume sinon.
func toggle() -> void:
	lit = not lit
	_show()
	toggled.emit(lit)


func _show() -> void:
	_flame.visible = lit
	_light.visible = lit
	_hand.prompt = settings.blow_prompt if lit else settings.light_prompt
