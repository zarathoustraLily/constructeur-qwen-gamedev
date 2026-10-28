class_name Hurtbox extends Area3D
## Une zone qui reçoit les tirs du héros et les passe à une santé (HealthComponent), multipliés : un point faible
## multiplie par plus de 1, un bouclier par 0 (le tir est bloqué). Elle est sur la couche des cibles et ne surveille
## rien : ce sont les projectiles qui la trouvent, par leurs rayons.

## Un tir de `amount` points est arrivé ; `dealt` : les dégâts vraiment faits (0 : bloqué).
signal received(amount: float, dealt: float)

## La santé qui prend les dégâts (aucune : la zone bloque, comme un bouclier).
@export var health: HealthComponent
## Le multiplicateur des dégâts : 1 normal, plus de 1 pour un point faible, 0 bloque.
@export_range(0.0, 10.0, 0.05) var multiplier: float = 1.0


func _ready() -> void:
	collision_layer = Layers.bit(Layers.TARGETS)
	collision_mask = 0
	monitoring = false


## Reçoit un tir de `amount` points et rend les dégâts vraiment faits : 0 si la zone bloque.
func receive(amount: float) -> float:
	var dealt: float = 0.0
	if health != null and multiplier > 0.0:
		dealt = health.take_damage(amount * multiplier)
	received.emit(amount, dealt)
	return dealt
