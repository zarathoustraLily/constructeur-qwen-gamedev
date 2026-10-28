class_name CameraSettings extends Resource
## Réglages de la caméra qui suit : distance, hauteur, inclinaison, douceur du suivi, rotation au stick droit.

## Distance voulue entre la caméra et sa cible, en mètres (le bras à ressort la raccourcit devant un mur).
@export_range(0.5, 30.0, 0.1) var distance: float = 6.0
## Hauteur du point visé au-dessus de la cible, en mètres.
@export_range(0.0, 5.0, 0.05) var target_height: float = 1.2
## Inclinaison de la caméra vers le bas, en degrés.
@export_range(0.0, 89.0, 0.5) var pitch_degrees: float = 25.0
## Vitesse à laquelle la caméra rejoint sa cible, par seconde (plus grand : plus sec).
@export_range(0.1, 50.0, 0.1) var follow_speed: float = 8.0
## Vitesse de rotation autour de la cible au stick, en degrés par seconde.
@export_range(0.0, 720.0, 5.0) var orbit_speed_degrees: float = 180.0
