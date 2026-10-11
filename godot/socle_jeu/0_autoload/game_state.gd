extends Node
## État de la partie : score et vies. Remis à zéro au début d'une partie.
## Entrées : reset(), add_score(), lose_life(). Possède : score, lives.
## Émet : score_changed, lives_changed (l'interface les écoute).

signal score_changed(score: int)
signal lives_changed(lives: int)

var score: int = 0
var lives: int = 0


func reset(start_lives: int) -> void:
	score = 0
	lives = start_lives
	score_changed.emit(score)
	lives_changed.emit(lives)


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


## Retire une vie ; vrai s'il en reste.
func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	lives_changed.emit(lives)
	return lives > 0
