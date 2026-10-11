extends Node
## Score, vies et progression. Remis à zéro au début d'une partie.

const START_LIVES := 3

var score: int = 0
var lives: int = START_LIVES


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)


func reset() -> void:
	score = 0
	lives = START_LIVES
	EventBus.score_changed.emit(score)


func add_score(points: int) -> void:
	score += points
	EventBus.score_changed.emit(score)


## Retire une vie ; vrai s'il en reste.
func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	return lives > 0


func _on_enemy_killed(_enemy: Node3D, score_value: int) -> void:
	add_score(score_value)
