class_name BoostPanel extends Node3D
## Plaque de turbo : un corps qui passe dessus la fait signaler `crossed`, avec la durée du turbo qu'elle donne.
## La scène qui l'écoute donne le turbo au kart ; la plaque ne connaît pas le kart.

## Émis quand `body` passe sur la plaque.
signal crossed(body: Node3D, boost_time: float)

## Durée (s) du turbo donné (donnée par la scène de la plaque).
@export var boost_time: float = 0.0


## Ce qui arrive quand `body` entre sur la plaque (signal body_entered de son Area3D).
func on_body_entered(body: Node3D) -> void:
	crossed.emit(body, boost_time)
