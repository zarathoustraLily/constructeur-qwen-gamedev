class_name HeartPickup
extends Area2D
## Cœur à ramasser : rend des points de vie au héros.

signal consumed(amount: int)

@export var heal_amount: int = 1


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Hero:
		apply_to(body)


func apply_to(hero: Hero) -> void:
	hero.health.heal(heal_amount)
	consumed.emit(heal_amount)
	queue_free()
