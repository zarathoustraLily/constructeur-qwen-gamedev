class_name MenuSettings extends Resource
## Réglages des menus : ce que la croix ou le stick fait bouger sur un curseur.

## Le pas d'un curseur de volume, de 0 à 1 : un appui à gauche ou à droite le déplace d'autant.
@export_range(0.01, 0.5, 0.01) var volume_step: float = 0.05
