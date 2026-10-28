class_name MoveSettings extends Resource
## Réglages du déplacement d'un personnage : vitesses, accélérations, gravité, saut.

## Vitesse au sol à fond, en m/s.
@export_range(0.5, 30.0, 0.1) var max_speed: float = 6.0
## Accélération au sol, en m/s².
@export_range(1.0, 200.0, 1.0) var ground_acceleration: float = 40.0
## Accélération en l'air, en m/s² : moins de contrôle qu'au sol.
@export_range(0.0, 200.0, 1.0) var air_acceleration: float = 12.0
## Freinage au sol quand le stick est lâché, en m/s².
@export_range(0.0, 200.0, 1.0) var friction: float = 30.0
## Gravité, en m/s².
@export_range(1.0, 100.0, 0.5) var gravity: float = 20.0
## Vitesse de chute maximale, en m/s.
@export_range(1.0, 100.0, 0.5) var max_fall_speed: float = 40.0
## Hauteur d'un saut, en mètres.
@export_range(0.1, 10.0, 0.05) var jump_height: float = 1.6
## Après avoir quitté un bord, le temps pendant lequel un saut reste permis, en secondes.
@export_range(0.0, 0.5, 0.01) var coyote_time: float = 0.12
## Un appui sur saut un peu trop tôt (encore en l'air) est gardé ce temps-là, en secondes.
@export_range(0.0, 0.5, 0.01) var jump_buffer_time: float = 0.12
