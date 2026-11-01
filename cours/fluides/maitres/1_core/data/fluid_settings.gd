class_name FluidSettings extends Resource
## Les réglages d'un fluide : sa taille et sa façon de couler. Ce sont des données : changer de fumée ne touche pas au code.

## La largeur de la grille, en cases.
@export_range(4, 512, 1) var width: int = 64
## La hauteur de la grille, en cases.
@export_range(4, 512, 1) var height: int = 64
## L'épaisseur du fluide, en cases² par seconde (0 : il n'est pas diffusé).
@export_range(0.0, 10.0, 0.01) var viscosity: float = 0.0
## L'étalement de la matière transportée, en cases² par seconde.
@export_range(0.0, 10.0, 0.01) var diffusion: float = 0.0
## Les passes de la pression, à chaque projection.
@export_range(1, 200, 1) var iterations: int = 30
## La surrelaxation de la pression : 1 sans, 1,7 pour converger plus vite.
@export_range(1.0, 1.95, 0.01) var relaxation: float = 1.7
## La part de matière perdue par seconde.
@export_range(0.0, 10.0, 0.01) var dissipation: float = 0.1
#@ 7+
## Vrai : le transport de MacCormack, plus fin ; faux : le transport simple, plus rapide.
@export var sharp_transport: bool = true
#@ 8+
## La force qui rend ses tourbillons au fluide (0 : aucune).
@export_range(0.0, 50.0, 0.1) var vortex_strength: float = 4.0
#@ all
