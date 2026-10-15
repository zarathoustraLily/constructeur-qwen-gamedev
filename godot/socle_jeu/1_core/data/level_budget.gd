class_name LevelBudget
extends Resource
## Budget de performance d'un niveau, vérifié par ses tests.

@export var max_nodes: int = 0
@export var max_frame_ms: float = 0.0
## Objets orphelins tolérés à la fermeture du niveau (fuites).
@export var max_orphans_after_free: int = 0
