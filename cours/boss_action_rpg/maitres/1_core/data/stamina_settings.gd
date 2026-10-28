class_name StaminaSettings extends Resource
## Réglages d'une endurance : son maximum, la vitesse à laquelle elle remonte et le délai avant qu'elle remonte.

## L'endurance au départ et au plus.
@export_range(1.0, 1000.0, 1.0) var max_stamina: float = 100.0
## La remontée, en points par seconde.
@export_range(0.0, 500.0, 1.0) var regen_rate: float = 40.0
## Après une dépense, le temps sans remontée, en secondes : rouler sans arrêt vide la jauge.
@export_range(0.0, 5.0, 0.05) var regen_delay: float = 0.7
