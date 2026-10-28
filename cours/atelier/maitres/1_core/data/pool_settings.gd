class_name PoolSettings extends Resource
## Réglages d'une réserve d'objets : combien en préparer d'avance, et combien au plus.

## Objets créés dès le départ : plus aucune création pendant le jeu tant qu'ils suffisent.
@export_range(0, 1000, 1) var prewarm: int = 16
## Nombre total d'objets au plus ; au-delà, la réserve refuse (null) plutôt que de grossir sans fin.
@export_range(1, 10000, 1) var max_size: int = 64
