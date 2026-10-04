class_name SpikeTrap
extends Area2D
## Piège à pointes : blesse le héros au contact, puis se recharge.

signal triggered(damage: int)

@export var damage: int = 1

@onready var cooldown: Timer = $Cooldown


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Hero:
		hit(body)


func is_armed() -> bool:
	return cooldown.is_stopped()


## Blesse le héros si le piège est armé, puis lance la recharge.
func hit(hero: Hero) -> bool:
	if not is_armed():
		return false
	hero.health.take_damage(damage)
	cooldown.start()
	triggered.emit(damage)
	return true
