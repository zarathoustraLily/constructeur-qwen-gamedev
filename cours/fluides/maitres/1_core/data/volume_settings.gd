class_name VolumeSettings extends Resource
## Les réglages d'un fluide en trois dimensions : sa taille et sa façon de couler. Dans un volume, y monte.

## La taille de la grille, en cases.
@export var size: Vector3i = Vector3i(64, 96, 64)
## Les passes de la pression, à chaque projection.
@export_range(1, 200, 1) var iterations: int = 24
## La surrelaxation de la pression.
@export_range(1.0, 1.95, 0.01) var relaxation: float = 1.7
## La part de fumée perdue par seconde.
@export_range(0.0, 10.0, 0.01) var dissipation: float = 0.3
## La part de chaleur perdue par seconde.
@export_range(0.0, 10.0, 0.01) var cooling: float = 1.0
## La poussée de la chaleur, en cases par seconde² par degré.
@export_range(0.0, 200.0, 0.1) var buoyancy: float = 40.0
## Le poids de la fumée, en cases par seconde² par unité.
@export_range(0.0, 100.0, 0.1) var weight: float = 4.0
## La force qui rend ses tourbillons au fluide (0 : aucune).
@export_range(0.0, 50.0, 0.1) var vortex_strength: float = 6.0
