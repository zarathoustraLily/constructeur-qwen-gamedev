class_name WeaponStand extends Node3D
## Un bouchon de liège qui présente une arme : elle tourne lentement au-dessus de lui. On la prend à la main ; le bouchon
## reste vide jusqu'à ce que l'établi lui rende son arme.

## La main vient de prendre l'arme de ce socle.
signal taken(kit: WeaponKit)

## La vitesse de rotation de l'arme présentée, en radians par seconde.
const TURN_SPEED: float = 0.7

## L'arme présentée.
@export var kit: WeaponKit

## Vrai quand son arme est dans la main de Bobine.
var empty: bool = false

@onready var _display: MeshInstance3D = $Display
@onready var _hand: Interactable = $Hand


func _ready() -> void:
	_display.mesh = WeaponShapes.build(kit.shape)
	_hand.prompt = "Prendre %s : %s" % [kit.display_name, kit.description]
	_hand.used.connect(_on_used)


func _process(delta: float) -> void:
	_display.rotate_y(delta * TURN_SPEED)


## Vide le socle ou lui rend son arme.
func set_empty(value: bool) -> void:
	empty = value
	_display.visible = not empty
	_hand.enabled = not empty


func _on_used() -> void:
	taken.emit(kit)
