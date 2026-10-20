class_name KartSettings extends Resource
## Réglages de conduite d'un kart : moteur, direction, saut et gravité. Les valeurs vivent dans un .tres de
## 5_data (5_data/kart/kart_settings.tres), jamais dans le script du kart (règle DAT-01).
##
## Les amortissements sont des taux par seconde : chaque image, une vitesse v devient v × exp(−taux × dt).
## Un taux de 0,277 divise la vitesse par deux en 2,5 s (ln 2 / 0,277) ; plus le taux est grand, plus
## l'arrêt est rapide.

@export_group("Moteur")
## Vitesse de pointe en marche avant.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var top_speed: float = 0.0
## Vitesse maximale en marche arrière.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var top_reverse_speed: float = 0.0
## Accélération du moteur, gaz à fond.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s²") var acceleration: float = 0.0
## Amortissement en roue libre (résistance au roulement), par seconde.
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var rolling_decay: float = 0.0
## Amortissement quand on freine, par seconde.
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var braking_decay: float = 0.0

@export_group("Direction")
## Angle de braquage maximal à l'arrêt.
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var max_steering_angle_slow: float = 0.0
## Angle de braquage maximal à la vitesse de pointe : plus petit, pour un kart stable vite.
@export_custom(PROPERTY_HINT_NONE, "suffix:°") var max_steering_angle_fast: float = 0.0
## Vitesse à laquelle le braquage rejoint celui demandé, par seconde.
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var steering_response: float = 0.0
## En dessous de cette vitesse, le kart ne tourne plus (sauf en freinant).
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var steering_min_speed: float = 0.0
## En dessous de cette vitesse, freiner en braquant fait tourner le kart sur place.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var handbrake_max_speed: float = 0.0
## Vitesse de rotation sur place, braquage à fond.
@export_custom(PROPERTY_HINT_NONE, "suffix:°/s") var handbrake_steering_velocity: float = 0.0
## Vitesse de rotation en l'air, braquage à fond.
@export_custom(PROPERTY_HINT_NONE, "suffix:°/s") var air_steering_velocity: float = 0.0
## Empattement : distance entre les essieux, qui fixe le rayon du virage.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var wheel_base: float = 0.0

@export_group("Saut et gravité")
## Vitesse vers le haut donnée par un saut.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var jump_velocity: float = 0.0
## Gravité en l'air.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s²") var gravity: float = 0.0

@export_group("Contacts")
## Impulsion donnée à un corps rigide que le kart pousse.
@export_custom(PROPERTY_HINT_NONE, "suffix:N·s") var push_impulse: float = 0.0
