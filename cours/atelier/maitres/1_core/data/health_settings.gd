class_name HealthSettings extends Resource
## Réglages d'une santé : son maximum et la durée d'invincibilité après un coup.

## Les points de vie au départ et au plus.
@export_range(1.0, 1000.0, 1.0) var max_health: float = 100.0
## Après un coup, le temps pendant lequel les coups suivants ne font rien, en secondes (0 : aucun répit).
@export_range(0.0, 5.0, 0.05) var invincibility_time: float = 0.5
