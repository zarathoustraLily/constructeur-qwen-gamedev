class_name ProjectileSettings extends Resource
## Les réglages d'un projectile : sa vitesse, ses dégâts, le recul qu'il donne, sa durée de vie. Un .tres par
## projectile, dans 5_data (règle DAT-01).

## Vitesse, en m/s.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var speed: float = 0.0
## Dégâts, en points de vie.
@export var damage: float = 0.0
## Vitesse du recul donné à la cible, en m/s, dans le sens du projectile.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var knockback: float = 0.0
## Durée de vie, en secondes : au-delà, le projectile s'éteint sans rien toucher.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lifetime: float = 0.0
