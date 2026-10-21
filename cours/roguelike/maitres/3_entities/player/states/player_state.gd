class_name PlayerState extends State
## Classe de base des états du joueur : ils lisent ses commandes et le déplacent.

## Le joueur piloté.
@export var player: Player


## Marche selon les commandes, à `speed` (m/s) pour un stick poussé à fond, le modèle tourné vers la marche.
func core_movement(delta: float, speed: float) -> void:
	var direction := player.get_movement_direction()
	player.velocity = direction * speed
	player.look_toward_direction(direction, delta)
