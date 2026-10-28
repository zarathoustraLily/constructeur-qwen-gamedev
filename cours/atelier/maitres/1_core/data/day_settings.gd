class_name DaySettings extends Resource
## Réglages du cycle jour-nuit : sa durée, l'énergie du soleil, ses couleurs à l'aube et à midi.

## La durée d'une journée entière, en secondes de jeu.
@export_range(1.0, 3600.0, 1.0) var day_length: float = 120.0
## L'énergie du soleil à midi.
@export_range(0.0, 16.0, 0.05) var noon_energy: float = 1.2
## La couleur du soleil à l'aube et au crépuscule.
@export var dawn_color: Color = Color(1.0, 0.55, 0.3)
## La couleur du soleil à midi.
@export var noon_color: Color = Color(1.0, 0.97, 0.9)
## L'heure de départ, de 0 à 1 (0 : minuit, 0,25 : aube, 0,5 : midi, 0,75 : crépuscule).
@export_range(0.0, 1.0, 0.01) var start_time: float = 0.3
