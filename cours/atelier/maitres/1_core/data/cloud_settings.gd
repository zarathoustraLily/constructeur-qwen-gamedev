class_name CloudSettings extends Resource
## Réglages d'un champ de nuages : nombre de bouffées, étendue, hauteur, taille, graine.

## Nombre de bouffées.
@export_range(1, 5000, 1) var puff_count: int = 120
## Rayon du champ, en mètres.
@export_range(1.0, 1000.0, 1.0) var radius: float = 80.0
## Hauteur des bouffées, au plus bas et au plus haut, en mètres.
@export var height: Vector2 = Vector2(30.0, 40.0)
## Taille des bouffées, au plus petit et au plus grand (échelle).
@export var size: Vector2 = Vector2(4.0, 10.0)
## Graine du hasard.
@export var random_seed: int = 11
