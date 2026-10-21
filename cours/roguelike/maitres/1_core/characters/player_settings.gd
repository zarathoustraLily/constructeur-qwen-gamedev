class_name PlayerSettings extends Resource
## Les réglages du joueur : ses vitesses et ses durées. Ils vivent dans 5_data/player/player_settings.tres,
## jamais dans un script (règle DAT-01). Les taux sont par seconde : le même réglage donne le même jeu à 30
## ou à 144 images par seconde.

## Vitesse de course, en m/s (stick poussé à fond).
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var movement_speed: float = 0.0
## Vivacité avec laquelle le personnage se tourne vers sa course : à chaque image, il fait la part
## 1 - exp(-turn_rate × durée de l'image) du chemin restant.
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var turn_rate: float = 0.0
#@ 5+
## Vitesse de l'esquive, en m/s.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var dash_speed: float = 0.0
## Durée de l'esquive, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var dash_duration: float = 0.0
## Délai avant de pouvoir esquiver à nouveau, compté dès le début de l'esquive, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var dash_cooldown: float = 0.0
#@ 6+
## Statistique de dégâts au départ, en % des dégâts de base des coups (100 : tels quels).
@export var damage_stat: float = 0.0
## Force de la secousse de la caméra quand l'épée touche (le trauma de ShakeCamera3D, de 0 à 1).
@export_range(0.0, 1.0) var hit_shake: float = 0.0
#@ 9+
## Force de la secousse de la caméra quand le joueur est touché.
@export_range(0.0, 1.0) var damage_shake: float = 0.0
#@ all
