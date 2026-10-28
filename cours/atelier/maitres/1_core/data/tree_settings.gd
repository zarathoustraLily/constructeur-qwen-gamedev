class_name TreeSettings extends Resource
## Réglages d'un arbre procédural : tronc, ramification, rétrécissement, feuilles, graine.

## Longueur du tronc, en mètres.
@export_range(0.1, 20.0, 0.1) var trunk_length: float = 2.0
## Rayon du tronc à sa base, en mètres.
@export_range(0.01, 2.0, 0.01) var trunk_radius: float = 0.18
## Nombre de niveaux de branches au-dessus du tronc.
@export_range(0, 6, 1) var depth: int = 3
## Branches filles par branche.
@export_range(1, 5, 1) var children: int = 3
## Chaque niveau garde cette part de la longueur de son parent.
@export_range(0.1, 1.0, 0.01) var length_ratio: float = 0.7
## Chaque niveau garde cette part du rayon de son parent.
@export_range(0.1, 1.0, 0.01) var radius_ratio: float = 0.6
## Écart d'une branche fille à la direction de son parent, en degrés.
@export_range(0.0, 90.0, 1.0) var spread_degrees: float = 35.0
## Variation aléatoire de l'écart, en degrés (plus ou moins).
@export_range(0.0, 45.0, 1.0) var jitter_degrees: float = 8.0
## Feuilles au bout de chaque rameau terminal.
@export_range(0, 20, 1) var leaves_per_tip: int = 4
## Graine du hasard : la même graine donne le même arbre.
@export var random_seed: int = 7
