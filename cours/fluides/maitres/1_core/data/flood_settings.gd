class_name FloodSettings extends Resource
## Les réglages d'une eau peu profonde.

## La largeur de la grille, en cases.
@export_range(4, 1024, 1) var width: int = 256
## La hauteur de la grille, en cases.
@export_range(4, 1024, 1) var height: int = 256
## La force qui fait couler l'eau : ce qu'un écart de hauteur d'une unité ajoute au débit, par seconde.
@export_range(1.0, 2000.0, 1.0) var pull: float = 300.0
## La part du débit gardée à chaque pas (1 : aucun frottement).
@export_range(0.9, 1.0, 0.001) var friction: float = 0.99
