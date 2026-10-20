class_name WeatherSettings extends Resource
## Réglages de la météo : force de la pluie, vitesse à laquelle la route se mouille, et orage (délai entre deux
## éclairs). Les valeurs vivent dans un .tres de 5_data (5_data/weather/storm.tres).

@export_group("Pluie")
## Force de la pluie, de 0 (rien) à 1 (averse).
@export_range(0.0, 1.0) var intensity: float = 0.0
## Vitesse à laquelle la route se mouille ou sèche (mouillage par seconde).
@export_custom(PROPERTY_HINT_NONE, "suffix:/s") var wetness_speed: float = 0.0
## La route est déjà mouillée au départ s'il pleut.
@export var start_wet: bool = false

@export_group("Orage")
## Force de pluie à partir de laquelle la foudre tombe.
@export_range(0.0, 1.0) var lightning_min_intensity: float = 0.0
## Délai le plus court entre deux éclairs.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lightning_interval_min: float = 0.0
## Délai le plus long entre deux éclairs.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var lightning_interval_max: float = 0.0
## Graine du hasard des éclairs : la même graine redonne le même orage.
@export var random_seed: int = 0
