class_name SphSettings extends Resource
## Les réglages d'un liquide sans grille. Ce sont des données : changer de liquide ne touche pas au code.

## La largeur de la cuve, en unités.
@export_range(2.0, 200.0, 0.1) var width: float = 24.0
## La hauteur de la cuve, en unités ; y va vers le bas.
@export_range(2.0, 200.0, 0.1) var height: float = 18.0
## La portée d'une particule : au-delà, elle n'en voit plus une autre.
@export_range(0.1, 10.0, 0.01) var radius: float = 1.0
## L'écart entre deux particules au départ. Il fixe leur masse : à cet écart, le liquide a sa densité de repos.
@export_range(0.05, 5.0, 0.01) var spacing: float = 0.5
## La densité que le liquide cherche à garder.
@export_range(0.1, 100.0, 0.01) var rest_density: float = 1.0
## La raideur : la pression que donne un écart à la densité de repos.
@export_range(0.0, 1000.0, 0.1) var stiffness: float = 60.0
## L'épaisseur du liquide : ce qu'une particule prend de la vitesse de ses voisines.
@export_range(0.0, 10.0, 0.001) var viscosity: float = 0.2
## La gravité, en unités par seconde².
@export_range(0.0, 200.0, 0.1) var gravity: float = 20.0
## Les petits pas de calcul dans un pas du jeu : SPH explose si un pas est trop long.
@export_range(1, 16, 1) var substeps: int = 4
## La vitesse gardée par une particule qui rebondit sur un mur.
@export_range(0.0, 1.0, 0.01) var bounce: float = 0.3
