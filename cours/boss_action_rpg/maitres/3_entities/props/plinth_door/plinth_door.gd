class_name PlinthDoor extends Node3D
## La plinthe : une planche qui ferme la sortie du Terrier. Elle se lève quand Bobine a une arme. Tant qu'elle est fermée, la
## main dit pourquoi elle ne cède pas.

## La hauteur dont elle se lève, en mètres.
const LIFT: float = 3.7
## Sa vitesse, en mètres par seconde.
const LIFT_SPEED: float = 2.6

## Vrai quand elle s'est levée.
var open: bool = false

@onready var _panel: Node3D = $Panel
@onready var _shape: CollisionShape3D = $Panel/Shape
@onready var _hand: Interactable = $Hand


func _process(delta: float) -> void:
	if open:
		_panel.position.y = move_toward(_panel.position.y, LIFT, delta * LIFT_SPEED)


## La lève : le passage est libre tout de suite, et la main n'a plus rien à dire.
func open_door() -> void:
	open = true
	_hand.enabled = false
	_shape.set_deferred(&"disabled", true)
