class_name ActorStats
extends Resource
## Réglages d'un acteur (joueur ou ennemi). Les valeurs vivent dans 5_data/, jamais dans le code.

@export var max_health: int = 3
@export var speed: float = 6.0
@export var hit_invulnerability: float = 0.0
@export_group("Ennemi")
@export var detection_range: float = 12.0
@export var attack_range: float = 7.0
@export var score_value: int = 100
@export_group("Dash")
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.6
