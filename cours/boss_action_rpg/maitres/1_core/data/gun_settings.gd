class_name GunSettings extends Resource
## Réglages d'une arme : cadence, chauffe par tir, projectiles (vitesse, dégâts, durée de vol) et portée de la visée.

## Le temps entre deux tirs, en secondes : 0,1 donne 10 tirs par seconde.
@export_range(0.02, 2.0, 0.01) var fire_interval: float = 0.1
## La chaleur ajoutée par un tir : dix tirs d'affilée font surchauffer une arme de 100.
@export_range(0.0, 100.0, 0.5) var heat_per_shot: float = 10.0
## La vitesse des projectiles, en m/s : rapides, mais pas instantanés (le bouclier a le temps de se lever).
@export_range(1.0, 500.0, 1.0) var projectile_speed: float = 70.0
## Les dégâts d'un projectile.
@export_range(0.0, 1000.0, 0.5) var damage: float = 12.0
## La durée de vol d'un projectile, en secondes : 70 m/s pendant 0,6 s, 42 m, plus que la salle.
@export_range(0.05, 5.0, 0.05) var lifetime: float = 0.6
## La portée du rayon de visée, en mètres.
@export_range(1.0, 500.0, 1.0) var aim_range: float = 60.0
