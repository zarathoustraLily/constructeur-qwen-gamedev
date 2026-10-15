extends Step
## Menu titre : Entrée pour commencer.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept"):
		finish()
