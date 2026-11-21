class_name DisclaimerInput extends Node
## Les entrées de l'écran d'avertissement (seul fichier de l'écran qui lit le clavier et la manette, règle ARC-04) :
## valider (A, Entrée, Espace) ou revenir (B, Échap) demande de passer l'écran. Il ne décide pas si c'est permis :
## l'écran en juge.

## Le joueur demande à passer l'écran.
signal skip_requested


func _ready() -> void:
	process_priority = ProcessOrder.INPUT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel"):
		skip_requested.emit()
		get_viewport().set_input_as_handled()
