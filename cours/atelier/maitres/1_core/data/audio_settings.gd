class_name AudioSettings extends Resource
## Réglages du son : nombre de voix d'effets, variation de hauteur et de volume, durée des fondus de musique.

## Nombre d'effets qui peuvent jouer en même temps.
@export_range(1, 64, 1) var sfx_voices: int = 8
## Variation de hauteur d'un effet, plus ou moins (0,08 : ±8 %).
@export_range(0.0, 0.5, 0.01) var pitch_variation: float = 0.08
## Variation de volume d'un effet, plus ou moins, en dB.
@export_range(0.0, 12.0, 0.1) var volume_variation_db: float = 1.5
## Durée d'un fondu enchaîné de musique, en secondes.
@export_range(0.0, 10.0, 0.05) var crossfade_time: float = 1.5
## Graine du hasard des variations.
@export var random_seed: int = 5
