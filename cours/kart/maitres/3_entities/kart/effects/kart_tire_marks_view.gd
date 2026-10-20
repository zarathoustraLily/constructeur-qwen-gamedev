class_name KartTireMarksView extends Node
## Traces des pneus du kart : à chaque image, elle recentre les traces de la scène (le TireMarksManager du
## groupe « tire_marks ») sur le kart, et y imprime chaque roue ; une roue en l'air imprime une marque de force
## nulle, qui ne laisse rien. Sans gestionnaire de traces dans la scène, elle ne fait rien.

## Le kart suivi.
@export var kart: Kart
## Les roues qui impriment leur marque.
@export var wheels: Array[WheelView] = []
## Force de la marque d'une roue au sol, de 0 à 1.
@export var mark_strength: float = 1.0
## Rayon de la marque, en pixels de la texture des traces.
@export var mark_radius_px: float = 9.0

var _manager: TireMarksManager


func _process(_delta: float) -> void:
	if _manager == null:
		_manager = get_tree().get_first_node_in_group("tire_marks") as TireMarksManager
		if _manager == null:
			return
	_manager.set_player_position(kart.global_position)
	for wheel: WheelView in wheels:
		_manager.add_tire(wheel.get_wheel_position(), mark_strength if wheel.is_grounded() else 0.0, mark_radius_px)
