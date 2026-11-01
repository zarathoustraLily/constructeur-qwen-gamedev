class_name CandleSettings extends Resource
## Réglages d'une bougie : sa lumière, son vacillement, les mots de l'invite.

## L'énergie de sa lumière au repos.
@export_range(0.0, 16.0, 0.1) var energy: float = 3.0
## La part de l'énergie que le vacillement ajoute ou retire.
@export_range(0.0, 1.0, 0.01) var flicker: float = 0.18
## La vitesse du vacillement, en radians par seconde.
@export_range(0.0, 60.0, 0.5) var flicker_speed: float = 11.0
## L'invite quand elle brûle.
@export var blow_prompt: String = "Souffler la bougie"
## L'invite quand elle est éteinte.
@export var light_prompt: String = "Rallumer la bougie"
