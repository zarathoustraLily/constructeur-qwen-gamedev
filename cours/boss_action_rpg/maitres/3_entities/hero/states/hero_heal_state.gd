class_name HeroHealState extends State
## L'état Heal du héros : il boit une fiole, immobile, pendant `heal_duration`. La fiole est prise au début, le soin
## arrive à `heal_moment` : un coup reçu avant fait perdre la fiole sans soigner. Se soigner se paie : on boit quand le
## boss ne peut pas frapper.

## Le héros piloté.
@export var hero: Hero

## Le temps écoulé depuis le début de la gorgée, en secondes.
var elapsed: float = 0.0

var _healed: bool = false


## La fiole est prise.
func enter(_previous: StringName) -> void:
	elapsed = 0.0
	_healed = false
	hero.flasks.use()


## Immobile ; au moment du soin, la santé remonte ; la fiole bue, Move.
func physics_update(delta: float) -> void:
	elapsed += delta
	hero.slide(delta, Vector3.ZERO)
	if not _healed and elapsed >= hero.settings.heal_moment:
		_healed = true
		hero.health.heal(hero.settings.heal_amount)
	if elapsed >= hero.settings.heal_duration:
		finish(&"Move")
