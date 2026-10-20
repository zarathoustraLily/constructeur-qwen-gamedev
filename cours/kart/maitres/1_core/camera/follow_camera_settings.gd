class_name FollowCameraSettings extends Resource
## Réglages d'une caméra qui suit une cible en orbite : sensibilité de la souris et du stick, limites de
## l'inclinaison, retour derrière la cible. Les valeurs vivent dans un .tres de 5_data
## (5_data/camera/follow_camera.tres).

## Rotation (radians) par pixel de mouvement de la souris.
@export var mouse_sensitivity: float = 0.0
## Rotation au stick droit poussé à fond, en radians par seconde.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad/s") var stick_speed: float = 0.0
## Inclinaison maximale vers le haut ou vers le bas, en radians.
@export_custom(PROPERTY_HINT_NONE, "suffix:rad") var max_pitch: float = 0.0
## Hauteur du point suivi au-dessus du modèle de la cible.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var height: float = 0.0
## Délai sans souris ni stick avant que la caméra revienne derrière la cible.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var reset_delay: float = 0.0
## Vitesse du retour derrière la cible, par seconde.
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var reset_rate: float = 0.0
## La caméra ne revient derrière la cible que si celle-ci va plus vite que cela.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var reset_min_speed: float = 0.0
