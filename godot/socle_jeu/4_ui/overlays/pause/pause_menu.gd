class_name PauseMenu
extends CanvasLayer
## Surcouche de pause : posée par-dessus l'étape en cours, elle l'interrompt sans la faire avancer.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
