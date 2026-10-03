class_name Hud
extends CanvasLayer
## Affichage tête haute : vie, pièces, vague.

@onready var health_label: Label = $VieLabel
@onready var coins_label: Label = $PiecesLabel
@onready var wave_label: Label = $VagueLabel


func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "Vie : %d/%d" % [current, maximum]


func _on_coins_changed(total: int) -> void:
	coins_label.text = "Pièces : %d" % total


func _on_wave_started(number: int, _enemy_count: int) -> void:
	wave_label.text = "Vague %d" % number
