class_name FlipbookSettings extends Resource
## Les réglages d'un flipbook : la planche d'images, et ce qu'on simule pour la remplir.

## Le nombre d'images sur une ligne de la planche.
@export_range(1, 16, 1) var columns: int = 4
## Le nombre de lignes de la planche.
@export_range(1, 16, 1) var rows: int = 4
## Les pas de simulation entre deux images.
@export_range(1, 16, 1) var steps_per_frame: int = 2
## La durée d'un pas de simulation, en secondes.
@export_range(0.001, 0.1, 0.001) var delta: float = 0.033
## La lumière retirée par unité de fumée et par longueur de volume.
@export_range(0.0, 50.0, 0.1) var absorption: float = 8.0
