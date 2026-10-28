class_name CameraSettings extends Resource
## Réglages de la caméra à la troisième personne : distance, épaule, inclinaison, sensibilités, suivi, visée,
## verrouillage de cible.

## Distance de la caméra au héros, en mètres (le bras à ressort la raccourcit devant un mur).
@export_range(0.5, 20.0, 0.1) var distance: float = 4.5
## Distance en visant, plus proche.
@export_range(0.5, 20.0, 0.1) var aim_distance: float = 2.2
## Décalage vers l'épaule droite, en mètres : le héros ne cache pas la cible.
@export_range(-3.0, 3.0, 0.05) var shoulder: float = 0.6
## Hauteur du point visé au-dessus des pieds du héros, en mètres.
@export_range(0.0, 3.0, 0.05) var height: float = 1.6
## Inclinaison la plus basse (regarder vers le haut), en degrés.
@export_range(-89.0, 0.0, 1.0) var pitch_min_degrees: float = -55.0
## Inclinaison la plus haute (regarder vers le bas), en degrés.
@export_range(0.0, 89.0, 1.0) var pitch_max_degrees: float = 60.0
## Vitesse de rotation au stick droit, en degrés par seconde.
@export_range(10.0, 720.0, 5.0) var stick_degrees_per_second: float = 220.0
## Rotation à la souris, en degrés par pixel.
@export_range(0.01, 1.0, 0.01) var mouse_degrees_per_pixel: float = 0.15
## Vitesse à laquelle le pivot rejoint le héros, par seconde.
@export_range(1.0, 50.0, 0.5) var follow_speed: float = 14.0
## Vitesse à laquelle la caméra verrouillée se tourne vers la cible, par seconde.
@export_range(1.0, 50.0, 0.5) var lock_speed: float = 8.0
## Distance la plus grande à laquelle on peut verrouiller une cible, en mètres.
@export_range(1.0, 100.0, 1.0) var lock_range: float = 30.0
