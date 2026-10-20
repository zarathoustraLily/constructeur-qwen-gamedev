class_name ItemBox extends Node3D
## Boîte à objets : un corps qui la traverse, tant qu'elle est active, la fait signaler `collected` ; elle se
## retire alors `respawn_time` secondes, puis revient. Elle ne sait ni qui la traverse ni ce qu'il reçoit : la
## scène qui l'écoute en décide. Sa présentation (item_box_view.gd) la fait flotter, tourner et changer de
## couleur.

## Émis quand `body` traverse la boîte active.
signal collected(body: Node3D)

## Durée (s) pendant laquelle la boîte se retire après avoir été prise (donnée par la scène de la boîte).
@export var respawn_time: float = 0.0

## Vrai si la boîte peut être prise.
var active: bool = true

var _respawn_left: float = 0.0


func _physics_process(delta: float) -> void:
	if active:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		active = true


## Ce qui arrive quand `body` entre dans la boîte (signal body_entered de son Area3D).
func on_body_entered(body: Node3D) -> void:
	if not active:
		return
	active = false
	_respawn_left = respawn_time
	collected.emit(body)
