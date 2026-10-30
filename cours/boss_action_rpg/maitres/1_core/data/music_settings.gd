class_name MusicSettings extends Resource
## Le volume de la musique et la durée de ses fondus.

## Le volume plein, en décibels.
@export_range(-60.0, 6.0, 0.5) var volume_db: float = -8.0
## La durée du fondu d'entrée, en secondes.
@export_range(0.05, 20.0, 0.05) var fade_in_time: float = 2.5
## La durée du fondu de sortie, en secondes.
@export_range(0.05, 20.0, 0.05) var fade_out_time: float = 4.0
