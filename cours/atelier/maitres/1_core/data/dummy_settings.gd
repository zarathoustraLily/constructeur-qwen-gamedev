class_name DummySettings extends Resource
## Réglages du mannequin d'entraînement : combien de temps un coup l'étourdit, et comment sa vue penche.

## Durée de l'état Hit après un coup, en secondes.
@export_range(0.05, 2.0, 0.05) var hit_stun_time: float = 0.3
## Inclinaison de la vue pendant un coup, en radians.
@export_range(0.0, 1.0, 0.01) var hit_tilt: float = 0.35
## Inclinaison de la vue une fois vaincu, en radians (couché : un quart de tour).
@export_range(0.0, 3.2, 0.01) var defeated_tilt: float = 1.5708
## Vitesse à laquelle la vue rejoint son inclinaison, par seconde (plus grand : plus sec).
@export_range(0.1, 50.0, 0.1) var tilt_speed: float = 12.0
