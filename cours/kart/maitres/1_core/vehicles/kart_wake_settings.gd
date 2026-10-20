class_name KartWakeSettings extends Resource
## Réglages du sillage d'un kart sur l'eau : ondulations sous les roues, écume des roues arrière, vague derrière
## l'essieu arrière. Les valeurs vivent dans un .tres de 5_data (5_data/kart/kart_wake.tres).
##
## La force du sillage suit la vitesse : `min_strength` à `min_speed`, 1 à `full_speed` et au-delà, le tout
## multiplié par `strength`.

@export_group("Vitesse")
## Vitesse en dessous de laquelle le kart ne laisse rien.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var min_speed: float = 0.0
## Vitesse à partir de laquelle le sillage est à sa force pleine.
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var full_speed: float = 0.0
## Force relative du sillage à `min_speed`.
@export var min_strength: float = 0.0
## Multiplicateur de tout le sillage.
@export var strength: float = 0.0

@export_group("Ondulations")
## Hauteur des ondulations sous chaque roue.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var ripple_height: float = 0.0
## Rayon des ondulations, en pixels de la simulation d'ondulations.
@export var ripple_radius_px: float = 0.0

@export_group("Vague et écume")
## Hauteur de la vague laissée derrière l'essieu arrière.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var wake_height: float = 0.0
## Rayon de cette vague, en pixels de la simulation de vagues.
@export var wake_radius_px: float = 0.0
## Quantité d'écume laissée par chaque roue arrière, de 0 à 1.
@export_range(0.0, 1.0) var foam_amount: float = 0.0
## Rayon de cette écume.
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var foam_radius: float = 0.0

@export_group("Roues")
## Position des roues avant, dans le repère du kart (x à droite, z vers l'arrière).
@export var front_wheels: PackedVector3Array = PackedVector3Array()
## Position des roues arrière, dans le repère du kart.
@export var rear_wheels: PackedVector3Array = PackedVector3Array()
