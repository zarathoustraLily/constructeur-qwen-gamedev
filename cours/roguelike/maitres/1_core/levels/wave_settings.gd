class_name WaveSettings extends Resource
## Les réglages d'une vague d'ennemis : combien selon le rang du niveau (une courbe), quand ils apparaissent, où,
## et la graine des tirages. Un .tres dans 5_data/levels/ (règle DAT-01).

## Nombre d'ennemis (partie entière) selon le rang du niveau, à partir de 1.
@export var difficulty: Curve
## Délai avant le premier ennemi, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var first_delay: float = 0.0
## Délai entre deux ennemis, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var interval: float = 0.0
## Demi-côté du carré, centré sur la vague, où un ennemi peut apparaître, en m.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var spawn_extent: float = 0.0
## Hauteur du centre d'un ennemi au-dessus du sol de la vague, en m (la moitié de sa capsule).
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var spawn_height: float = 0.0
## Graine des tirages de la vague (sorte d'ennemi, place, graine de chaque ennemi).
@export var random_seed: int = 0


## Nombre d'ennemis d'une vague au niveau de rang `rank`.
func enemy_count(rank: int) -> int:
	return floori(difficulty.sample(float(rank)))
