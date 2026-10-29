class_name GolemSettings extends Resource
## Réglages du golem : quand il se réveille, comment il marche et se tourne, ses attaques, quand commence la seconde
## phase et ce qui y change.

## Le héros à moins de cette distance, en mètres, le réveille (un tir aussi).
@export_range(0.0, 50.0, 0.5) var wake_distance: float = 8.0
## Le temps du réveil, en secondes : il se dresse et fait face.
@export_range(0.0, 10.0, 0.1) var wake_time: float = 2.0
## Sa vitesse de marche, en mètres par seconde.
@export_range(0.0, 10.0, 0.1) var walk_speed: float = 2.0
## Sa vitesse pour se tourner, en radians par seconde.
@export_range(0.0, 10.0, 0.1) var turn_speed: float = 1.4
## Il ne marche ni ne frappe que s'il regarde le héros à moins de cet angle près, en radians (sinon il se tourne
## d'abord).
@export_range(0.0, 3.2, 0.05) var walk_cone: float = 0.8
## Ses attaques, dans l'ordre où il les essaie.
@export var attacks: Array[GolemAttack] = []
## La seconde phase commence quand sa vie passe sous cette part : 0,7, quand il en a perdu 30 %.
@export_range(0.0, 1.0, 0.01) var phase_two_ratio: float = 0.7
## Le temps du passage à la seconde phase, en secondes : il rugit et jette son bouclier.
@export_range(0.0, 10.0, 0.1) var phase_shift_time: float = 2.5
## En seconde phase, le nombre d'attaques qu'il enchaîne avant de récupérer.
@export_range(1, 5) var phase_two_chain: int = 2
## La vitesse de ses clips en seconde phase (1 : celle des clips).
@export_range(0.5, 2.0, 0.05) var phase_two_speed: float = 1.15
