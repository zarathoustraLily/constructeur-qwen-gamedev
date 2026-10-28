class_name VfxSettings extends Resource
## Réglages des effets visuels : les gerbes de particules, le tremblement de caméra, l'éclair d'un coup.

## Nombre de particules d'une gerbe d'étincelles.
@export_range(1, 256, 1) var spark_amount: int = 24
## Durée de vie d'une étincelle, en secondes.
@export_range(0.05, 5.0, 0.05) var spark_lifetime: float = 0.4
## Vitesse de départ des étincelles, au plus bas et au plus haut, en m/s.
@export var spark_speed: Vector2 = Vector2(4.0, 9.0)
## Ouverture du cône des étincelles, en degrés.
@export_range(0.0, 180.0, 1.0) var spark_spread: float = 50.0
## Couleur d'une étincelle à sa naissance, puis à sa mort (fondue).
@export var spark_colors: PackedColorArray = PackedColorArray([Color(1.0, 0.85, 0.4), Color(1.0, 0.3, 0.05, 0.0)])
## Nombre de particules d'un nuage de poussière.
@export_range(1, 256, 1) var dust_amount: int = 12
## Durée de vie de la poussière, en secondes.
@export_range(0.05, 5.0, 0.05) var dust_lifetime: float = 0.9
## Décalage maximal de la caméra pendant un tremblement, en mètres.
@export_range(0.0, 2.0, 0.01) var shake_max_offset: float = 0.3
## Traumatisme perdu par seconde.
@export_range(0.0, 10.0, 0.1) var shake_decay: float = 1.5
## Fréquence du bruit du tremblement.
@export_range(0.1, 60.0, 0.5) var shake_frequency: float = 18.0
## Couleur de l'éclair d'un coup.
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 0.8)
## Durée de l'éclair d'un coup, en secondes.
@export_range(0.01, 1.0, 0.01) var flash_duration: float = 0.12
