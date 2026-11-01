class_name WaveSettings extends Resource
## Les réglages d'une surface d'eau.

## La largeur de la grille, en cases.
@export_range(4, 1024, 1) var width: int = 256
## La hauteur de la grille, en cases.
@export_range(4, 1024, 1) var height: int = 256
## La vitesse des vagues, en cases par seconde.
@export_range(1.0, 500.0, 0.1) var speed: float = 60.0
## La part du mouvement gardée à chaque pas (1 : rien ne se perd).
@export_range(0.9, 1.0, 0.001) var damping: float = 0.998
