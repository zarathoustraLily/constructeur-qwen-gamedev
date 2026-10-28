class_name RippleSettings extends Resource
## Réglages d'une ondulation : la forme de l'onde, sa vitesse, son amortissement, et la grille qui la porte.

## Hauteur de l'onde au point d'impact, en mètres.
@export_range(0.0, 2.0, 0.01) var amplitude: float = 0.25
## Longueur d'onde, en mètres (distance entre deux crêtes).
@export_range(0.05, 10.0, 0.05) var wavelength: float = 1.2
## Vitesse du front de l'onde, en m/s.
@export_range(0.1, 20.0, 0.1) var speed: float = 3.0
## Amortissement avec la distance, par mètre.
@export_range(0.0, 5.0, 0.05) var distance_damping: float = 0.6
## Amortissement avec le temps, par seconde.
@export_range(0.0, 5.0, 0.05) var time_damping: float = 0.8
## Taille de la surface, en mètres (x, z).
@export var size: Vector2 = Vector2(10.0, 10.0)
## Nombre de cases de la grille (x, z).
@export var cells: Vector2i = Vector2i(40, 40)
