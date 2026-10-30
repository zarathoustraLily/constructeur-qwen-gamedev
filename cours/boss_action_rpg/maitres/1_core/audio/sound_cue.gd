class_name SoundCue extends Resource
## Un son du jeu : plusieurs variantes (une tirée au hasard à chaque fois), son volume, une hauteur tirée entre deux
## bornes (un même son ne revient jamais tout à fait pareil) et la distance au-delà de laquelle on ne l'entend plus.

## Les variantes.
@export var streams: Array[AudioStream] = []
## Le volume, en décibels.
@export_range(-60.0, 12.0, 0.5) var volume_db: float = 0.0
## La hauteur la plus basse (1 : celle du fichier).
@export_range(0.1, 4.0, 0.01) var pitch_min: float = 0.95
## La hauteur la plus haute.
@export_range(0.1, 4.0, 0.01) var pitch_max: float = 1.05
## La distance au-delà de laquelle il se tait, en mètres.
@export_range(1.0, 200.0, 1.0) var max_distance: float = 40.0
