class_name GolemSpellSettings extends Resource
## Réglages des sorts du Gardien : le vol et l'explosion de ses boules de feu, la marque et le coup de ses éclairs. Les
## instants, les dégâts et le nombre de chaque sort sont dans son attaque (GolemAttack).

@export_group("Boules de feu")
## Sa vitesse, en mètres par seconde : assez lente pour qu'on la voie venir.
@export_range(1.0, 60.0, 0.5) var ball_speed: float = 15.0
## Elle se tourne vers sa cible d'au plus autant, en radians par seconde : une roulade de côté l'évite.
@export_range(0.0, 5.0, 0.05) var ball_turn: float = 0.5
## Sa durée de vol au plus, en secondes.
@export_range(0.5, 20.0, 0.5) var ball_life: float = 5.0
## Elle explose à cette distance de sa cible, en mètres.
@export_range(0.1, 5.0, 0.05) var ball_contact: float = 1.1
## L'explosion frappe jusqu'à cette distance, en mètres.
@export_range(0.5, 10.0, 0.1) var blast_radius: float = 2.6
## Le nombre de boules en seconde phase.
@export_range(1, 4) var phase_two_balls: int = 3
## L'écart entre deux boules d'une même salve, en radians.
@export_range(0.0, 1.5, 0.01) var fan_angle: float = 0.3

@export_group("Éclairs")
## Le rayon de la marque au sol et de la zone de coup, en mètres.
@export_range(0.5, 10.0, 0.1) var lightning_radius: float = 2.2
## L'écart entre deux marques, en mètres.
@export_range(0.5, 20.0, 0.5) var lightning_spread: float = 4.5
## La durée de l'éclair, en secondes.
@export_range(0.05, 2.0, 0.01) var bolt_time: float = 0.35
## La zone de coup reste allumée autant, en secondes.
@export_range(0.02, 1.0, 0.01) var zone_time: float = 0.12
## La largeur du ruban, halo compris, en mètres.
@export_range(0.1, 5.0, 0.05) var bolt_width: float = 1.3
## L'écart du zigzag à la ligne droite, en part de la longueur de l'éclair.
@export_range(0.0, 0.5, 0.01) var bolt_jag: float = 0.09
## L'éclair change de forme toutes les tant de secondes.
@export_range(0.01, 0.5, 0.01) var bolt_flicker: float = 0.05
