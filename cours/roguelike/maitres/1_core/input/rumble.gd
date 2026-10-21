class_name Rumble extends Resource
## Une vibration de manette : la force de ses deux moteurs et sa durée. Ses valeurs vivent dans un .tres
## de 5_data, jamais dans un script (règle DAT-01) ; l'adaptateur d'entrées la joue (PlayerInput.vibrate).

## Moteur faible (vibration rapide et légère), de 0 à 1.
@export_range(0.0, 1.0) var weak_magnitude: float = 0.0
## Moteur fort (vibration lente et lourde), de 0 à 1.
@export_range(0.0, 1.0) var strong_magnitude: float = 0.0
## Durée, en secondes.
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var duration: float = 0.0
