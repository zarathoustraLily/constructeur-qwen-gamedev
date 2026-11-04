class_name TinCan extends Node3D
## Une boîte de conserve pour essayer une arme : elle encaisse sans jamais tomber, penche sous le coup, revient, et affiche
## les dégâts du dernier tir. Sa zone n'a pas de santé : la boîte n'a rien à perdre.

## Ce qu'un point de dégâts la fait pencher, en radians.
const TILT_PER_POINT: float = 0.01
## Sa plus grande inclinaison, en radians.
const TILT_MAX: float = 0.5
## La vitesse à laquelle elle se redresse, en radians par seconde.
const TILT_RECOVERY: float = 0.9

## Son inclinaison du moment, en radians.
var tilt: float = 0.0

@onready var _can: Node3D = $Can
@onready var _label: Label3D = $Damage


func _ready() -> void:
	($Hurtbox as Hurtbox).received.connect(_on_received)


func _process(delta: float) -> void:
	tilt = move_toward(tilt, 0.0, delta * TILT_RECOVERY)
	_can.rotation.x = -tilt


func _on_received(amount: float, _dealt: float) -> void:
	tilt = minf(tilt + amount * TILT_PER_POINT, TILT_MAX)
	_label.text = str(roundi(amount))
