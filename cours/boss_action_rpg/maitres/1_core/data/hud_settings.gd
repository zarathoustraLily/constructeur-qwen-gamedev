class_name HudSettings extends Resource
## Réglages de l'interface du combat : la traîne des jauges (ce qu'un coup vient d'enlever), l'écran de chute, le nom
## du boss. Les couleurs et la place des jauges sont dans la scène de l'interface.

## Après une perte, le temps pendant lequel la traîne reste à l'ancienne valeur, en secondes : on voit ce qu'on a perdu.
@export_range(0.0, 3.0, 0.05) var trail_delay: float = 0.6
## Puis la vitesse à laquelle la traîne rejoint la valeur, en part de la jauge par seconde.
@export_range(0.05, 5.0, 0.05) var trail_speed: float = 0.6
## Le temps du fondu de l'écran de chute, en secondes.
@export_range(0.0, 5.0, 0.05) var defeat_fade_time: float = 1.2
## Le texte de l'écran de chute.
@export var defeat_text: String = "TERRASSÉ"
## Le nom du boss, au-dessus de sa jauge.
@export var boss_name: String = "Le Gardien du Comptoir"
