class_name CoinPickup
extends Area2D
## Pièce ramassée par le héros au contact.

signal collected(value: int)

@export var value: int = 1

var _taken: bool = false


func _on_body_entered(body: Node2D) -> void:
	if body is Hero:
		collect()


func collect() -> void:
	if _taken:
		return
	_taken = true
	GameState.add_coins(value)
	collected.emit(value)
	queue_free()
