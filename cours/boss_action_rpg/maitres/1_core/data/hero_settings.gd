class_name HeroSettings extends Resource
#@ 2-3
## Réglages du déplacement du héros : vitesses, accélérations, virage, gravité. Toutes les valeurs d'équilibrage du
## héros vivent ici (et dans le .tres de 5_data), jamais dans un script.
#@ 4+
## Réglages du déplacement du héros : vitesses, accélérations, virage, gravité, sprint et roulade. Toutes les valeurs
## d'équilibrage du héros vivent ici (et dans les .tres de 5_data), jamais dans un script.
#@ all

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
#@ 4+
## Vitesse du sprint (bouton de roulade tenu), en m/s.
@export_range(0.5, 20.0, 0.1) var sprint_speed: float = 8.0
## Endurance dépensée par seconde de sprint : une jauge pleine tient 5 secondes.
@export_range(0.0, 100.0, 1.0) var sprint_cost: float = 20.0
## Vitesse de la roulade, en m/s.
@export_range(1.0, 30.0, 0.1) var roll_speed: float = 7.0
## Durée de la roulade, en secondes : 7 m/s pendant 0,5 s, 3,5 m.
@export_range(0.1, 2.0, 0.01) var roll_duration: float = 0.5
## Durée de l'invulnérabilité, depuis le début de la roulade, en secondes ; la fin de la roulade reste punissable.
@export_range(0.0, 2.0, 0.01) var roll_invulnerable_time: float = 0.3
## Endurance dépensée par une roulade : quatre roulades vident une jauge pleine.
@export_range(0.0, 100.0, 1.0) var roll_cost: float = 25.0
## Mémoire d'appui : une roulade pressée au plus tant de secondes trop tôt part dès que possible.
@export_range(0.0, 1.0, 0.01) var roll_buffer_time: float = 0.25
#@ all
