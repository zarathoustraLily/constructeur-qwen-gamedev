class_name HeatSettings extends Resource
## Réglages d'une chaleur d'arme : son maximum (la surchauffe), la vitesse à laquelle elle redescend et le délai avant
## qu'elle redescende.

## La chaleur qui fait surchauffer.
@export_range(1.0, 1000.0, 1.0) var max_heat: float = 100.0
## Le refroidissement, en points par seconde : surchauffée, l'arme reste bloquée max_heat / cool_rate secondes.
@export_range(1.0, 500.0, 1.0) var cool_rate: float = 50.0
## Après un tir, le temps sans refroidissement, en secondes : tirer sans arrêt finit toujours par surchauffer.
@export_range(0.0, 5.0, 0.05) var cool_delay: float = 0.25
