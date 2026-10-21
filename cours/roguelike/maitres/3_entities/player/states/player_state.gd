class_name PlayerState extends State
## Classe de base des états du joueur : ils lisent ses commandes et le déplacent.

## Le joueur piloté.
@export var player: Player


#@ 2-5
## Marche selon les commandes, à `speed` (m/s) pour un stick poussé à fond, le modèle tourné vers la marche.
#@ 6+
## Marche selon les commandes, à `speed` (m/s) pour un stick poussé à fond, le modèle tourné vers la marche ;
## repoussé, suit son recul.
#@ all
func core_movement(delta: float, speed: float) -> void:
	var direction := player.get_movement_direction()
#@ 2-5
	player.velocity = direction * speed
#@ 6+
	# Repoussé, le personnage suit son recul au lieu de sa marche.
	if player.knockback_component.is_active():
		player.velocity = player.knockback_component.magnitude
	else:
		player.velocity = direction * speed
#@ all
	player.look_toward_direction(direction, delta)
