class_name Level extends Node3D
## Une salle où l'on marche : le héros, sa caméra, l'interface. Elle prend la souris et branche l'interface sur le héros.

## Le héros de la salle.
@onready var hero: Hero = $Hero
## L'interface de la salle.
@onready var hud: Hud = $Hud


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.bind_fighter(hero.health, hero.stamina, hero.gun.heat, hero.flasks)
	hud.bind_interactor(hero.interactor)
