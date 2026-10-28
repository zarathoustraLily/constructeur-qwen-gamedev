class_name GalaxySettings extends Resource
## Réglages d'une galaxie spirale : étoiles, bras, enroulement, épaisseur, couleurs, graine.

## Nombre d'étoiles.
@export_range(1, 100000, 1) var star_count: int = 4000
## Nombre de bras.
@export_range(1, 8, 1) var arms: int = 3
## Rayon de la galaxie, en mètres.
@export_range(1.0, 1000.0, 1.0) var radius: float = 60.0
## Enroulement des bras : tours de spirale du centre au bord.
@export_range(0.0, 5.0, 0.05) var winding: float = 1.2
## Dispersion des étoiles autour de leur bras, en part du rayon.
@export_range(0.0, 1.0, 0.01) var arm_spread: float = 0.08
## Épaisseur du disque, en mètres (plus ou moins).
@export_range(0.0, 50.0, 0.1) var thickness: float = 2.0
## Couleur des étoiles du cœur.
@export var core_color: Color = Color(1.0, 0.85, 0.6)
## Couleur des étoiles du bord.
@export var edge_color: Color = Color(0.55, 0.7, 1.0)
## Graine du hasard : la même graine donne la même galaxie.
@export var random_seed: int = 3
