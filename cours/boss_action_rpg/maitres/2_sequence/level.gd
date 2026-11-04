class_name Level extends Node3D
## Une salle où l'on marche : le héros, sa caméra, l'interface. Elle prend la souris et branche l'interface sur le héros.

#@ 29+
## Le héros vient de passer le seuil vers la salle `path`.
signal left(path: String)

#@ all
## Le héros de la salle.
@onready var hero: Hero = $Hero
## L'interface de la salle.
@onready var hud: Hud = $Hud


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.bind_fighter(hero.health, hero.stamina, hero.gun.heat, hero.flasks)
	hud.bind_interactor(hero.interactor)
#@ 28+
	hero.weapon_changed.connect(_on_weapon_changed)
#@ 29+
	for exit: Node in find_children("*", "Threshold", true, false):
		(exit as Threshold).crossed.connect(left.emit)
#@ 28+


func _on_weapon_changed(kit: WeaponKit) -> void:
	hud.show_weapon(kit.display_name)
#@ all
