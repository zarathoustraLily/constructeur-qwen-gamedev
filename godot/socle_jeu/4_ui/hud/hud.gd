class_name Hud
extends CanvasLayer
## Interface de jeu : score et vie. Elle affiche, elle ne décide de rien (aucune lecture à chaque image).
## Entrées : show_health() (le niveau l'appelle). Dépend de : GameState (score_changed).

@onready var score_label: Label = $Margin/Box/Score
@onready var health_label: Label = $Margin/Box/Health


func _ready() -> void:
	GameState.score_changed.connect(show_score)
	show_score(GameState.score)


func show_score(score: int) -> void:
	score_label.text = "Score %d" % score


func show_health(current_health: int) -> void:
	health_label.text = "Vie %d" % current_health
