extends Node
## État global de la partie (autoload « GameState ») : pièces ramassées.

signal coins_changed(total: int)

var coins: int = 0


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)


func reset() -> void:
	coins = 0
	coins_changed.emit(coins)
