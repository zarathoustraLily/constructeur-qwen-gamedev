class_name HeroSettings extends Resource
## Réglages du déplacement du héros : vitesses, accélérations, virage, gravité. Toutes les valeurs d'équilibrage du
## héros vivent ici (et dans le .tres de 5_data), jamais dans un script.

## Vitesse de course, en m/s.
@export_range(0.5, 20.0, 0.1) var run_speed: float = 5.5
## Vitesse en visant, en m/s : plus lente, le joueur choisit entre bouger et viser.
@export_range(0.5, 20.0, 0.1) var aim_speed: float = 2.5
## Accélération au sol, en m/s² : atteint la course en un peu plus d'un dixième de seconde.
@export_range(1.0, 200.0, 1.0) var acceleration: float = 45.0
## Freinage quand le stick est lâché, en m/s².
@export_range(1.0, 200.0, 1.0) var deceleration: float = 60.0
## Vitesse de virage du corps vers la direction de marche, en radians par seconde.
@export_range(1.0, 50.0, 0.5) var turn_speed: float = 14.0
## Gravité, en m/s².
@export_range(1.0, 100.0, 0.5) var gravity: float = 24.0
