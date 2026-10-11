extends Node
## Les signaux partagés entre dossiers. Un émetteur ne connaît pas ses auditeurs.

signal enemy_killed(enemy: Node3D, score_value: int)
signal player_damaged(current_health: int)
signal player_died
signal score_changed(score: int)
