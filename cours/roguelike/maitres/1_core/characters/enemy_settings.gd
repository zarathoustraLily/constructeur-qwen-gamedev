class_name EnemySettings extends Resource
## Les réglages d'une sorte d'ennemi : sa vitesse, sa portée d'attaque, la durée de ses attentes, le rayon de ses
## errances et la graine de ses tirages. Un .tres par sorte, dans 5_data/enemies/ (règle DAT-01).

## Vitesse de marche, en m/s.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var speed: float = 0.0
## Distance à la cible sous laquelle l'ennemi attaque, en m.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var attack_range: float = 0.0
## Durée d'une attente, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var wait_time: float = 0.0
#@ 8+
## Rayon autour de lui où l'ennemi choisit le but d'une errance, en m.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var meander_radius: float = 0.0
#@ all
#@ 7
## Graine des tirages de l'ennemi (l'action qui suit une attaque) : une même graine, une même partie.
#@ 8+
## Graine des tirages de l'ennemi (l'action qui suit une attaque, le but d'une errance) : une même graine, une
## même partie.
#@ all
@export var random_seed: int = 0
