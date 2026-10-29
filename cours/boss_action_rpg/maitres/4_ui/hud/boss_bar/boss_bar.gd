class_name BossBar extends Control
## Le nom et la vie du boss, en bas de l'écran : cachés tant que le boss ne s'est pas montré (reveal).

## La jauge de vie du boss.
@onready var bar: StatBar = $Bar

@onready var _name: Label = $Name


func _ready() -> void:
	visible = false


## Montre la jauge avec le nom `boss_name`.
func reveal(boss_name: String) -> void:
	_name.text = boss_name
	visible = true


## Le nom affiché.
func shown_name() -> String:
	return _name.text
