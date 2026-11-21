class_name SavesInput extends Node
## Les entrées de l'écran des sauvegardes (seul fichier de l'écran qui lit le clavier et la manette, règle ARC-04) :
## revenir (B, Échap) demande le retour d'un cran. Valider et monter ou descendre sont laissés aux boutons.

## Le joueur demande à revenir.
signal back_requested


func _ready() -> void:
	process_priority = ProcessOrder.INPUT


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
