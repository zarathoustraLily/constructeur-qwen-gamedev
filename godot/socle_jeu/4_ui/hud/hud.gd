class_name Hud
extends CanvasLayer
## Score et vie, mis à jour par les signaux du bus (aucune lecture à chaque image).

@onready var score_label: Label = $Margin/Box/Score
@onready var health_label: Label = $Margin/Box/Health


func _ready() -> void:
	EventBus.score_changed.connect(show_score)
	EventBus.player_damaged.connect(show_health)
	show_score(GameState.score)


func show_score(score: int) -> void:
	score_label.text = "Score %d" % score


func show_health(current_health: int) -> void:
	health_label.text = "Vie %d" % current_health
