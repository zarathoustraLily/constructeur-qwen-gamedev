class_name FlipSettings extends Resource
## Les réglages d'une eau en particules. Ce sont des données : changer de cuve ne touche pas au code.

## La largeur de la cuve, en cases.
@export_range(4, 256, 1) var width: int = 40
## La hauteur de la cuve, en cases.
@export_range(4, 256, 1) var height: int = 30
## La gravité, en cases par seconde² ; y va vers le bas.
@export_range(0.0, 400.0, 0.1) var gravity: float = 60.0
## Les passes de la pression, à chaque pas.
@export_range(1, 200, 1) var iterations: int = 30
## La surrelaxation de la pression.
@export_range(1.0, 1.95, 0.01) var relaxation: float = 1.6
## La part de FLIP : 1, la particule ne reçoit que ce qui a changé sur la grille, et garde ses détails ; 0, elle reprend la vitesse
## de la grille (PIC), et tout s'amortit.
@export_range(0.0, 1.0, 0.01) var flip_ratio: float = 0.95
