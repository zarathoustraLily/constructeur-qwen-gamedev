class_name HeroViewSettings extends Resource
## Réglages de la vue du héros : la vitesse de foulée de chaque boucle de marche (mesurée sur le modèle : un pied posé
## recule à la vitesse que le corps doit avoir pour qu'il ne glisse pas) et les durées des fondus entre animations.
## Les durées de la roulade et du soin ne sont pas ici : ce sont celles des états du héros (HeroSettings).

## Vitesse de foulée de la boucle de course, en m/s (mesurée : 4,23).
@export_range(0.5, 20.0, 0.01) var run_clip_speed: float = 4.23
## Vitesse de foulée de la boucle de sprint, en m/s (mesurée : 6,02).
@export_range(0.5, 20.0, 0.01) var sprint_clip_speed: float = 6.02
## Vitesse de foulée des marches visées, en m/s (moyenne des quatre directions mesurées, de 1,94 à 2,19).
@export_range(0.5, 20.0, 0.01) var aim_walk_clip_speed: float = 2.1
## Fondu entre deux états (course, roulade, coup, soin, chute), en secondes.
@export_range(0.0, 1.0, 0.01) var state_blend_time: float = 0.12
## Temps pour passer de la course à la marche visée, ou revenir, en secondes.
@export_range(0.01, 1.0, 0.01) var aim_blend_time: float = 0.15
## Entrée du recul d'un tir, en secondes.
@export_range(0.0, 0.5, 0.01) var fire_fade_in: float = 0.03
## Sortie du recul d'un tir, en secondes.
@export_range(0.0, 0.5, 0.01) var fire_fade_out: float = 0.12
