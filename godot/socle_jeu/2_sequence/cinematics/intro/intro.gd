extends Step
## Cinématique d'introduction : un texte, puis la suite après DURATION secondes (Entrée pour passer).

const DURATION := 2.5

var _time_left: float = DURATION


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		set_process(false)
		finish()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") and is_processing():
		set_process(false)
		finish()
